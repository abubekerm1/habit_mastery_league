# Goal helper

The card on Add/Edit habit suggests a weekly goal. It is a rule, not a trained model and not a chatbot. Nothing leaves the phone.

## What it decides
Question: what weekly goal should I try next for this habit?

Input: the current goal (1 to 7) and the check-ins from the last 7 days. Each check-in is completed or not.

Output: a suggested goal, or no number when the input is bad or there is no history. There is always a fixed baseline of 3 days so I can compare.

Success for me: the suggestion is a small step from the recent check-ins, and the user can ignore it.

## The rule
- If the goal is not from 1 to 7, I show an error and I do not suggest a number.
- If there are no check-ins, I say there is not enough data. Apply can still put 3 on the slider because that is the fixed starter goal.
- If completed days are at least the current goal, I add 1, but I never go over 7.
- If completed days are at least 2 under the goal, I subtract 1, but I never go under 1.
- Otherwise I keep the same goal.

Apply only changes the slider. Save is what writes the habit. Not now hides the card for that visit.

## Baseline
The baseline is always 3. It does not look at history. If the rule says 4 and the baseline says 3, the card shows both. That way a fixed starter goal is the simple comparison.

## Five cases I checked
1. Normal. Goal 3 and four completed check-ins. Suggestion is 4. Reason says it is a small next step.
2. No data. Goal 3 and an empty list. No suggested number. The text says not enough check-ins. Baseline stays 3.
3. Invalid. Goal 0 or 8. No suggestion. The text says the goal has to be between 1 and 7.
4. Boundary. Goal is already 7 and the check-ins meet it. Suggestion stays 7.
5. Counterexample. Goal 2 with only two completed check-ins. The rule still goes to 3, and the text says this can be too high. That is the weak spot. A short lucky streak is not enough to raise the goal, but the rule does it anyway. I left the behavior and I say so on the card, because hiding it would look more sure than it is.

I also checked a close week (3 done out of a goal of 4 keeps 4) and a short week (1 done out of 5 goes to 4).

The checks are in `test/goal_helper_test.dart`. I ran them with `flutter test`.

## Limits
- The sample is only the last 7 days, and sometimes less.
- It does not know if the student was sick, busy, or on break.
- It is not a health or study prediction. It is just a next goal for this app.
- I did not invent a confidence percent.
