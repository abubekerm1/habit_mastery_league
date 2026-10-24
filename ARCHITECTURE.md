# Architecture

I kept this small. The app is one offline tracker, so I did not add a big state package.

## How the pieces talk
- The screens in `lib/screens` draw the pages and call the database.
- `DatabaseHelper` keep the SQLite connection. The widgets do not open the database themselves.
- `SettingsStore` hold the name and dark mode. `main.dart` listen to it and change the theme.
- `goal_helper.dart` is plain Dart. It do not import Flutter. The form just show what the function return.
- `HabitTile` and `SuggestionCard` only display things. The form and the check-in page keep the values that change.

I used setState on the screens. ChangeNotifier was enough for the theme. I did not use Provider because the app is small.

## Why two tables
A habit is what you plan. A check-in is one day of doing it. One habit can have many check-ins. The link is `habit_id`.

`is_active` mean the week is running. Finish week turn it off but leave the old check-ins. Reset delete only the last 7 days for that habit and turn the week back on.

## Delete rule
If you delete a habit, its check-ins go too. The table say `ON DELETE CASCADE`, and `deleteHabit` also delete the check-in rows in the same step. I did both so old check-ins do not get left behind.

## What stays where
SQLite: habits and check-ins.
SharedPreferences: display name, dark mode, and the flag that the sample habits were already added.

The phone create the database the first time you open the app.
