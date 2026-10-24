import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'date_keys.dart';
import 'models/check_in.dart';
import 'models/habit.dart';

// One helper owns the database. Screens do not open their own connection.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'habit_league.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    await init();
    return _db!;
  }

  Future<void> init() async {
    if (_db != null) return;

    final folder = await getApplicationDocumentsDirectory();
    final path = join(folder.path, _dbName);

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        // Needed so ON DELETE CASCADE actually runs.
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

        // Same habit + same day should only have one row.
        await db.execute('''
          CREATE UNIQUE INDEX idx_checkin_habit_date
          ON checkins(habit_id, checkin_date)
        ''');
      },
    );

    await _seedSamplesOnce();
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<void> _seedSamplesOnce() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('sample_habits_added') == true) return;

    final db = _db!;
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM habits'),
        ) ??
        0;

    if (count == 0) {
      final studyId = await db.insert('habits', {
        'name': 'Study for class',
        'category': 'Study',
        'weekly_goal': 4,
        'is_active': 1,
      });
      final waterId = await db.insert('habits', {
        'name': 'Drink water',
        'category': 'Health',
        'weekly_goal': 5,
        'is_active': 1,
      });
      final readId = await db.insert('habits', {
        'name': 'Read before bed',
        'category': 'Reading',
        'weekly_goal': 3,
        'is_active': 1,
      });

      Future<void> addLog(
        int habitId,
        int daysBack,
        int completed,
        String note,
      ) {
        return db.insert('checkins', {
          'habit_id': habitId,
          'checkin_date': toDateKey(
            DateTime.now().subtract(Duration(days: daysBack)),
          ),
          'completed': completed,
          'note': note,
        });
      }

      await addLog(studyId, 1, 1, 'reviewed notes');
      await addLog(studyId, 2, 1, 'practice problems');
      await addLog(studyId, 3, 1, '');
      await addLog(studyId, 4, 0, 'skipped');
      await addLog(waterId, 0, 1, 'bottle at my desk');
      await addLog(waterId, 1, 1, '');
      await addLog(readId, 1, 1, 'ten pages');
      await addLog(readId, 2, 1, '');
    }

    await prefs.setBool('sample_habits_added', true);
  }

  Future<int> insertHabit(Habit habit) async {
    final db = await database;
    return db.insert('habits', habit.toMap());
  }

  Future<int> updateHabit(Habit habit) async {
    final db = await database;
    return db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<void> setHabitActive(int id, bool active) async {
    final db = await database;
    await db.update(
      'habits',
      {'is_active': active ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // I delete the check-ins in the same transaction as the habit.
  // CASCADE is also on, so a parent delete does not leave old rows behind.
  Future<void> deleteHabit(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('checkins', where: 'habit_id = ?', whereArgs: [id]);
      final removed = await txn.delete(
        'habits',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (removed == 0) {
        throw StateError('That habit was already gone.');
      }
    });
  }

  Future<void> resetRecentCheckIns(int habitId, String startDate) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'checkins',
        where: 'habit_id = ? AND checkin_date >= ?',
        whereArgs: [habitId, startDate],
      );
      await txn.update(
        'habits',
        {'is_active': 1},
        where: 'id = ?',
        whereArgs: [habitId],
      );
    });
  }

  Future<List<Habit>> getHabits() async {
    final db = await database;
    final rows = await db.query('habits', orderBy: 'name COLLATE NOCASE');
    return rows.map(Habit.fromMap).toList();
  }

  Future<List<CheckIn>> getCheckIns() async {
    final db = await database;
    final rows = await db.query(
      'checkins',
      orderBy: 'checkin_date DESC, id DESC',
    );
    return rows.map(CheckIn.fromMap).toList();
  }

  Future<List<CheckIn>> getCheckInsForHabit(int habitId) async {
    final db = await database;
    final rows = await db.query(
      'checkins',
      where: 'habit_id = ?',
      whereArgs: [habitId],
      orderBy: 'checkin_date DESC',
    );
    return rows.map(CheckIn.fromMap).toList();
  }

  Future<CheckIn?> findCheckIn(int habitId, String dateKey) async {
    final db = await database;
    final rows = await db.query(
      'checkins',
      where: 'habit_id = ? AND checkin_date = ?',
      whereArgs: [habitId, dateKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CheckIn.fromMap(rows.first);
  }

  Future<void> saveCheckIn(CheckIn item) async {
    final db = await database;
    final dupes = await db.query(
      'checkins',
      where: 'habit_id = ? AND checkin_date = ?',
      whereArgs: [item.habitId, item.checkinDate],
    );

    final blocked = dupes.any((row) => row['id'] != item.id);
    if (blocked) {
      throw DuplicateCheckInException();
    }

    if (item.id == null) {
      await db.insert('checkins', item.toMap());
      return;
    }

    await db.update(
      'checkins',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteCheckIn(int id) async {
    final db = await database;
    await db.delete('checkins', where: 'id = ?', whereArgs: [id]);
  }
}
