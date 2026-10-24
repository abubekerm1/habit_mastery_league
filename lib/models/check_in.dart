class CheckIn {
  const CheckIn({
    this.id,
    required this.habitId,
    required this.checkinDate,
    required this.completed,
    required this.note,
  });

  final int? id;
  final int habitId;
  final String checkinDate;
  final int completed;
  final String note;

  bool get didIt => completed == 1;

  CheckIn copyWith({
    int? id,
    int? habitId,
    String? checkinDate,
    int? completed,
    String? note,
  }) {
    return CheckIn(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      checkinDate: checkinDate ?? this.checkinDate,
      completed: completed ?? this.completed,
      note: note ?? this.note,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'habit_id': habitId,
      'checkin_date': checkinDate,
      'completed': completed,
      'note': note,
    };
  }

  factory CheckIn.fromMap(Map<String, Object?> row) {
    return CheckIn(
      id: row['id'] as int?,
      habitId: row['habit_id'] as int? ?? 0,
      checkinDate: row['checkin_date'] as String? ?? '',
      completed: row['completed'] as int? ?? 0,
      note: row['note'] as String? ?? '',
    );
  }
}

class DuplicateCheckInException implements Exception {
  @override
  String toString() =>
      'You already have a check-in for this habit on that day.';
}
