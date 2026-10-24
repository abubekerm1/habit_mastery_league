class Habit {
  const Habit({
    this.id,
    required this.name,
    required this.category,
    required this.weeklyGoal,
    required this.isActive,
  });

  final int? id;
  final String name;
  final String category;
  final int weeklyGoal;
  final int isActive;

  bool get isRunning => isActive == 1;

  Habit copyWith({
    int? id,
    String? name,
    String? category,
    int? weeklyGoal,
    int? isActive,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category,
      'weekly_goal': weeklyGoal,
      'is_active': isActive,
    };
  }

  factory Habit.fromMap(Map<String, Object?> row) {
    return Habit(
      id: row['id'] as int?,
      name: row['name'] as String? ?? '',
      category: row['category'] as String? ?? 'Other',
      weeklyGoal: row['weekly_goal'] as int? ?? 3,
      isActive: row['is_active'] as int? ?? 0,
    );
  }
}

// isActive means the week is running. Old check-ins can still be there after finish.
String habitStatus(Habit habit, int checkInCount) {
  if (habit.isRunning) return 'In progress';
  if (checkInCount > 0) return 'Week finished';
  return 'Not started';
}
