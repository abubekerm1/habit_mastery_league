# Goal helper

The card on Add/Edit habit suggest a weekly goal. It is a rule, not a trained model and not a chatbot. Nothing leave the phone.

## What it decide
The question is, what weekly goal should I try next for this habit?

The input is the current goal, from 1 to 7, and the check-ins from the last 7 days. Each check-in is done or not done.

The output is a suggested goal, or no number if the input is bad or there is no history. I always show a fixed starter goal of 3 days so I can compare.

For me it is good enough if the suggestion is a small step from the recent check-ins, and the user can ignore it.

## The rule
- If the goal is not from 1 to 7, I show an error and I do not suggest a number.
- If there are no check-ins, I say there is not enough data. Apply can still put 3 on the slider, because that is the starter goal.
- If the finished days are at least the current goal, I add 1, but I never go over 7.
- If the finished days are at least 2 under the goal, I subtract 1, but I never go under 1.
- If it is close, I keep the same goal.

Apply only change the slider. Save is what write the habit. Not now hide the card for that visit.

## Baseline
The baseline is always 3. It do not look at history. If the rule say 4 and the baseline say 3, the card show both. The starter goal is the simple thing I compare against.

## Five cases I checked
1. Normal. Goal 3 and four finished check-ins. The suggestion is 4. The text say it is a small next step.
2. No data. Goal 3 and an empty list. No suggested number. The text say not enough check-ins. Baseline stay 3.
3. Bad input. Goal 0 or 8. No suggestion. The text say the goal has to be between 1 and 7.
4. Already at the top. Goal is 7 and the check-ins meet it. The suggestion stay 7.
5. A case where the rule is weak. Goal 2 with only two finished check-ins. The rule still go to 3, and the text say this can be too high. Two good days is not really enough to raise the goal, but the rule do it anyway. I left it like that and the card say so.

I also checked a close week. 3 done out of a goal of 4 stay at 4. A short week, 1 done out of 5, go to 4.

The checks are in `test/goal_helper_test.dart`. I ran them with `flutter test`.

## Limits
- I only look at the last 7 days, and sometimes less.
- It do not know if the student was sick, busy, or on break.
- It is not a health or study prediction. It is just a next goal for this app.
- I do not show a confidence percent. I do not have one.
