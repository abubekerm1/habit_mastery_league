import 'package:flutter/material.dart';

import '../goal_helper.dart';

class SuggestionCard extends StatelessWidget {
  const SuggestionCard({
    super.key,
    required this.suggestion,
    this.onApply,
    this.onNotNow,
  });

  final GoalSuggestion suggestion;
  final VoidCallback? onApply;
  final VoidCallback? onNotNow;

  @override
  Widget build(BuildContext context) {
    final canApply = suggestion.isValid && onApply != null;
    final headline = suggestion.hasEnoughData
        ? 'Next goal: ${suggestion.suggestedGoal} days'
        : 'Fixed starter goal: ${suggestion.baselineGoal} days';

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suggested, not guaranteed',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Text(headline),
            const SizedBox(height: 6),
            Text(suggestion.reason),
            const SizedBox(height: 8),
            Text('Baseline to compare: ${suggestion.baselineGoal} days'),
            if (canApply) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: onNotNow,
                    child: const Text('Not now'),
                  ),
                  FilledButton(onPressed: onApply, child: const Text('Apply')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
