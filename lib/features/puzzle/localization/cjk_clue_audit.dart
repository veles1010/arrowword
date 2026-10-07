import '../generation/word_entry.dart';
import 'localized_clue_audit.dart';

/// Offline editorial diagnostics. Script/loan checks never enter generation.
class CjkClueAudit {
  CjkClueAudit(
    this.locale,
    this.words,
    this.clues,
    Map<String, String> english,
  ) {
    final basic = LocalizedClueAudit(words, clues, english);
    errors.addAll(basic.errors);
    errors.addAll(basic.punctuationWarnings);
    final expectedScript = switch (locale) {
      'ja' => RegExp(r'[\u3040-\u30ff\u3400-\u9fff]'),
      'ko' => RegExp(r'[\uac00-\ud7a3]'),
      'zh-Hans' => RegExp(r'[\u3400-\u9fff]'),
      _ => throw ArgumentError.value(locale),
    };
    for (final word in words) {
      final id = word.clueId!, clue = clues[id];
      if (clue == null) continue;
      if (!expectedScript.hasMatch(clue) || clue.contains('\uFFFD')) {
        errors.add('$id: missing expected script or invalid Unicode');
      }
      if (RegExp(r'[A-Za-z\uff21-\uff3a\uff41-\uff5a]|[\u0400-\u04ff]|[çğıİş]')
          .hasMatch(clue)) {
        untranslatedWarnings.add('$id: $clue');
      }
      if ((locale != 'ko' && RegExp(r'[\uac00-\ud7a3]').hasMatch(clue)) ||
          (locale != 'ja' && RegExp(r'[\u3040-\u30ff]').hasMatch(clue))) {
        errors.add('$id: unexpected neighbouring-language script');
      }
      if (locale == 'ja' && RegExp(r'\s').hasMatch(clue)) {
        errors.add('$id: artificial Japanese whitespace');
      }
      if (locale == 'zh-Hans' && RegExp(traditionalOnly).hasMatch(clue)) {
        errors.add('$id: possible Traditional-only character');
      }
      final forms = loanForms[locale]?[word.solution] ?? const <String>[];
      final hits = forms.where(clue.contains).toList();
      if (hits.isNotEmpty) {
        final normalized = clue.replaceAll(RegExp(r'[\s、。！？，,.!?]'), '');
        if (hits.contains(normalized) ||
            hits.any((form) => form.runes.length >= 2)) {
          errors.add('$id: definite phonetic answer revelation');
        } else {
          loanWarnings.add('$id (${word.solution}): ${hits.join(',')} — $clue');
        }
      }
      // Katakana is not synonymous with borrowing: native animal names are
      // routinely written this way too. Report all usage for human review.
      final borrowed = locale == 'ja'
          ? RegExp(r'[ァ-ヶー]+').allMatches(clue).map((m) => m.group(0)!).toList()
          : locale == 'ko'
          ? koreanBorrowings.where(clue.contains).toList()
          : chineseBorrowings.where(clue.contains).toList();
      if (borrowed.isNotEmpty) {
        borrowingWarnings.add(
          '$id (${word.solution}): ${borrowed.join(',')} — $clue',
        );
      }
      final limit = switch (locale) {
        'ja' => 28,
        'ko' => 32,
        _ => 22,
      };
      if (clue.runes.length > limit) {
        lengthWarnings.add('$id: ${clue.runes.length} characters — $clue');
      }
    }
  }
  final String locale;
  final List<WordEntry> words;
  final Map<String, String> clues;
  final errors = <String>[];
  final loanWarnings = <String>[];
  final borrowingWarnings = <String>[];
  final untranslatedWarnings = <String>[];
  final lengthWarnings = <String>[];

  Map<String, Object> statistics(String track) {
    final values = clues.entries
        .where((e) => e.key.startsWith('${track}_'))
        .map((e) => e.value)
        .toList();
    final lengths = values.map((c) => c.runes.length).toList();
    final result = <String, Object>{
      'count': values.length,
      'averageCharacters': lengths.reduce((a, b) => a + b) / lengths.length,
      'maxCharacters': lengths.reduce((a, b) => a > b ? a : b),
    };
    if (locale == 'ko') {
      final counts = values
          .map((s) => s.trim().split(RegExp(r'\s+')).length)
          .toList();
      result['averageWords'] = counts.reduce((a, b) => a + b) / counts.length;
      result['maxWords'] = counts.reduce((a, b) => a > b ? a : b);
    }
    return result;
  }

  // Curated screening vocabulary, not a claim of universal phonetic detection.
  // It complements full editorial review, including words absent from this list.
  static const loanForms = <String, Map<String, List<String>>>{
    'ja': {
      'HOTEL': ['ホテル'],
      'MOTOR': ['モーター', 'モータ'],
      'RADIO': ['ラジオ'],
      'CAMERA': ['カメラ'],
      'ROBOT': ['ロボット'],
      'TENNIS': ['テニス'],
      'SOFA': ['ソファ'],
      'TABLE': ['テーブル'],
      'LIGHT': ['ライト'],
      'ORANGE': ['オレンジ'],
      'COFFEE': ['コーヒー'],
      'BANANA': ['バナナ'],
      'LEMON': ['レモン'],
      'MELON': ['メロン'],
      'PASTA': ['パスタ'],
      'YOGURT': ['ヨーグルト'],
      'COOKIE': ['クッキー'],
      'JUICE': ['ジュース'],
      'CHEESE': ['チーズ'],
      'BUTTER': ['バター'],
      'SALAD': ['サラダ'],
      'COCOA': ['ココア'],
      'VANILLA': ['バニラ'],
      'BASIL': ['バジル'],
      'THYME': ['タイム'],
      'MINT': ['ミント'],
      'MANGO': ['マンゴー'],
      'PANDA': ['パンダ'],
      'BISON': ['バイソン'],
      'HYENA': ['ハイエナ'],
      'JACKAL': ['ジャッカル'],
      'GAZELLE': ['ガゼル'],
      'LYNX': ['リンクス'],
      'CANOE': ['カヌー'],
      'KAYAK': ['カヤック'],
      'FERRY': ['フェリー'],
      'YACHT': ['ヨット'],
      'WAGON': ['ワゴン'],
      'TRAILER': ['トレーラー'],
      'ENGINE': ['エンジン'],
      'CABLE': ['ケーブル'],
      'SOCKET': ['ソケット'],
      'PLUG': ['プラグ'],
      'SWITCH': ['スイッチ'],
      'LAMP': ['ランプ'],
      'TUNNEL': ['トンネル'],
      'COLUMN': ['コラム'],
      'BOLT': ['ボルト'],
      'SCREW': ['スクリュー'],
      'COLLAR': ['カラー'],
      'BELT': ['ベルト'],
      'SANDAL': ['サンダル'],
      'SLIPPER': ['スリッパ'],
      'BOOT': ['ブーツ'],
      'TUNIC': ['チュニック'],
      'VEST': ['ベスト'],
      'BLOUSE': ['ブラウス'],
      'SUIT': ['スーツ'],
      'DENIM': ['デニム'],
      'LINEN': ['リネン'],
      'VELVET': ['ベルベット'],
      'WOOL': ['ウール'],
      'SILK': ['シルク'],
      'LEATHER': ['レザー'],
      'ADVICE': ['アドバイス'],
      'BUDGET': ['バジェット'],
      'CHANCE': ['チャンス'],
      'CHOICE': ['チョイス'],
      'COST': ['コスト'],
      'ENERGY': ['エネルギー'],
      'EVENT': ['イベント'],
      'METHOD': ['メソッド'],
      'OPTION': ['オプション'],
      'PATTERN': ['パターン'],
      'ROUTINE': ['ルーティン'],
      'SIGNAL': ['シグナル'],
      'GLOBAL': ['グローバル'],
      'LOCAL': ['ローカル'],
      'NORMAL': ['ノーマル'],
      'SIMPLE': ['シンプル'],
      'AURA': ['オーラ'],
      'ESSAY': ['エッセイ'],
      'DOGMA': ['ドグマ'],
      'NUANCE': ['ニュアンス'],
      'MOTIF': ['モチーフ'],
      'THEME': ['テーマ'],
      'GENRE': ['ジャンル'],
      'RATIO': ['レシオ'],
      'SCALE': ['スケール'],
      'FRAME': ['フレーム'],
      'STATUS': ['ステータス'],
      'TACT': ['タクト'],
      'TENDER': ['テンダー'],
      'DILEMMA': ['ジレンマ'],
      'PARADOX': ['パラドックス'],
      'PEAK': ['ピーク'],
      'ECHO': ['エコー'],
      'MUTE': ['ミュート'],
      'SWAP': ['スワップ'],
    },
    'ko': {
      'HOTEL': ['호텔'],
      'MOTOR': ['모터'],
      'RADIO': ['라디오'],
      'CAMERA': ['카메라'],
      'ROBOT': ['로봇'],
      'TENNIS': ['테니스'],
      'SOFA': ['소파'],
      'TABLE': ['테이블'],
      'LIGHT': ['라이트'],
      'ORANGE': ['오렌지'],
      'COFFEE': ['커피'],
      'BANANA': ['바나나'],
      'LEMON': ['레몬'],
      'MELON': ['멜론'],
      'PASTA': ['파스타'],
      'YOGURT': ['요거트', '요구르트'],
      'COOKIE': ['쿠키'],
      'JUICE': ['주스'],
      'CHEESE': ['치즈'],
      'BUTTER': ['버터'],
      'SALAD': ['샐러드'],
      'COCOA': ['코코아'],
      'VANILLA': ['바닐라'],
      'BASIL': ['바질'],
      'THYME': ['타임'],
      'MINT': ['민트'],
      'MANGO': ['망고'],
      'PANDA': ['판다', '팬더'],
      'BISON': ['바이슨'],
      'HYENA': ['하이에나'],
      'JACKAL': ['자칼'],
      'GAZELLE': ['가젤'],
      'LYNX': ['링스'],
      'CANOE': ['카누'],
      'KAYAK': ['카약'],
      'FERRY': ['페리'],
      'YACHT': ['요트'],
      'WAGON': ['왜건'],
      'TRAILER': ['트레일러'],
      'ENGINE': ['엔진'],
      'CABLE': ['케이블'],
      'SOCKET': ['소켓'],
      'PLUG': ['플러그'],
      'SWITCH': ['스위치'],
      'LAMP': ['램프'],
      'TUNNEL': ['터널'],
      'COLUMN': ['칼럼', '컬럼'],
      'BOLT': ['볼트'],
      'BELT': ['벨트'],
      'SANDAL': ['샌들'],
      'SLIPPER': ['슬리퍼'],
      'BOOT': ['부츠'],
      'TUNIC': ['튜닉'],
      'VEST': ['베스트'],
      'BLOUSE': ['블라우스'],
      'SUIT': ['슈트'],
      'DENIM': ['데님'],
      'LINEN': ['리넨'],
      'VELVET': ['벨벳'],
      'WOOL': ['울'],
      'SILK': ['실크'],
      'LEATHER': ['레더'],
      'CHOICE': ['초이스'],
      'ENERGY': ['에너지'],
      'EVENT': ['이벤트'],
      'OPTION': ['옵션'],
      'PATTERN': ['패턴'],
      'ROUTINE': ['루틴'],
      'SIGNAL': ['시그널'],
      'GLOBAL': ['글로벌'],
      'LOCAL': ['로컬'],
      'NORMAL': ['노멀'],
      'AURA': ['아우라'],
      'ESSAY': ['에세이'],
      'DOGMA': ['도그마'],
      'NUANCE': ['뉘앙스'],
      'MOTIF': ['모티프'],
      'THEME': ['테마'],
      'GENRE': ['장르'],
      'SCALE': ['스케일'],
      'FRAME': ['프레임'],
      'DILEMMA': ['딜레마'],
      'PARADOX': ['패러독스'],
      'PEAK': ['피크'],
      'ECHO': ['에코'],
      'MUTE': ['뮤트'],
    },
    'zh-Hans': {
      'MOTOR': ['马达'],
      'ENGINE': ['引擎'],
      'COFFEE': ['咖啡'],
      'COCOA': ['可可'],
      'MANGO': ['芒果'],
      'SOFA': ['沙发'],
      'SALAD': ['沙拉'],
      'YOGURT': ['优格'],
      'CHEESE': ['芝士'],
    },
  };
  static const koreanBorrowings = [
    '초콜릿',
    '라켓',
    '피스톤',
    '너트',
    '디저트',
    '시트',
    '모터',
    '호텔',
    '카메라',
  ];
  static const chineseBorrowings = [
    '巧克力',
    '咖啡',
    '可可',
    '马达',
    '引擎',
    '沙发',
    '沙拉',
    '芒果',
  ];
  // Screening list of common Traditional-only forms, not full orthographic proof.
  static const traditionalOnly =
      r'[體國學門車書頁電動風雲鳥魚馬貓樹葉頭髮頸後腳齒銀銅鐵鋼礦寶錢給對從與為這個時過會記說話讀寫裡場廣權變讓邊聲氣麼]';
}
