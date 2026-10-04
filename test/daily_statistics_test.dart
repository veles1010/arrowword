import 'package:arrowword/app/daily_statistics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void check(
    String name,
    List<String> dates,
    String today,
    int current,
    int longest,
    int total,
  ) {
    test(name, () {
      final s = DailyStatistics.fromDates(dates, today: today);
      expect(s.currentStreak, current);
      expect(s.longestStreak, longest);
      expect(s.totalCompletedDaily, total);
    });
  }

  check('empty', [], '2026-10-04', 0, 0, 0);
  check('today only', ['2026-10-04'], '2026-10-04', 1, 1, 1);
  check(
    'unfinished today preserves yesterday streak',
    ['2026-10-03'],
    '2026-10-04',
    1,
    1,
    1,
  );
  check(
    'older date loses current streak',
    ['2026-10-02'],
    '2026-10-04',
    0,
    1,
    1,
  );
  check(
    'three consecutive days',
    ['2026-10-03', '2026-10-04', '2026-10-05'],
    '2026-10-05',
    3,
    3,
    3,
  );
  check(
    'gap and multiple runs',
    ['2026-10-01', '2026-10-02', '2026-10-03', '2026-10-05'],
    '2026-10-05',
    1,
    3,
    4,
  );
  check('year boundary', ['2026-12-31', '2027-01-01'], '2027-01-01', 2, 2, 2);
  check(
    'leap day boundary',
    ['2028-02-28', '2028-02-29', '2028-03-01'],
    '2028-03-01',
    3,
    3,
    3,
  );
  check(
    'duplicates and malformed dates do not inflate',
    ['2026-10-04', '2026-10-04', 'bad'],
    '2026-10-04',
    1,
    1,
    1,
  );
  check(
    'date change expires streak without changing history',
    ['2026-10-04'],
    '2026-10-06',
    0,
    1,
    1,
  );
  test('Turkish formatting', () {
    expect(formatDailyDate('2026-10-04'), '4 Ekim 2026');
    expect(formatDailyDate('2028-02-29'), '29 Şubat 2028');
    expect(formatDailyDuration(80), '01:20');
  });
}
