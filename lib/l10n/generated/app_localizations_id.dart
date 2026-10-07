// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get home => 'Beranda';

  @override
  String get puzzles => 'Teka-teki';

  @override
  String get daily => 'Harian';

  @override
  String get statistics => 'Statistik';

  @override
  String get settings => 'Pengaturan';

  @override
  String get about => 'Tentang';

  @override
  String get appearance => 'Tampilan';

  @override
  String get theme => 'Tema';

  @override
  String get system => 'Sistem';

  @override
  String get light => 'Terang';

  @override
  String get dark => 'Gelap';

  @override
  String get appInformation => 'Informasi aplikasi';

  @override
  String get easy => 'Mudah';

  @override
  String get medium => 'Sedang';

  @override
  String get hard => 'Sulit';

  @override
  String get puzzle => 'Teka-teki';

  @override
  String get clear => 'Hapus';

  @override
  String get check => 'Periksa';

  @override
  String get continueGame => 'Lanjutkan';

  @override
  String get start => 'Mulai';

  @override
  String get replay => 'Main ulang';

  @override
  String get replayLower => 'main ulang';

  @override
  String get play => 'Main';

  @override
  String get resume => 'Lanjutkan';

  @override
  String get dailyTitle => 'Teka-teki Harian';

  @override
  String get dailyHistory => 'Riwayat Harian';

  @override
  String get seeResult => 'Lihat hasil';

  @override
  String get share => 'Bagikan';

  @override
  String get returnHome => 'Kembali ke Beranda';

  @override
  String get returnPuzzles => 'Kembali ke teka-teki';

  @override
  String get chooseDifficulty => 'Pilih kesulitan';

  @override
  String get viewPuzzles => 'Lihat teka-teki';

  @override
  String get nextPuzzle => 'Teka-teki berikutnya';

  @override
  String get close => 'Tutup';

  @override
  String get back => 'Kembali';

  @override
  String get closeSession => 'Tutup permainan';

  @override
  String get restart => 'Mulai lagi';

  @override
  String get retry => 'Coba lagi';

  @override
  String get locked => 'Terkunci';

  @override
  String get completed => 'Selesai';

  @override
  String get completedLower => 'selesai';

  @override
  String get score => 'Skor';

  @override
  String get time => 'Waktu';

  @override
  String get hints => 'Petunjuk';

  @override
  String get wrongChecks => 'Pemeriksaan salah';

  @override
  String get best => 'Terbaik';

  @override
  String get thisAttempt => 'Percobaan ini';

  @override
  String get newRecord => 'Rekor baru!';

  @override
  String get puzzleCompleted => 'Teka-teki selesai!';

  @override
  String get dailyCompleted => 'Teka-teki Harian selesai!';

  @override
  String get rewardHint => 'Petunjuk via iklan';

  @override
  String get adLoading => 'Memuat iklan';

  @override
  String get adUnavailable => 'Iklan belum tersedia. Coba lagi.';

  @override
  String get puzzleLoading => 'Menyiapkan teka-teki…';

  @override
  String get puzzlePreparing => 'Menyiapkan teka-teki';

  @override
  String get dailyPreparing => 'Menyiapkan Teka-teki Harian';

  @override
  String get generationError => 'Teka-teki belum bisa disiapkan. Coba lagi.';

  @override
  String get shareError => 'Hasil belum bisa dibagikan. Coba lagi.';

  @override
  String get dailyUnavailable =>
      'Teka-teki Harian tidak tersedia dalam sesi ini.';

  @override
  String get emptyHistory => 'Belum ada Teka-teki Harian yang selesai.';

  @override
  String get noScore => 'Belum ada';

  @override
  String get completedPuzzles => 'Teka-teki selesai';

  @override
  String get scoredPuzzles => 'Teka-teki dengan skor';

  @override
  String get totalScore => 'Total skor';

  @override
  String get averageScore => 'Rata-rata skor';

  @override
  String get bestScore => 'Skor tertinggi';

  @override
  String get hintFree => 'Selesai tanpa petunjuk';

  @override
  String get errorFree => 'Selesai tanpa kesalahan';

  @override
  String get dailyStatistics => 'Teka-teki Harian';

  @override
  String get dailyCount => 'Harian selesai';

  @override
  String get currentStreak => 'Rangkaian saat ini';

  @override
  String get longestStreak => 'Rangkaian terpanjang';

  @override
  String get statisticsIntro =>
      'Teka-teki selesai dan skor terbaik yang tersimpan.';

  @override
  String get statisticsExplanation =>
      'Statistik skor memakai hasil terbaik tiap teka-teki. Penyelesaian lama tanpa skor hanya dihitung sebagai teka-teki selesai.';

  @override
  String get withinDifficulty => 'Bandingkan skor pada kesulitan yang sama.';

  @override
  String get hintLocked => 'Terungkap lewat petunjuk, terkunci';

  @override
  String get development => 'Pengembangan · Progres tidak disimpan';

  @override
  String get allCorrect => 'Semua huruf benar.';

  @override
  String get legacyScore =>
      'Teka-teki ini selesai sebelum fitur skor diperkenalkan.';

  @override
  String get appDescription =>
      'Temukan kata bahasa Inggris lewat petunjuk. Nikmati progres teka-teki, main ulang, dan Teka-teki Harian.';

  @override
  String get workingName =>
      'Arrowword adalah nama sementara; nama final belum diputuskan.';

  @override
  String get versionLoading => 'Memuat informasi versi…';

  @override
  String get versionUnavailable => 'Informasi versi belum tersedia.';

  @override
  String puzzleNumber(int number) {
    return 'Teka-teki $number';
  }

  @override
  String trackPuzzle(String difficulty, int number) {
    return '$difficulty · Teka-teki $number';
  }

  @override
  String replayPuzzle(int number) {
    return 'Teka-teki $number · Main ulang';
  }

  @override
  String trackFinished(String difficulty) {
    return 'Tingkat $difficulty selesai!';
  }

  @override
  String progress(int completed, int total) {
    return '$completed / $total selesai';
  }

  @override
  String scorePoints(int score) {
    return '$score poin';
  }

  @override
  String todayCompleted(int score) {
    return 'Selesai hari ini · $score poin';
  }

  @override
  String streakDays(int count) {
    return '$count hari berturut-turut';
  }

  @override
  String completedCount(int count) {
    return '$count teka-teki selesai';
  }

  @override
  String versionBuild(String version, String build) {
    return 'Versi $version · Build $build';
  }

  @override
  String bestDetail(int number, int seconds) {
    return 'Teka-teki $number · $seconds dtk';
  }

  @override
  String legacyDetail(int seconds) {
    return 'Catatan lama · $seconds dtk';
  }

  @override
  String dailyDetails(String duration, int hints, int checks) {
    return '$duration · $hints petunjuk · $checks pemeriksaan salah';
  }

  @override
  String clueLength(String clue, int length) {
    return '$clue ($length)';
  }

  @override
  String clueSemantics(String clue, int length, String direction) {
    return '$clue, $length huruf, $direction';
  }

  @override
  String get right => 'mendatar';

  @override
  String get down => 'menurun';

  @override
  String tileSemantics(
    int number,
    String status,
    String completed,
    String scored,
    int score,
    String replayable,
  ) {
    String _temp0 = intl.Intl.selectLogic(completed, {
      'yes': ', selesai',
      'other': '',
    });
    String _temp1 = intl.Intl.selectLogic(scored, {
      'yes': ', $score poin',
      'other': '',
    });
    String _temp2 = intl.Intl.selectLogic(replayable, {
      'yes': ', bisa dimainkan ulang',
      'other': '',
    });
    return 'Teka-teki $number, $status$_temp0$_temp1$_temp2';
  }

  @override
  String resultDetails(
    String label,
    int score,
    String hasBest,
    int best,
    String duration,
    int hints,
    int checks,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasBest, {
      'yes': 'Terbaik: $best\n',
      'other': '',
    });
    return '$label: $score\n${_temp0}Waktu: $duration\nPetunjuk: $hints\nPemeriksaan salah: $checks';
  }

  @override
  String dailyShare(
    String date,
    int score,
    String duration,
    int hints,
    int checks,
    String hasStreak,
    int streak,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasStreak, {
      'yes': '\nRangkaian: $streak hari',
      'other': '',
    });
    return 'Arrowword — Teka-teki Harian\n$date\n\nSkor: $score\nWaktu: $duration\nPetunjuk: $hints\nPemeriksaan salah: $checks$_temp0';
  }

  @override
  String dateDisplay(int day, String month, int year) {
    return '$day $month $year';
  }

  @override
  String get clueUnavailable => 'Petunjuk ini belum tersedia.';

  @override
  String get uiPreview => 'Pengembangan · Pratinjau UI Inggris saja';

  @override
  String invalidDevConfig(int count) {
    return 'Teka-teki pengembangan tidak dapat dibuka.\nARROWWORD_PUZZLE_INDEX harus antara 1 dan $count.\nARROWWORD_PUZZLE_DIFFICULTY: easy, medium, atau hard.';
  }

  @override
  String get month1 => 'Januari';

  @override
  String get month2 => 'Februari';

  @override
  String get month3 => 'Maret';

  @override
  String get month4 => 'April';

  @override
  String get month5 => 'Mei';

  @override
  String get month6 => 'Juni';

  @override
  String get month7 => 'Juli';

  @override
  String get month8 => 'Agustus';

  @override
  String get month9 => 'September';

  @override
  String get month10 => 'Oktober';

  @override
  String get month11 => 'November';

  @override
  String get month12 => 'Desember';

  @override
  String get versionFailed => 'Informasi versi tidak dapat dimuat.';

  @override
  String get puzzleGenerationFailed =>
      'Teka-teki tidak dapat dibuat. Coba lagi.';

  @override
  String get replayGenerationFailed =>
      'Teka-teki tidak dapat dipulihkan. Coba lagi.';

  @override
  String get dailyGenerationFailed =>
      'Teka-teki Harian tidak dapat dibuat. Coba lagi.';

  @override
  String get legacyScoringMessage =>
      'Teka-teki ini selesai sebelum fitur skor diperkenalkan.';

  @override
  String get restartGame => 'Mulai ulang';

  @override
  String get emptyProgress => 'Belum ada teka-teki selesai';

  @override
  String get language => 'Bahasa';

  @override
  String get systemDefault => 'Default sistem';

  @override
  String get englishName => 'English';

  @override
  String get turkishName => 'Türkçe';
}
