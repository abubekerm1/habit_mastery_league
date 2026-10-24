# Habit Mastery League

This app is for students who want to keep a weekly habit, like studying, reading, or drinking water. You add the habit, check in on the days you do it, and look back at the history. It works with no internet.

Team: Abubeker Mohammed and Jalen Artis
Class: Mobile Application Development, Project 1, undergraduate, Fall 2026

Planned work from our proposal:
- Abubeker Mohammed: Home, Add/Edit, SQLite, and the proposal
- Jalen Artis: Check-In, History, Settings, and the goal helper
- Both of us: testing, docs, and the final submission

## What the app does
- Add, edit, and delete a habit
- Save, update, and delete a check-in
- Start a week, finish it, or reset the last 7 days
- Filter history by category and see a completion rate
- Save a name and dark mode on the phone

## Screens
1. Home, the habit list
2. Add / Edit habit (opens from Home, not from the bottom menu)
3. Check-In
4. History
5. Settings

Bottom menu is Home, Check-In, History, and Settings.

## How to run it
We used Flutter 3.47.3.

```bash
flutter pub get
flutter test
flutter run
```

For Android I use the Pixel 7 emulator. I open Android Studio to start that emulator, then I close Android Studio and leave the emulator up. My laptop only has 8 GB of RAM, so Studio and the emulator together make it freeze.

Open the project folder in VS Code when you want to edit the Dart files.

## Data on the phone
SQLite file: `habit_league.db`

habits
- id, name, category, weekly_goal, is_active

checkins
- id, habit_id, checkin_date, completed, note

habit_id points at habits. If you delete a habit, its check-ins go too. I turn foreign keys on and I also delete the check-ins in the same transaction.

One habit cannot have two check-ins on the same day. Saving again updates that day.

SharedPreferences is only for small settings:
- display_name
- dark_mode
- sample_habits_added (so the sample habits do not come back after you delete them)

No cloud database and no online helper.

The first time the database is empty, three sample habits are added so the list is not blank.

## Goal card
On Add/Edit there is a card that suggests a weekly goal from check-ins in the last 7 days. It is a rule I wrote, not a trained model. Apply only moves the slider. The habit is not saved until Save. Not now hides the card until you leave the screen.

The fixed baseline is 3 days. More detail is in AI_FEATURE.md. How the files are split is in ARCHITECTURE.md.

## Dark mode
The switch is on the Settings screen. I turned it on from the phone, and it stays saved after the app closes.

![Settings with dark mode on](phone_screens/06_settings_dark.png)

## Known limits
- A week is the last 7 days, not Monday to Sunday.
- One or two check-ins can make the suggestion jump up too fast. The card says when that happens.

## License
School project for our team. Please do not turn this in as your own work.
