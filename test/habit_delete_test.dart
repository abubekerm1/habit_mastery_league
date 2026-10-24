import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Same tables as DatabaseHelper. I keep this here so I can test the delete
// rule without opening the phone.
Future<Database> openTestDb() {
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE habits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            weekly_goal INTEGER NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE checkins (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            habit_id INTEGER NOT NULL,
            checkin_date TEXT NOT NULL,
            completed INTEGER NOT NULL,
            note TEXT NOT NULL DEFAULT '',
            FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE UNIQUE INDEX idx_checkin_habit_date
          ON checkins(habit_id, checkin_date)
        ''');
      },
    ),
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  test('deleting a habit also deletes its check-ins', () async {
    final db = await openTestDb();
    final habitId = await db.insert('habits', {
      'name': 'Study for class',
      'category': 'Study',
      'weekly_goal': 4,
      'is_active': 1,
    });
    await db.insert('checkins', {
      'habit_id': habitId,
      'checkin_date': '2026-10-22',
      'completed': 1,
      'note': 'notes',
    });
    await db.insert('checkins', {
      'habit_id': habitId,
      'checkin_date': '2026-10-21',
      'completed': 0,
      'note': '',
    });

    // Delete only the habit. Check-ins should go too because of CASCADE.
    // If foreign keys were off, the check-ins would still be here.
    await db.delete('habits', where: 'id = ?', whereArgs: [habitId]);

    final habits = await db.query('habits');
    final checkins = await db.query('checkins');
    expect(habits, isEmpty);
    expect(checkins, isEmpty);
    await db.close();
  });

  test('the same habit and day cannot be saved twice', () async {
    final db = await openTestDb();
    final habitId = await db.insert('habits', {
      'name': 'Drink water',
      'category': 'Health',
      'weekly_goal': 5,
      'is_active': 1,
    });
    await db.insert('checkins', {
      'habit_id': habitId,
      'checkin_date': '2026-10-23',
      'completed': 1,
      'note': '',
    });

    await expectLater(
      db.insert('checkins', {
        'habit_id': habitId,
        'checkin_date': '2026-10-23',
        'completed': 0,
        'note': 'again',
      }),
      throwsA(isA<DatabaseException>()),
    );
    await db.close();
  });
}
