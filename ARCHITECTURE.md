# Architecture

I kept this small on purpose. The app is one offline tracker, so I did not add a state package.

## How the pieces talk
- Screens in `lib/screens` draw the pages and call the database.
- `DatabaseHelper` owns the SQLite connection. Widgets do not open the database themselves.
- `SettingsStore` is a ChangeNotifier for the name and dark mode. `main.dart` listens and rebuilds the theme.
- `goal_helper.dart` is plain Dart. It does not import Flutter. The form only shows what the function returns.
- `HabitTile` and `SuggestionCard` are stateless. The form and the check-in page keep the changing values in a State object.

I used setState for the screens. ChangeNotifier was enough for the theme. Provider would be extra for this size.

## Why two tables
A habit is the thing you plan. A check-in is one day of doing it. One habit has many check-ins. The link is `habit_id`.

`is_active` means the week is running. Finish week turns it off but leaves the old check-ins. Reset deletes only the last 7 days for that habit and turns the week back on.

## Delete rule
Deleting a habit deletes its check-ins too. The table says `ON DELETE CASCADE`, and `deleteHabit` also deletes the child rows inside a transaction. I did both so a missed foreign-key setting does not leave orphan check-ins.

## What stays where
SQLite: habits and check-ins.
SharedPreferences: display name, dark mode, and the flag that samples were already added.

Build files and the database file are not something we commit as app data. The phone creates the database on first launch.
