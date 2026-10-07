// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get answersAlwaysEnglish => '答案始终为英语。';

  @override
  String get home => '首页';

  @override
  String get puzzles => '谜题';

  @override
  String get daily => '每日';

  @override
  String get statistics => '统计';

  @override
  String get settings => '设置';

  @override
  String get about => '关于';

  @override
  String get appearance => '外观';

  @override
  String get theme => '主题';

  @override
  String get system => '系统';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get appInformation => '应用信息';

  @override
  String get easy => '简单';

  @override
  String get medium => '中等';

  @override
  String get hard => '困难';

  @override
  String get puzzle => '谜题';

  @override
  String get clear => '清空';

  @override
  String get check => '检查';

  @override
  String get continueGame => '继续';

  @override
  String get start => '开始';

  @override
  String get replay => '重玩';

  @override
  String get replayLower => '重玩';

  @override
  String get play => '开始玩';

  @override
  String get resume => '继续';

  @override
  String get dailyTitle => '每日谜题';

  @override
  String get dailyHistory => '每日记录';

  @override
  String get seeResult => '查看结果';

  @override
  String get share => '分享';

  @override
  String get returnHome => '返回首页';

  @override
  String get returnPuzzles => '返回谜题列表';

  @override
  String get chooseDifficulty => '选择难度';

  @override
  String get viewPuzzles => '查看谜题';

  @override
  String get nextPuzzle => '下一题';

  @override
  String get close => '关闭';

  @override
  String get back => '返回';

  @override
  String get closeSession => '结束本次游戏';

  @override
  String get restart => '重新开始';

  @override
  String get retry => '重试';

  @override
  String get locked => '未解锁';

  @override
  String get completed => '已完成';

  @override
  String get completedLower => '已完成';

  @override
  String get score => '得分';

  @override
  String get time => '用时';

  @override
  String get hints => '提示';

  @override
  String get wrongChecks => '错误检查';

  @override
  String get best => '最佳';

  @override
  String get thisAttempt => '本次结果';

  @override
  String get newRecord => '新纪录！';

  @override
  String get puzzleCompleted => '谜题完成！';

  @override
  String get dailyCompleted => '每日谜题完成！';

  @override
  String get rewardHint => '广告提示';

  @override
  String get adLoading => '广告加载中';

  @override
  String get adUnavailable => '暂时无法播放广告，请重试。';

  @override
  String get puzzleLoading => '正在准备谜题…';

  @override
  String get puzzlePreparing => '正在准备谜题';

  @override
  String get dailyPreparing => '正在准备每日谜题';

  @override
  String get generationError => '无法准备谜题，请重试。';

  @override
  String get shareError => '无法分享结果，请重试。';

  @override
  String get dailyUnavailable => '本次游戏无法使用每日谜题。';

  @override
  String get emptyHistory => '尚未完成任何每日谜题。';

  @override
  String get noScore => '暂无';

  @override
  String get completedPuzzles => '已完成谜题';

  @override
  String get scoredPuzzles => '有得分的谜题';

  @override
  String get totalScore => '总得分';

  @override
  String get averageScore => '平均得分';

  @override
  String get bestScore => '最高得分';

  @override
  String get hintFree => '无提示完成';

  @override
  String get errorFree => '无错误完成';

  @override
  String get dailyStatistics => '每日谜题';

  @override
  String get dailyCount => '每日完成数';

  @override
  String get currentStreak => '当前连续天数';

  @override
  String get longestStreak => '最长连续天数';

  @override
  String get statisticsIntro => '已完成的谜题及保存的最佳得分。';

  @override
  String get statisticsExplanation => '得分统计使用每个谜题保存的最佳成绩。评分功能推出前的记录仅计入完成数。';

  @override
  String get withinDifficulty => '请比较同一难度的得分。';

  @override
  String get hintLocked => '提示揭示，已锁定';

  @override
  String get development => '开发模式 · 进度不会保存';

  @override
  String get allCorrect => '所有字母均正确。';

  @override
  String get legacyScore => '此谜题在评分功能推出前已完成。';

  @override
  String get appDescription => '根据线索发现英语单词。体验关卡谜题、重玩和每日谜题。';

  @override
  String get workingName => 'Arrowword 为暂定名称，最终产品名称尚未确定。';

  @override
  String get versionLoading => '正在加载版本信息…';

  @override
  String get versionUnavailable => '暂时无法获取版本信息。';

  @override
  String puzzleNumber(int number) {
    return '谜题 $number';
  }

  @override
  String trackPuzzle(String difficulty, int number) {
    return '$difficulty · 谜题 $number';
  }

  @override
  String replayPuzzle(int number) {
    return '谜题 $number · 重玩';
  }

  @override
  String trackFinished(String difficulty) {
    return '$difficulty难度全部完成！';
  }

  @override
  String progress(int completed, int total) {
    return '已完成 $completed / $total';
  }

  @override
  String scorePoints(int score) {
    return '$score 分';
  }

  @override
  String todayCompleted(int score) {
    return '今日已完成 · $score 分';
  }

  @override
  String streakDays(int count) {
    return '连续 $count 天';
  }

  @override
  String completedCount(int count) {
    return '已完成 $count 个谜题';
  }

  @override
  String versionBuild(String version, String build) {
    return '版本 $version · 构建 $build';
  }

  @override
  String bestDetail(int number, int seconds) {
    return '谜题 $number · $seconds 秒';
  }

  @override
  String legacyDetail(int seconds) {
    return '旧记录 · $seconds 秒';
  }

  @override
  String dailyDetails(String duration, int hints, int checks) {
    return '$duration · 提示 $hints 次 · 错误检查 $checks 次';
  }

  @override
  String clueLength(String clue, int length) {
    return '$clue（$length）';
  }

  @override
  String clueSemantics(String clue, int length, String direction) {
    return '$clue，$length 个字母，$direction';
  }

  @override
  String get right => '横向';

  @override
  String get down => '向下';

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
      'yes': '，已完成',
      'other': '',
    });
    String _temp1 = intl.Intl.selectLogic(scored, {
      'yes': '，$score 分',
      'other': '',
    });
    String _temp2 = intl.Intl.selectLogic(replayable, {
      'yes': '，可重玩',
      'other': '',
    });
    return '谜题 $number，$status$_temp0$_temp1$_temp2';
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
      'yes': '最佳：$best\n',
      'other': '',
    });
    return '$label：$score\n$_temp0用时：$duration\n提示：$hints\n错误检查：$checks';
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
      'yes': '\n连续记录：$streak 天',
      'other': '',
    });
    return 'Arrowword — 每日谜题\n$date\n\n得分：$score\n用时：$duration\n提示：$hints\n错误检查：$checks$_temp0';
  }

  @override
  String dateDisplay(int day, String month, int year) {
    return '$year年$month$day日';
  }

  @override
  String get clueUnavailable => '此线索暂不可用。';

  @override
  String get uiPreview => '开发模式 · 仅预览英语界面';

  @override
  String invalidDevConfig(int count) {
    return '无法打开开发谜题。\nARROWWORD_PUZZLE_INDEX 必须为 1 到 $count。\nARROWWORD_PUZZLE_DIFFICULTY：easy、medium 或 hard。';
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
  String get versionFailed => '无法加载版本信息。';

  @override
  String get puzzleGenerationFailed => '无法生成谜题，请重试。';

  @override
  String get replayGenerationFailed => '无法还原谜题，请重试。';

  @override
  String get dailyGenerationFailed => '无法生成每日谜题，请重试。';

  @override
  String get legacyScoringMessage => '此谜题在评分功能推出前已完成。';

  @override
  String get restartGame => '重新开始';

  @override
  String get emptyProgress => '尚未完成任何谜题';

  @override
  String get language => '语言';

  @override
  String get systemDefault => '系统默认';

  @override
  String get englishName => 'English';

  @override
  String get turkishName => 'Türkçe';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get answersAlwaysEnglish => '答案始终为英语。';

  @override
  String get home => '首页';

  @override
  String get puzzles => '谜题';

  @override
  String get daily => '每日';

  @override
  String get statistics => '统计';

  @override
  String get settings => '设置';

  @override
  String get about => '关于';

  @override
  String get appearance => '外观';

  @override
  String get theme => '主题';

  @override
  String get system => '系统';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get appInformation => '应用信息';

  @override
  String get easy => '简单';

  @override
  String get medium => '中等';

  @override
  String get hard => '困难';

  @override
  String get puzzle => '谜题';

  @override
  String get clear => '清空';

  @override
  String get check => '检查';

  @override
  String get continueGame => '继续';

  @override
  String get start => '开始';

  @override
  String get replay => '重玩';

  @override
  String get replayLower => '重玩';

  @override
  String get play => '开始玩';

  @override
  String get resume => '继续';

  @override
  String get dailyTitle => '每日谜题';

  @override
  String get dailyHistory => '每日记录';

  @override
  String get seeResult => '查看结果';

  @override
  String get share => '分享';

  @override
  String get returnHome => '返回首页';

  @override
  String get returnPuzzles => '返回谜题列表';

  @override
  String get chooseDifficulty => '选择难度';

  @override
  String get viewPuzzles => '查看谜题';

  @override
  String get nextPuzzle => '下一题';

  @override
  String get close => '关闭';

  @override
  String get back => '返回';

  @override
  String get closeSession => '结束本次游戏';

  @override
  String get restart => '重新开始';

  @override
  String get retry => '重试';

  @override
  String get locked => '未解锁';

  @override
  String get completed => '已完成';

  @override
  String get completedLower => '已完成';

  @override
  String get score => '得分';

  @override
  String get time => '用时';

  @override
  String get hints => '提示';

  @override
  String get wrongChecks => '错误检查';

  @override
  String get best => '最佳';

  @override
  String get thisAttempt => '本次结果';

  @override
  String get newRecord => '新纪录！';

  @override
  String get puzzleCompleted => '谜题完成！';

  @override
  String get dailyCompleted => '每日谜题完成！';

  @override
  String get rewardHint => '广告提示';

  @override
  String get adLoading => '广告加载中';

  @override
  String get adUnavailable => '暂时无法播放广告，请重试。';

  @override
  String get puzzleLoading => '正在准备谜题…';

  @override
  String get puzzlePreparing => '正在准备谜题';

  @override
  String get dailyPreparing => '正在准备每日谜题';

  @override
  String get generationError => '无法准备谜题，请重试。';

  @override
  String get shareError => '无法分享结果，请重试。';

  @override
  String get dailyUnavailable => '本次游戏无法使用每日谜题。';

  @override
  String get emptyHistory => '尚未完成任何每日谜题。';

  @override
  String get noScore => '暂无';

  @override
  String get completedPuzzles => '已完成谜题';

  @override
  String get scoredPuzzles => '有得分的谜题';

  @override
  String get totalScore => '总得分';

  @override
  String get averageScore => '平均得分';

  @override
  String get bestScore => '最高得分';

  @override
  String get hintFree => '无提示完成';

  @override
  String get errorFree => '无错误完成';

  @override
  String get dailyStatistics => '每日谜题';

  @override
  String get dailyCount => '每日完成数';

  @override
  String get currentStreak => '当前连续天数';

  @override
  String get longestStreak => '最长连续天数';

  @override
  String get statisticsIntro => '已完成的谜题及保存的最佳得分。';

  @override
  String get statisticsExplanation => '得分统计使用每个谜题保存的最佳成绩。评分功能推出前的记录仅计入完成数。';

  @override
  String get withinDifficulty => '请比较同一难度的得分。';

  @override
  String get hintLocked => '提示揭示，已锁定';

  @override
  String get development => '开发模式 · 进度不会保存';

  @override
  String get allCorrect => '所有字母均正确。';

  @override
  String get legacyScore => '此谜题在评分功能推出前已完成。';

  @override
  String get appDescription => '根据线索发现英语单词。体验关卡谜题、重玩和每日谜题。';

  @override
  String get workingName => 'Arrowword 为暂定名称，最终产品名称尚未确定。';

  @override
  String get versionLoading => '正在加载版本信息…';

  @override
  String get versionUnavailable => '暂时无法获取版本信息。';

  @override
  String puzzleNumber(int number) {
    return '谜题 $number';
  }

  @override
  String trackPuzzle(String difficulty, int number) {
    return '$difficulty · 谜题 $number';
  }

  @override
  String replayPuzzle(int number) {
    return '谜题 $number · 重玩';
  }

  @override
  String trackFinished(String difficulty) {
    return '$difficulty难度全部完成！';
  }

  @override
  String progress(int completed, int total) {
    return '已完成 $completed / $total';
  }

  @override
  String scorePoints(int score) {
    return '$score 分';
  }

  @override
  String todayCompleted(int score) {
    return '今日已完成 · $score 分';
  }

  @override
  String streakDays(int count) {
    return '连续 $count 天';
  }

  @override
  String completedCount(int count) {
    return '已完成 $count 个谜题';
  }

  @override
  String versionBuild(String version, String build) {
    return '版本 $version · 构建 $build';
  }

  @override
  String bestDetail(int number, int seconds) {
    return '谜题 $number · $seconds 秒';
  }

  @override
  String legacyDetail(int seconds) {
    return '旧记录 · $seconds 秒';
  }

  @override
  String dailyDetails(String duration, int hints, int checks) {
    return '$duration · 提示 $hints 次 · 错误检查 $checks 次';
  }

  @override
  String clueLength(String clue, int length) {
    return '$clue（$length）';
  }

  @override
  String clueSemantics(String clue, int length, String direction) {
    return '$clue，$length 个字母，$direction';
  }

  @override
  String get right => '横向';

  @override
  String get down => '向下';

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
      'yes': '，已完成',
      'other': '',
    });
    String _temp1 = intl.Intl.selectLogic(scored, {
      'yes': '，$score 分',
      'other': '',
    });
    String _temp2 = intl.Intl.selectLogic(replayable, {
      'yes': '，可重玩',
      'other': '',
    });
    return '谜题 $number，$status$_temp0$_temp1$_temp2';
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
      'yes': '最佳：$best\n',
      'other': '',
    });
    return '$label：$score\n$_temp0用时：$duration\n提示：$hints\n错误检查：$checks';
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
      'yes': '\n连续记录：$streak 天',
      'other': '',
    });
    return 'Arrowword — 每日谜题\n$date\n\n得分：$score\n用时：$duration\n提示：$hints\n错误检查：$checks$_temp0';
  }

  @override
  String dateDisplay(int day, String month, int year) {
    return '$year年$month$day日';
  }

  @override
  String get clueUnavailable => '此线索暂不可用。';

  @override
  String get uiPreview => '开发模式 · 仅预览英语界面';

  @override
  String invalidDevConfig(int count) {
    return '无法打开开发谜题。\nARROWWORD_PUZZLE_INDEX 必须为 1 到 $count。\nARROWWORD_PUZZLE_DIFFICULTY：easy、medium 或 hard。';
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
  String get versionFailed => '无法加载版本信息。';

  @override
  String get puzzleGenerationFailed => '无法生成谜题，请重试。';

  @override
  String get replayGenerationFailed => '无法还原谜题，请重试。';

  @override
  String get dailyGenerationFailed => '无法生成每日谜题，请重试。';

  @override
  String get legacyScoringMessage => '此谜题在评分功能推出前已完成。';

  @override
  String get restartGame => '重新开始';

  @override
  String get emptyProgress => '尚未完成任何谜题';

  @override
  String get language => '语言';

  @override
  String get systemDefault => '系统默认';

  @override
  String get englishName => 'English';

  @override
  String get turkishName => 'Türkçe';
}
