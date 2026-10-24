import 'package:flutter/material.dart';

import '../categories.dart';
import '../database_helper.dart';
import '../date_keys.dart';
import '../goal_helper.dart';
import '../models/check_in.dart';
import '../models/habit.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.reloadToken});

  final int reloadToken;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Habit> _habits = [];
  List<CheckIn> _checkIns = [];
  String _category = 'All';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadToken != widget.reloadToken) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final habits = await DatabaseHelper.instance.getHabits();
      final checkIns = await DatabaseHelper.instance.getCheckIns();
      if (!mounted) return;
      setState(() {
        _habits = habits;
        _checkIns = checkIns;
        _loading = false;
      });
    } catch (error) {
      debugPrint('history load failed: $error');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load history. Please try again.';
      });
    }
  }

  List<Habit> get _filteredHabits {
    if (_category == 'All') return _habits;
    return _habits.where((habit) => habit.category == _category).toList();
  }

  Future<void> _edit(CheckIn item) async {
    final noteController = TextEditingController(text: item.note);
    var completed = item.didIt;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Edit check-in'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: completed,
                    title: const Text('Completed'),
                    onChanged: (value) =>
                        setLocal(() => completed = value ?? false),
                  ),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'Note'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    final note = noteController.text.trim();
    noteController.dispose();
    if (saved != true || !mounted) return;
    if (note.length > 120) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please keep the note under 120 letters.'),
        ),
      );
      return;
    }

    try {
      await DatabaseHelper.instance.saveCheckIn(
        item.copyWith(completed: completed ? 1 : 0, note: note),
      );
      await _load();
    } catch (error) {
      debugPrint('edit check-in failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update that check-in.')),
      );
    }
  }

  Future<void> _delete(CheckIn item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete check-in?'),
        content: const Text('This only removes this one day, not the habit.'),
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
    if (ok != true || item.id == null) return;

    try {
      await DatabaseHelper.instance.deleteCheckIn(item.id!);
      await _load();
    } catch (error) {
      debugPrint('delete check-in failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete that check-in.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      );
    }

    final habits = _filteredHabits;
    final habitIds = habits.map((habit) => habit.id).toSet();
    final rows = _checkIns
        .where((row) => habitIds.contains(row.habitId))
        .toList();
    final names = {for (final habit in _habits) habit.id: habit.name};
    final start = weekStartKey();

    var rateSum = 0.0;
    var totalDone = 0;
    for (final habit in habits) {
      final done = _checkIns
          .where(
            (row) =>
                row.habitId == habit.id &&
                row.didIt &&
                row.checkinDate.compareTo(start) >= 0,
          )
          .length;
      totalDone += done;
      rateSum += completionRate(done, habit.weeklyGoal);
    }
    final average = habits.isEmpty ? 0.0 : rateSum / habits.length;
    final percent = (average * 100).round();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Category filter',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _category,
                items: [
                  const DropdownMenuItem(value: 'All', child: Text('All')),
                  for (final category in habitCategories)
                    DropdownMenuItem(value: category, child: Text(category)),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _category = value);
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              habits.isEmpty
                  ? 'No habits in this category.'
                  : 'Completed days this week: $totalDone. Average completion rate: $percent%.',
            ),
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? const Center(child: Text('No check-ins for this filter yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    final title = names[row.habitId] ?? 'Habit';
                    final note = row.note.isEmpty ? 'No note' : row.note;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$title · ${prettyDate(row.checkinDate)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${row.didIt ? 'Completed' : 'Not completed'} · $note',
                            ),
                            Wrap(
                              children: [
                                TextButton.icon(
                                  onPressed: () => _edit(row),
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit'),
                                ),
                                TextButton.icon(
                                  onPressed: () => _delete(row),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
