import 'package:flutter_test/flutter_test.dart';

import 'package:habit_mastery_league/goal_helper.dart';

// These checks are the five cases I care about for the goal card.
void main() {
  test('normal week raises the goal by one', () {
    final result = suggestNextGoal(
      currentGoal: 3,
      recentCompleted: const [true, true, true, true],
    );

    expect(result.isValid, isTrue);
    expect(result.hasEnoughData, isTrue);
    expect(result.suggestedGoal, 4);
    expect(result.baselineGoal, 3);
    expect(result.reason, contains('small next step'));
  });

  test('no check-ins says there is not enough data', () {
    final result = suggestNextGoal(currentGoal: 3, recentCompleted: const []);

    expect(result.isValid, isTrue);
    expect(result.hasEnoughData, isFalse);
    expect(result.suggestedGoal, isNull);
    expect(result.baselineGoal, baselineWeeklyGoal);
    expect(result.reason, contains('Not enough'));
  });

  test('a goal outside 1 to 7 is invalid', () {
    final low = suggestNextGoal(currentGoal: 0, recentCompleted: const [true]);
    final high = suggestNextGoal(currentGoal: 8, recentCompleted: const [true]);

    expect(low.isValid, isFalse);
    expect(low.suggestedGoal, isNull);
    expect(high.isValid, isFalse);
    expect(high.reason, contains('1 and 7'));
  });

  test('goal already at 7 stays at 7', () {
    final result = suggestNextGoal(
      currentGoal: 7,
      recentCompleted: const [true, true, true, true, true, true, true],
    );

    expect(result.suggestedGoal, 7);
    expect(result.reason, contains('already 7'));
  });

  test(
    'two perfect days still bumps the goal and admits it can be too high',
    () {
      final result = suggestNextGoal(
        currentGoal: 2,
        recentCompleted: const [true, true],
      );

      expect(result.suggestedGoal, 3);
      expect(result.reason, contains('too high'));
    },
  );

  test('a close week keeps the same goal', () {
    final result = suggestNextGoal(
      currentGoal: 4,
      recentCompleted: const [true, true, true, false],
    );

    expect(result.suggestedGoal, 4);
    expect(result.reason, contains('same goal'));
  });

  test('a short week lowers the goal by one', () {
    final result = suggestNextGoal(
      currentGoal: 5,
      recentCompleted: const [true, false, false, false],
    );

    expect(result.suggestedGoal, 4);
  });

  test('completion rate stays between 0 and 1', () {
    expect(completionRate(0, 4), 0);
    expect(completionRate(2, 4), 0.5);
    expect(completionRate(5, 4), 1);
    expect(completionRate(3, 0), 0);
  });
}
