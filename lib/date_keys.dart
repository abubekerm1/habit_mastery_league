// I store dates as text like 2026-10-23 so I can sort them with a normal compare.
// A "week" in this app is the last 7 days, not Monday to Sunday. It was easier.

String toDateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String weekStartKey([DateTime? today]) {
  final start = dateOnly(today ?? DateTime.now())
      .subtract(const Duration(days: 6));
  return toDateKey(start);
}

String prettyDate(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return key;

  const months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final month = int.tryParse(parts[1]) ?? 0;
  final day = int.tryParse(parts[2]) ?? 0;
  if (month < 1 || month > 12) return key;
  return '${months[month]} $day, ${parts[0]}';
}
