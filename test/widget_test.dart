import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habit_mastery_league/goal_helper.dart';
import 'package:habit_mastery_league/widgets/suggestion_card.dart';

void main() {
  testWidgets('Apply is a choice and does not pretend the habit is saved', (
    tester,
  ) async {
    var taps = 0;
    const suggestion = GoalSuggestion(
      suggestedGoal: 4,
      baselineGoal: 3,
      reason: 'You finished 4 check-ins, which meets the goal of 3.',
      isValid: true,
      hasEnoughData: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SuggestionCard(
            suggestion: suggestion,
            onApply: () => taps += 1,
            onNotNow: () {},
          ),
        ),
      ),
    );

    expect(find.text('Suggested, not guaranteed'), findsOneWidget);
    expect(find.text('Baseline to compare: 3 days'), findsOneWidget);
    await tester.tap(find.text('Apply'));
    expect(taps, 1);
  });

  testWidgets('a bad goal does not show Apply', (tester) async {
    const suggestion = GoalSuggestion(
      suggestedGoal: null,
      baselineGoal: 3,
      reason: 'The weekly goal has to be between 1 and 7 days.',
      isValid: false,
      hasEnoughData: false,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SuggestionCard(suggestion: suggestion)),
      ),
    );

    expect(find.text('Apply'), findsNothing);
    expect(find.textContaining('1 and 7'), findsOneWidget);
  });
}
