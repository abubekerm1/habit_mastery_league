import 'package:flutter/material.dart';

import '../database_helper.dart';
import '../date_keys.dart';
import '../models/check_in.dart';
import '../models/habit.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({
    super.key,
    required this.reloadToken,
    this.selectedHabitId,
    this.onHabitChanged,
  });

  final int reloadToken;
  final int? selectedHabitId;
  final ValueChanged<int>? onHabitChanged;

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _noteController = TextEditingController();

  List<Habit> _habits = [];
  int? _habitId;
  DateTime _date = dateOnly(DateTime.now());
  bool _completed = true;
  CheckIn? _existing;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  int _lookupToken = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(CheckInScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadToken != widget.reloadToken ||
        oldWidget.selectedHabitId != widget.selectedHabitId) {
      _load();
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final habits = await DatabaseHelper.instance.getHabits();
      if (!mounted) return;

      var nextId = _habitId;
      final wanted = widget.selectedHabitId;
      final ids = habits.map((habit) => habit.id).toSet();
      if (wanted != null && ids.contains(wanted)) {
        nextId = wanted;
      } else if (nextId == null || !ids.contains(nextId)) {
        nextId = habits.isEmpty ? null : habits.first.id;
      }

      setState(() {
        _habits = habits;
        _habitId = nextId;
        _loading = false;
      });
      await _lookupExisting();
    } catch (error) {
      debugPrint('check-in load failed: $error');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load check-in. Please try again.';
      });
    }
  }

  Future<void> _lookupExisting() async {
    final habitId = _habitId;
    if (habitId == null) return;

    final token = ++_lookupToken;
    final dateKey = toDateKey(_date);

    try {
      final row = await DatabaseHelper.instance.findCheckIn(habitId, dateKey);
      if (!mounted || token != _lookupToken) return;
      setState(() {
        _existing = row;
        _completed = row?.didIt ?? true;
        _noteController.text = row?.note ?? '';
      });
    } catch (error) {
      debugPrint('lookup check-in failed: $error');
    }
  }

  Habit? get _habit {
    for (final habit in _habits) {
      if (habit.id == _habitId) return habit;
    }
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: dateOnly(DateTime.now()),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = dateOnly(picked));
    await _lookupExisting();
  }

  Future<void> _save() async {
    final habit = _habit;
    if (habit?.id == null) {
      _show('Add a habit on the Home screen first.');
      return;
    }

    if (dateOnly(_date).isAfter(dateOnly(DateTime.now()))) {
      _show('Please pick today or a past day.');
      return;
    }

    final note = _noteController.text.trim();
    if (note.length > 120) {
      _show('Please keep the note under 120 letters.');
      return;
    }

    setState(() => _saving = true);

    final item = CheckIn(
      id: _existing?.id,
      habitId: habit!.id!,
      checkinDate: toDateKey(_date),
      completed: _completed ? 1 : 0,
      note: note,
    );

    try {
      await DatabaseHelper.instance.saveCheckIn(item);
      if (!mounted) return;
      setState(() => _saving = false);
      _show(_existing == null ? 'Check-in saved.' : 'Check-in updated.');
      await _lookupExisting();
    } on DuplicateCheckInException {
      if (!mounted) return;
      setState(() => _saving = false);
      _show('You already have a check-in for this habit on that day.');
    } catch (error) {
      debugPrint('save check-in failed: $error');
      if (!mounted) return;
      setState(() => _saving = false);
      _show('Could not save the check-in.');
    }
  }

  Future<void> _startWeek() async {
    final habit = _habit;
    if (habit?.id == null) return;
    if (habit!.isRunning) {
      _show('This week is already going.');
      return;
    }

    try {
      await DatabaseHelper.instance.setHabitActive(habit.id!, true);
      await _load();
      if (!mounted) return;
      _show('Week started for ${habit.name}.');
    } catch (error) {
      debugPrint('start week failed: $error');
      _show('Could not start the week.');
    }
  }

  Future<void> _finishWeek() async {
    final habit = _habit;
    if (habit?.id == null) return;
    if (!habit!.isRunning) {
      _show('Start the week before you finish it.');
      return;
    }

    final ok = await _confirm(
      'Finish this week?',
      'Your check-ins stay in History. The habit will show as week finished.',
    );
    if (!ok || !mounted) return;

    try {
      await DatabaseHelper.instance.setHabitActive(habit.id!, false);
      await _load();
      if (!mounted) return;
      _show('Week finished. Check-ins are still in History.');
    } catch (error) {
      debugPrint('finish week failed: $error');
      _show('Could not finish the week.');
    }
  }

  Future<void> _resetWeek() async {
    final habit = _habit;
    if (habit?.id == null) return;

    final ok = await _confirm(
      'Reset the last 7 days?',
      'This removes check-ins from the last 7 days for ${habit!.name}. Older ones stay.',
    );
    if (!ok || !mounted) return;

    try {
      await DatabaseHelper.instance.resetRecentCheckIns(
        habit.id!,
        weekStartKey(),
      );
      await _load();
      if (!mounted) return;
      _show('Recent check-ins were cleared and the week is active again.');
    } catch (error) {
      debugPrint('reset week failed: $error');
      _show('Could not reset the week.');
    }
  }

  Future<bool> _confirm(String title, String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    if (_habits.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No habits yet. Add one from Home, then come back to check in.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final habit = _habit;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Habit',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: _habitId,
              items: [
                for (final item in _habits)
                  DropdownMenuItem(value: item.id, child: Text(item.name)),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _habitId = value);
                widget.onHabitChanged?.call(value);
                _lookupExisting();
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (habit != null)
          Text(
            habit.isRunning
                ? '${habit.name} is in progress. Goal is ${habit.weeklyGoal} days.'
                : '${habit.name} is not in an active week. You can still log a day, or tap Start week.',
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickDate,
          icon: const Icon(Icons.calendar_today),
          label: Text(prettyDate(toDateKey(_date))),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _completed,
          title: const Text('I did it this day'),
          onChanged: (value) => setState(() => _completed = value ?? false),
        ),
        TextField(
          controller: _noteController,
          maxLength: 120,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _existing == null
              ? 'No check-in for this day yet.'
              : 'This day already has a check-in. Save will update it.',
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_existing == null ? 'Save check-in' : 'Update check-in'),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: _startWeek,
              child: const Text('Start week'),
            ),
            OutlinedButton(
              onPressed: _finishWeek,
              child: const Text('Finish week'),
            ),
            OutlinedButton(
              onPressed: _resetWeek,
              child: const Text('Reset week'),
            ),
          ],
        ),
      ],
    );
  }
}
