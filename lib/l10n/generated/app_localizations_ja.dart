// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get answersAlwaysEnglish => '答えは常に英語です。';

  @override
  String get home => 'ホーム';

  @override
  String get puzzles => 'パズル';

  @override
  String get daily => 'デイリー';

  @override
  String get statistics => '統計';

  @override
  String get settings => '設定';

  @override
  String get about => 'このアプリについて';

  @override
  String get appearance => '表示';

  @override
  String get theme => 'テーマ';

  @override
  String get system => 'システム';

  @override
  String get light => 'ライト';

  @override
  String get dark => 'ダーク';

  @override
  String get appInformation => 'アプリ情報';

  @override
  String get easy => 'かんたん';

  @override
  String get medium => 'ふつう';

  @override
  String get hard => 'むずかしい';

  @override
  String get puzzle => 'パズル';

  @override
  String get clear => '消去';

  @override
  String get check => '確認';

  @override
  String get continueGame => '続ける';

  @override
  String get start => 'はじめる';

  @override
  String get replay => 'もう一度遊ぶ';

  @override
  String get replayLower => 'リプレイ';

  @override
  String get play => '遊ぶ';

  @override
  String get resume => '続ける';

  @override
  String get dailyTitle => '今日のパズル';

  @override
  String get dailyHistory => 'デイリー履歴';

  @override
  String get seeResult => '結果を見る';

  @override
  String get share => '共有';

  @override
  String get returnHome => 'ホームへ戻る';

  @override
  String get returnPuzzles => 'パズル一覧へ戻る';

  @override
  String get chooseDifficulty => '難易度を選ぶ';

  @override
  String get viewPuzzles => 'パズルを見る';

  @override
  String get nextPuzzle => '次のパズル';

  @override
  String get close => '閉じる';

  @override
  String get back => '戻る';

  @override
  String get closeSession => 'プレイを閉じる';

  @override
  String get restart => '最初から';

  @override
  String get retry => 'もう一度試す';

  @override
  String get locked => 'ロック中';

  @override
  String get completed => 'クリア済み';

  @override
  String get completedLower => 'クリア済み';

  @override
  String get score => 'スコア';

  @override
  String get time => '時間';

  @override
  String get hints => 'ヒント';

  @override
  String get wrongChecks => '誤答チェック';

  @override
  String get best => 'ベスト';

  @override
  String get thisAttempt => '今回の結果';

  @override
  String get newRecord => '新記録！';

  @override
  String get puzzleCompleted => 'パズルクリア！';

  @override
  String get dailyCompleted => '今日のパズルクリア！';

  @override
  String get rewardHint => '広告でヒント';

  @override
  String get adLoading => '広告を読み込み中';

  @override
  String get adUnavailable => '今は広告を表示できません。もう一度お試しください。';

  @override
  String get puzzleLoading => 'パズルを準備中…';

  @override
  String get puzzlePreparing => 'パズルを準備中';

  @override
  String get dailyPreparing => '今日のパズルを準備中';

  @override
  String get generationError => 'パズルを準備できませんでした。もう一度お試しください。';

  @override
  String get shareError => '結果を共有できませんでした。もう一度お試しください。';

  @override
  String get dailyUnavailable => 'このプレイでは今日のパズルを利用できません。';

  @override
  String get emptyHistory => 'まだデイリーパズルをクリアしていません。';

  @override
  String get noScore => 'まだなし';

  @override
  String get completedPuzzles => 'クリアしたパズル';

  @override
  String get scoredPuzzles => 'スコアのあるパズル';

  @override
  String get totalScore => '合計スコア';

  @override
  String get averageScore => '平均スコア';

  @override
  String get bestScore => '最高スコア';

  @override
  String get hintFree => 'ヒントなしクリア';

  @override
  String get errorFree => '誤答なしクリア';

  @override
  String get dailyStatistics => 'デイリーパズル';

  @override
  String get dailyCount => 'デイリークリア数';

  @override
  String get currentStreak => '現在の連続記録';

  @override
  String get longestStreak => '最長の連続記録';

  @override
  String get statisticsIntro => 'クリアしたパズルと保存されたベストスコア。';

  @override
  String get statisticsExplanation =>
      'スコア統計には各パズルのベスト記録を使います。スコア導入前の記録はクリア数にのみ含まれます。';

  @override
  String get withinDifficulty => 'スコアは同じ難易度で比べましょう。';

  @override
  String get hintLocked => 'ヒントで表示、変更不可';

  @override
  String get development => '開発用・進行は保存されません';

  @override
  String get allCorrect => 'すべての文字が正解です。';

  @override
  String get legacyScore => 'このパズルはスコア導入前にクリアされました。';

  @override
  String get appDescription => 'ヒントから英単語を見つけましょう。進行パズル、リプレイ、今日のパズルを楽しめます。';

  @override
  String get workingName => 'Arrowwordは仮称で、正式名称はまだ決まっていません。';

  @override
  String get versionLoading => 'バージョン情報を読み込み中…';

  @override
  String get versionUnavailable => '現在バージョン情報を取得できません。';

  @override
  String puzzleNumber(int number) {
    return 'パズル $number';
  }

  @override
  String trackPuzzle(String difficulty, int number) {
    return '$difficulty・パズル $number';
  }

  @override
  String replayPuzzle(int number) {
    return 'パズル $number・リプレイ';
  }

  @override
  String trackFinished(String difficulty) {
    return '$difficultyをすべてクリア！';
  }

  @override
  String progress(int completed, int total) {
    return '$completed / $total クリア';
  }

  @override
  String scorePoints(int score) {
    return '$score 点';
  }

  @override
  String todayCompleted(int score) {
    return '今日クリア・$score 点';
  }

  @override
  String streakDays(int count) {
    return '$count日連続';
  }

  @override
  String completedCount(int count) {
    return '$count個のパズルをクリア';
  }

  @override
  String versionBuild(String version, String build) {
    return 'バージョン $version・ビルド $build';
  }

  @override
  String bestDetail(int number, int seconds) {
    return 'パズル $number・$seconds秒';
  }

  @override
  String legacyDetail(int seconds) {
    return '以前の記録・$seconds秒';
  }

  @override
  String dailyDetails(String duration, int hints, int checks) {
    return '$duration・ヒント $hints・誤答チェック $checks';
  }

  @override
  String clueLength(String clue, int length) {
    return '$clue（$length）';
  }

  @override
  String clueSemantics(String clue, int length, String direction) {
    return '$clue、$length文字、$direction';
  }

  @override
  String get right => '横';

  @override
  String get down => '下';

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
      'yes': '、クリア済み',
      'other': '',
    });
    String _temp1 = intl.Intl.selectLogic(scored, {
      'yes': '、$score点',
      'other': '',
    });
    String _temp2 = intl.Intl.selectLogic(replayable, {
      'yes': '、リプレイ可能',
      'other': '',
    });
    return 'パズル $number、$status$_temp0$_temp1$_temp2';
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
      'yes': 'ベスト: $best\n',
      'other': '',
    });
    return '$label: $score\n$_temp0時間: $duration\nヒント: $hints\n誤答チェック: $checks';
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
      'yes': '\n連続記録: $streak日',
      'other': '',
    });
    return 'Arrowword — 今日のパズル\n$date\n\nスコア: $score\n時間: $duration\nヒント: $hints\n誤答チェック: $checks$_temp0';
  }

  @override
  String dateDisplay(int day, String month, int year) {
    return '$year年$month$day日';
  }

  @override
  String get clueUnavailable => 'このヒントは現在利用できません。';

  @override
  String get uiPreview => '開発用・英語UIのみのプレビュー';

  @override
  String invalidDevConfig(int count) {
    return '開発用パズルを開けません。\nARROWWORD_PUZZLE_INDEXは1〜$countで指定してください。\nARROWWORD_PUZZLE_DIFFICULTY: easy、medium、hard。';
  }

  @override
  String get month1 => '1月';

  @override
  String get month2 => '2月';

  @override
  String get month3 => '3月';

  @override
  String get month4 => '4月';

  @override
  String get month5 => '5月';

  @override
  String get month6 => '6月';

  @override
  String get month7 => '7月';

  @override
  String get month8 => '8月';

  @override
  String get month9 => '9月';

  @override
  String get month10 => '10月';

  @override
  String get month11 => '11月';

  @override
  String get month12 => '12月';

  @override
  String get versionFailed => 'バージョン情報を読み込めませんでした。';

  @override
  String get puzzleGenerationFailed => 'パズルを作成できませんでした。もう一度お試しください。';

  @override
  String get replayGenerationFailed => 'パズルを復元できませんでした。もう一度お試しください。';

  @override
  String get dailyGenerationFailed => '今日のパズルを作成できませんでした。もう一度お試しください。';

  @override
  String get legacyScoringMessage => 'このパズルはスコア導入前にクリアされました。';

  @override
  String get restartGame => 'やり直す';

  @override
  String get emptyProgress => 'まだクリアしたパズルはありません';

  @override
  String get language => '言語';

  @override
  String get systemDefault => 'システム設定に従う';

  @override
  String get englishName => 'English';

  @override
  String get turkishName => 'Türkçe';
}
