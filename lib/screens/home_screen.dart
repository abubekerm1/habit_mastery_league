import 'package:flutter/material.dart';

import '../database_helper.dart';
import '../date_keys.dart';
import '../models/check_in.dart';
import '../models/habit.dart';
import '../widgets/habit_tile.dart';
import 'habit_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.reloadToken,
    required this.onCheckIn,
  });

  final int reloadToken;
  final ValueChanged<int> onCheckIn;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Habit> _habits = [];
  List<CheckIn> _checkIns = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadToken != widget.reloadToken) {
      _load();
    }
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
      debugPrint('home load failed: $error');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load habits. Please try again.';
      });
    }
  }

  Future<void> _openForm(Habit? habit) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => HabitFormScreen(habit: habit)),
    );
    if (saved == true) _load();
  }

  Future<bool> _askDelete(Habit habit) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text(
          'Delete "${habit.name}"? This also deletes its check-ins.',
        ),
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
    return ok ?? false;
  }

  Future<void> _delete(Habit habit) async {
    // Take it off the list first. If I wait for the database, the swipe
    // animation complains that the card is still here.
    setState(() {
      _habits.removeWhere((item) => item.id == habit.id);
      _checkIns.removeWhere((row) => row.habitId == habit.id);
    });

    try {
      await DatabaseHelper.instance.deleteHabit(habit.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Habit deleted.')));
    } catch (error) {
      debugPrint('delete habit failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete that habit.')),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

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

    final start = weekStartKey();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'Swipe a habit left to delete it, or long-press it. Tap the card to edit.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: _habits.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No habits yet. Tap Add habit to start one.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  itemCount: _habits.length,
                  itemBuilder: (context, index) {
                    final habit = _habits[index];
                    final mine = _checkIns.where(
                      (row) => row.habitId == habit.id,
                    );
                    final weekDone = mine
                        .where(
                          (row) =>
                              row.didIt &&
                              row.checkinDate.compareTo(start) >= 0,
                        )
                        .length;

                    return HabitTile(
                      habit: habit,
                      doneCount: weekDone,
                      checkInCount: mine.length,
                      onEdit: () => _openForm(habit),
                      onCheckIn: () => widget.onCheckIn(habit.id!),
                      onConfirmDelete: () => _askDelete(habit),
                      onDeleted: () => _delete(habit),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
