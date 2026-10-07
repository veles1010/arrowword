// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get answersAlwaysEnglish => 'Answers are always in English.';

  @override
  String get home => 'Home';

  @override
  String get puzzles => 'Puzzles';

  @override
  String get daily => 'Daily';

  @override
  String get statistics => 'Statistics';

  @override
  String get settings => 'Settings';

  @override
  String get about => 'About';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get appInformation => 'App information';

  @override
  String get easy => 'Easy';

  @override
  String get medium => 'Medium';

  @override
  String get hard => 'Hard';

  @override
  String get puzzle => 'Puzzle';

  @override
  String get clear => 'Clear';

  @override
  String get check => 'Check';

  @override
  String get continueGame => 'Continue';

  @override
  String get start => 'Start';

  @override
  String get replay => 'Replay';

  @override
  String get replayLower => 'replay';

  @override
  String get play => 'Play';

  @override
  String get resume => 'Continue';

  @override
  String get dailyTitle => 'Daily Puzzle';

  @override
  String get dailyHistory => 'Daily History';

  @override
  String get seeResult => 'View result';

  @override
  String get share => 'Share';

  @override
  String get returnHome => 'Back to Home';

  @override
  String get returnPuzzles => 'Back to Puzzles';

  @override
  String get chooseDifficulty => 'Choose difficulty';

  @override
  String get viewPuzzles => 'View puzzles';

  @override
  String get nextPuzzle => 'Next Puzzle';

  @override
  String get close => 'Close';

  @override
  String get back => 'Go back';

  @override
  String get closeSession => 'Close session';

  @override
  String get restart => 'Start again';

  @override
  String get retry => 'Try again';

  @override
  String get locked => 'Locked';

  @override
  String get completed => 'Completed';

  @override
  String get completedLower => 'completed';

  @override
  String get score => 'Score';

  @override
  String get time => 'Time';

  @override
  String get hints => 'Hints';

  @override
  String get wrongChecks => 'Incorrect checks';

  @override
  String get best => 'Best';

  @override
  String get thisAttempt => 'This attempt';

  @override
  String get newRecord => 'New best!';

  @override
  String get puzzleCompleted => 'Puzzle complete!';

  @override
  String get dailyCompleted => 'Daily puzzle complete!';

  @override
  String get rewardHint => 'Reveal with Ad';

  @override
  String get adLoading => 'Loading ad';

  @override
  String get adUnavailable =>
      'An ad is unavailable right now. Please try again.';

  @override
  String get puzzleLoading => 'Preparing puzzle…';

  @override
  String get puzzlePreparing => 'Preparing puzzle';

  @override
  String get dailyPreparing => 'Preparing the Daily Puzzle';

  @override
  String get generationError =>
      'The puzzle could not be prepared. Please try again.';

  @override
  String get shareError => 'The result could not be shared. Please try again.';

  @override
  String get dailyUnavailable =>
      'The Daily Puzzle is unavailable in this session.';

  @override
  String get emptyHistory => 'No Daily Puzzles completed yet.';

  @override
  String get noScore => 'Not yet';

  @override
  String get completedPuzzles => 'Completed puzzles';

  @override
  String get scoredPuzzles => 'Scored puzzles';

  @override
  String get totalScore => 'Total score';

  @override
  String get averageScore => 'Average score';

  @override
  String get bestScore => 'Best score';

  @override
  String get hintFree => 'Hint-free completions';

  @override
  String get errorFree => 'Error-free completions';

  @override
  String get dailyStatistics => 'Daily puzzles';

  @override
  String get dailyCount => 'Daily completions';

  @override
  String get currentStreak => 'Current streak';

  @override
  String get longestStreak => 'Longest streak';

  @override
  String get statisticsIntro => 'Completed puzzles and saved best scores.';

  @override
  String get statisticsExplanation =>
      'Score statistics use each puzzle’s saved best result. Older completions without scores count only toward completed puzzles.';

  @override
  String get withinDifficulty => 'Compare scores within the same difficulty.';

  @override
  String get hintLocked => 'Revealed with a hint, locked';

  @override
  String get development => 'Development · Progress is not saved';

  @override
  String get allCorrect => 'All letters are correct.';

  @override
  String get legacyScore =>
      'This puzzle was completed before scoring was introduced.';

  @override
  String get appDescription =>
      'Discover English words through clues. Progression puzzles, replay, and a Daily Puzzle.';

  @override
  String get workingName =>
      'Arrowword is a working title; the final product name has not been decided.';

  @override
  String get versionLoading => 'Loading version information…';

  @override
  String get versionUnavailable =>
      'Version information is currently unavailable.';

  @override
  String puzzleNumber(int number) {
    return 'Puzzle $number';
  }

  @override
  String trackPuzzle(String difficulty, int number) {
    return '$difficulty · Puzzle $number';
  }

  @override
  String replayPuzzle(int number) {
    return 'Puzzle $number · Replay';
  }

  @override
  String trackFinished(String difficulty) {
    return '$difficulty track complete!';
  }

  @override
  String progress(int completed, int total) {
    return '$completed / $total completed';
  }

  @override
  String scorePoints(int score) {
    return '$score points';
  }

  @override
  String todayCompleted(int score) {
    return 'Completed today · $score points';
  }

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-day streak',
      one: '1-day streak',
    );
    return '$_temp0';
  }

  @override
  String completedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count puzzles completed',
      one: '1 puzzle completed',
    );
    return '$_temp0';
  }

  @override
  String versionBuild(String version, String build) {
    return 'Version $version · Build $build';
  }

  @override
  String bestDetail(int number, int seconds) {
    return 'Puzzle $number · $seconds s';
  }

  @override
  String legacyDetail(int seconds) {
    return 'Older record · $seconds s';
  }

  @override
  String dailyDetails(String duration, int hints, int checks) {
    String _temp0 = intl.Intl.pluralLogic(
      hints,
      locale: localeName,
      other: '$hints hints',
      one: '1 hint',
    );
    String _temp1 = intl.Intl.pluralLogic(
      checks,
      locale: localeName,
      other: '$checks incorrect checks',
      one: '1 incorrect check',
    );
    return '$duration · $_temp0 · $_temp1';
  }

  @override
  String clueLength(String clue, int length) {
    return '$clue ($length)';
  }

  @override
  String clueSemantics(String clue, int length, String direction) {
    String _temp0 = intl.Intl.pluralLogic(
      length,
      locale: localeName,
      other: '$length letters',
      one: '1 letter',
    );
    return '$clue, $_temp0, $direction';
  }

  @override
  String get right => 'across';

  @override
  String get down => 'down';

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
      'yes': ', completed',
      'other': '',
    });
    String _temp1 = intl.Intl.selectLogic(scored, {
      'yes': ', $score points',
      'other': '',
    });
    String _temp2 = intl.Intl.selectLogic(replayable, {
      'yes': ', replay',
      'other': '',
    });
    return 'Puzzle $number, $status$_temp0$_temp1$_temp2';
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
      'yes': 'Best: $best\n',
      'other': '',
    });
    return '$label: $score\n${_temp0}Time: $duration\nHints: $hints\nIncorrect checks: $checks';
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
    String _temp0 = intl.Intl.pluralLogic(
      streak,
      locale: localeName,
      other: '$streak days',
      one: '1 day',
    );
    String _temp1 = intl.Intl.selectLogic(hasStreak, {
      'yes': '\nStreak: $_temp0',
      'other': '',
    });
    return 'Arrowword — Daily Puzzle\n$date\n\nScore: $score\nTime: $duration\nHints: $hints\nIncorrect checks: $checks$_temp1';
  }

  @override
  String dateDisplay(int day, String month, int year) {
    return '$day $month $year';
  }

  @override
  String get clueUnavailable => 'This clue is currently unavailable.';

  @override
  String get uiPreview => 'Development · English UI preview only';

  @override
  String invalidDevConfig(int count) {
    return 'Cannot open the development puzzle.\nARROWWORD_PUZZLE_INDEX must be between 1 and $count.\nARROWWORD_PUZZLE_DIFFICULTY: easy, medium, or hard.';
  }

  @override
  String get month1 => 'January';

  @override
  String get month2 => 'February';

  @override
  String get month3 => 'March';

  @override
  String get month4 => 'April';

  @override
  String get month5 => 'May';

  @override
  String get month6 => 'June';

  @override
  String get month7 => 'July';

  @override
  String get month8 => 'August';

  @override
  String get month9 => 'September';

  @override
  String get month10 => 'October';

  @override
  String get month11 => 'November';

  @override
  String get month12 => 'December';

  @override
  String get versionFailed => 'Version information could not be loaded.';

  @override
  String get puzzleGenerationFailed =>
      'The puzzle could not be generated. Please try again.';

  @override
  String get replayGenerationFailed =>
      'The puzzle could not be reconstructed. Please try again.';

  @override
  String get dailyGenerationFailed =>
      'The Daily Puzzle could not be generated. Please try again.';

  @override
  String get legacyScoringMessage =>
      'This puzzle was completed before scoring was introduced.';

  @override
  String get restartGame => 'Restart';

  @override
  String get emptyProgress => 'No puzzles completed yet';

  @override
  String get language => 'Language';

  @override
  String get systemDefault => 'System Default';

  @override
  String get englishName => 'English';

  @override
  String get turkishName => 'Türkçe';
}
