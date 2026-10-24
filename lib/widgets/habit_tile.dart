import 'package:flutter/material.dart';

import '../goal_helper.dart';
import '../models/habit.dart';

class HabitTile extends StatelessWidget {
  const HabitTile({
    super.key,
    required this.habit,
    required this.doneCount,
    required this.checkInCount,
    required this.onEdit,
    required this.onCheckIn,
    required this.onConfirmDelete,
    required this.onDeleted,
  });

  final Habit habit;
  final int doneCount;
  final int checkInCount;
  final VoidCallback onEdit;
  final VoidCallback onCheckIn;
  final Future<bool> Function() onConfirmDelete;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final rate = completionRate(doneCount, habit.weeklyGoal);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final colors = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(habit.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onConfirmDelete(),
      onDismissed: (_) => onDeleted(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: colors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onEdit,
          onLongPress: () async {
            final ok = await onConfirmDelete();
            if (ok) onDeleted();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        habit.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(habitStatus(habit, checkInCount)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${habit.category} · goal ${habit.weeklyGoal} days'),
                const SizedBox(height: 8),
                Text(
                  '$doneCount of ${habit.weeklyGoal} done in the last 7 days',
                ),
                const SizedBox(height: 6),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(
                          height: 8,
                          width: constraints.maxWidth,
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        AnimatedContainer(
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 280),
                          height: 8,
                          width: constraints.maxWidth * rate,
                          decoration: BoxDecoration(
                            color: rate >= 1 ? colors.tertiary : colors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (rate >= 1) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Goal met for this week',
                    style: TextStyle(color: colors.tertiary),
                  ),
                ],
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onCheckIn,
                    child: const Text('Check in'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
