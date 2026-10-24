// Small rule helper for the weekly goal.
// This is not a trained model. I wrote the ifs myself.
// The baseline is always 3 days so I can compare the rule to a fixed starter goal.

const int baselineWeeklyGoal = 3;
const int minWeeklyGoal = 1;
const int maxWeeklyGoal = 7;

class GoalSuggestion {
  const GoalSuggestion({
    required this.suggestedGoal,
    required this.baselineGoal,
    required this.reason,
    required this.isValid,
    required this.hasEnoughData,
  });

  final int? suggestedGoal;
  final int baselineGoal;
  final String reason;
  final bool isValid;
  final bool hasEnoughData;
}

GoalSuggestion suggestNextGoal({
  required int currentGoal,
  required List<bool> recentCompleted,
}) {
  if (currentGoal < minWeeklyGoal || currentGoal > maxWeeklyGoal) {
    return const GoalSuggestion(
      suggestedGoal: null,
      baselineGoal: baselineWeeklyGoal,
      reason: 'The weekly goal has to be between 1 and 7 days.',
      isValid: false,
      hasEnoughData: false,
    );
  }

  if (recentCompleted.isEmpty) {
    return const GoalSuggestion(
      suggestedGoal: null,
      baselineGoal: baselineWeeklyGoal,
      reason: 'Not enough check-ins yet. The fixed starter goal is 3 days. Apply can fill that in, but nothing is saved until you tap Save.',
      isValid: true,
      hasEnoughData: false,
    );
  }

  final done = recentCompleted.where((item) => item).length;
  var next = currentGoal;
  var why = '';

  if (done >= currentGoal) {
    next = currentGoal + 1;
    if (next > maxWeeklyGoal) {
      next = maxWeeklyGoal;
      why =
          'You finished $done check-ins and the goal is already 7, so I kept it at 7.';
    } else {
      why =
          'You finished $done check-ins, which meets the goal of $currentGoal. I suggest $next for a small next step.';
    }
  } else if (done <= currentGoal - 2) {
    next = currentGoal - 1;
    if (next < minWeeklyGoal) next = minWeeklyGoal;
    why =
        'You finished $done check-ins, which is under the goal of $currentGoal. I suggest $next so it is a bit easier.';
  } else {
    why =
        'You finished $done check-ins, close to the goal of $currentGoal. I would keep the same goal.';
  }

  // Two good days can push the goal up even when we barely know the habit.
  // I still return the number, but I say it can be too high.
  if (recentCompleted.length < 3 && next > currentGoal) {
    why =
        '$why Only ${recentCompleted.length} check-ins were used, so this can be too high.';
  }

  return GoalSuggestion(
    suggestedGoal: next,
    baselineGoal: baselineWeeklyGoal,
    reason: why,
    isValid: true,
    hasEnoughData: true,
  );
}

// If the goal is 0 I return 0 instead of dividing.
// If they did more days than the goal, the rate stays at 1 (100%).
double completionRate(int completedCount, int weeklyGoal) {
  if (weeklyGoal <= 0 || completedCount <= 0) return 0;
  final rate = completedCount / weeklyGoal;
  if (rate > 1) return 1;
  return rate;
}
