import 'package:flutter/material.dart';

import '../categories.dart';
import '../database_helper.dart';
import '../date_keys.dart';
import '../goal_helper.dart';
import '../models/habit.dart';
import '../widgets/suggestion_card.dart';

class HabitFormScreen extends StatefulWidget {
  const HabitFormScreen({super.key, this.habit});

  final Habit? habit;

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _nameController = TextEditingController();
  double _goal = 3;
  String _category = habitCategories.first;
  List<bool> _recent = [];
  bool _hideTip = false;
  bool _saving = false;
  String? _nameError;

  bool get _isEdit => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    if (habit != null) {
      _nameController.text = habit.name;
      _goal = habit.weeklyGoal.toDouble();
      _category = habitCategories.contains(habit.category)
          ? habit.category
          : habitCategories.last;
      _loadRecent();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final id = widget.habit?.id;
    if (id == null) return;

    try {
      final rows = await DatabaseHelper.instance.getCheckInsForHabit(id);
      final start = weekStartKey();
      final recent = rows.where((row) => row.checkinDate.compareTo(start) >= 0);
      if (!mounted) return;
      setState(() {
        _recent = recent.map((row) => row.didIt).toList();
      });
    } catch (error) {
      debugPrint('recent check-ins failed: $error');
    }
  }

  // The suggestion is based on the saved goal, not the slider.
  // If it used the slider, tapping Apply would change the suggestion again
  // and the user could keep tapping Apply to push the goal higher.
  GoalSuggestion get _suggestion => suggestNextGoal(
    currentGoal: widget.habit?.weeklyGoal ?? _goal.round(),
    recentCompleted: _recent,
  );

  void _apply(GoalSuggestion tip) {
    // Apply only moves the slider. Save is a separate button on purpose.
    final next = tip.suggestedGoal ?? tip.baselineGoal;
    setState(() => _goal = next.toDouble());
  }

  Future<void> _save() async {
    final name = _nameController.text.trim().replaceAll('\n', ' ');
    if (name.isEmpty) {
      setState(() => _nameError = 'Please enter a habit name.');
      return;
    }
    if (name.length > 40) {
      setState(() => _nameError = 'Please keep the name under 40 letters.');
      return;
    }

    final goal = _goal.round();
    if (goal < minWeeklyGoal || goal > maxWeeklyGoal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal has to be from 1 to 7 days.')),
      );
      return;
    }

    setState(() {
      _saving = true;
      _nameError = null;
    });

    final habit = Habit(
      id: widget.habit?.id,
      name: name,
      category: _category,
      weeklyGoal: goal,
      isActive: widget.habit?.isActive ?? 0,
    );

    try {
      if (habit.id == null) {
        await DatabaseHelper.instance.insertHabit(habit);
      } else {
        await DatabaseHelper.instance.updateHabit(habit);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      debugPrint('save habit failed: $error');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save the habit. Please try again.'),
        ),
      );
    }
  }

  Future<void> _delete() async {
    final habit = widget.habit;
    if (habit?.id == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete habit?'),
        content: const Text('This also deletes the check-ins for this habit.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await DatabaseHelper.instance.deleteHabit(habit!.id!);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      debugPrint('delete from form failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete the habit.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tip = _suggestion;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit habit' : 'Add habit')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Habit name',
                errorText: _nameError,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _category,
                  items: [
                    for (final category in habitCategories)
                      DropdownMenuItem(value: category, child: Text(category)),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _category = value);
                        },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Weekly goal: ${_goal.round()} days'),
            Semantics(
              label: 'Weekly goal in days',
              child: Slider(
                value: _goal,
                min: 1,
                max: 7,
                divisions: 6,
                label: '${_goal.round()}',
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _goal = value),
              ),
            ),
            const Text('1 day is a light week. 7 means every day.'),
            const SizedBox(height: 16),
            if (!_hideTip)
              SuggestionCard(
                suggestion: tip,
                onApply: () => _apply(tip),
                onNotNow: () => setState(() => _hideTip = true),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save'),
            ),
            if (_isEdit) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _saving ? null : _delete,
                child: const Text('Delete habit'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
