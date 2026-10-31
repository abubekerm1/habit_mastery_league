import 'package:flutter_test/flutter_test.dart';

import 'package:habit_mastery_league/date_keys.dart';

void main() {
  test('toDateKey pads the month and day', () {
    expect(toDateKey(DateTime(2026, 1, 5)), '2026-01-05');
  });

  test('weekStartKey includes the previous six days', () {
    expect(weekStartKey(DateTime(2026, 10, 27)), '2026-10-21');
  });

  test('prettyDate formats a valid date key', () {
    expect(prettyDate('2026-10-27'), 'Oct 27, 2026');
  });

  test('prettyDate preserves malformed date keys', () {
    expect(prettyDate('bad'), 'bad');
  });

  test('prettyDate preserves a key with an invalid month', () {
    expect(prettyDate('2026-13-01'), '2026-13-01');
  });
}
