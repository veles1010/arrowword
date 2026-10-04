import '../features/puzzle/daily/daily_puzzle.dart';

/// Calendar-only arithmetic uses UTC date components, avoiding DST durations.
class DailyStatistics {
  const DailyStatistics(
    this.currentStreak,
    this.longestStreak,
    this.totalCompletedDaily,
  );
  final int currentStreak, longestStreak, totalCompletedDaily;

  factory DailyStatistics.fromDates(
    Iterable<String> keys, {
    required String today,
  }) {
    DateTime date(String key) => DateTime.utc(
      int.parse(key.substring(0, 4)),
      int.parse(key.substring(5, 7)),
      int.parse(key.substring(8, 10)),
    );
    DateTime previous(DateTime day) =>
        DateTime.utc(day.year, day.month, day.day - 1);
    final days = keys.where(isValidDailyDateKey).map(date).toSet();
    final ordered = days.toList()..sort();
    var longest = 0, run = 0;
    DateTime? last;
    for (final day in ordered) {
      run = last == previous(day) ? run + 1 : 1;
      if (run > longest) longest = run;
      last = day;
    }
    var current = 0;
    var cursor = date(today);
    if (!days.contains(cursor)) cursor = previous(cursor);
    while (days.contains(cursor)) {
      current++;
      cursor = previous(cursor);
    }
    return DailyStatistics(current, longest, days.length);
  }
}

String formatDailyDate(String key) {
  const months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];
  final date = DateTime.parse(key);
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String formatDailyDuration(int seconds) =>
    '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
