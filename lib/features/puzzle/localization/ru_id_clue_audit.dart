import '../generation/word_entry.dart';
import 'localized_clue_audit.dart';

/// Offline screening complements editorial review; never used in generation.
class RuIdClueAudit {
  RuIdClueAudit(
    this.locale,
    List<WordEntry> words,
    this.clues,
    Map<String, String> english,
  ) {
    if (locale != 'ru' && locale != 'id') {
      throw ArgumentError.value(locale);
    }
    basic = LocalizedClueAudit(words, clues, english);
    errors.addAll(basic.errors);
    errors.addAll(basic.punctuationWarnings);
    for (final word in words) {
      final id = word.clueId!, clue = clues[id];
      if (clue == null) continue;
      final tokens = LocalizedClueAudit.tokenize(clue);
      if (locale == 'ru') {
        if (!RegExp(r'[А-Яа-яЁё]').hasMatch(clue) ||
            RegExp(
              r'[^\p{Script=Cyrillic}\s\p{P}\p{N}]',
              unicode: true,
            ).hasMatch(clue)) {
          untranslatedWarnings.add('$id: unexpected script — $clue');
        }
      } else {
        if (RegExp(r'[\u0400-\u04ff\u3040-\u30ff\u3400-\u9fff\uac00-\ud7a3]')
            .hasMatch(clue)) {
          untranslatedWarnings.add('$id: unexpected script — $clue');
        }
        final source = LocalizedClueAudit.tokenize(english[id] ?? '').toSet();
        final shared = tokens.where(source.contains).toSet();
        if ((shared.length >= 2 && shared.length / tokens.length >= .6) ||
            tokens.any(englishFunctionWords.contains)) {
          untranslatedWarnings.add('$id: possible English fragment — $clue');
        }
      }
      final aliases = ownForms[locale]?[word.solution] ?? const <String>[];
      for (final alias in aliases) {
        // Long stems catch inflected Russian borrowings, not arbitrary substrings.
        final hit = tokens.any(
          (t) =>
              t == alias ||
              (locale == 'ru' && alias.length >= 4 && t.startsWith(alias)),
        );
        if (hit) {
          errors.add('$id: phonetic/borrowed answer revelation ($alias)');
        }
      }
      for (final token in tokens) {
        if ((borrowedVocabulary[locale] ?? const <String>[]).contains(token)) {
          loanWarnings.add('$id (${word.solution}): $token — $clue');
        }
      }
      if (tokens.length > 8 || clue.runes.length > 65) {
        lengthWarnings.add('$id: ${clue.runes.length} characters — $clue');
      }
    }
  }
  final String locale;
  final Map<String, String> clues;
  late final LocalizedClueAudit basic;
  final errors = <String>[];
  final loanWarnings = <String>[];
  final untranslatedWarnings = <String>[];
  final lengthWarnings = <String>[];
  Map<String, Object> statistics(String track) => basic.statistics(track);

  // A curated, word-aware screen, not universal transliteration detection.
  // Full review also covers aliases absent here and near-synonym ambiguity.
  static const ownForms = <String, Map<String, List<String>>>{
    'ru': {
      'MOTOR': ['мотор'],
      'HOTEL': ['отель', 'хотел'],
      'RADIO': ['радио'],
      'SPORT': ['спорт'],
      'CAMERA': ['камер'],
      'ROBOT': ['робот'],
      'TENNIS': ['теннис'],
      'SOFA': ['софа'],
      'LEMON': ['лимон'],
      'BANANA': ['банан'],
      'MELON': ['мелон'],
      'PASTA': ['паста'],
      'YOGURT': ['йогурт'],
      'SALAD': ['салат'],
      'COCOA': ['какао'],
      'VANILLA': ['ванил'],
      'BASIL': ['базилик'],
      'MANGO': ['манго'],
      'PANDA': ['панд'],
      'ZEBRA': ['зебр'],
      'BISON': ['бизон'],
      'HYENA': ['гиен'],
      'JACKAL': ['шакал'],
      'GAZELLE': ['газел'],
      'CANOE': ['каноэ'],
      'KAYAK': ['каяк'],
      'YACHT': ['яхт'],
      'TRAILER': ['трейлер'],
      'ENGINE': ['энджин'],
      'CABLE': ['кабель'],
      'LAMP': ['ламп'],
      'TUNNEL': ['туннел'],
      'GARAGE': ['гараж'],
      'BALCONY': ['балкон'],
      'PALACE': ['палац'],
      'COLUMN': ['колумн'],
      'PILLAR': ['пиллар'],
      'BOLT': ['болт'],
      'SANDAL': ['сандал'],
      'TUNIC': ['туник'],
      'BLOUSE': ['блуз'],
      'DENIM': ['деним'],
      'BUDGET': ['бюджет'],
      'ENERGY': ['энерги'],
      'METHOD': ['метод'],
      'SIGNAL': ['сигнал'],
      'GLOBAL': ['глобал'],
      'LOCAL': ['локал'],
      'NORMAL': ['нормал'],
      'ACTIVE': ['актив'],
      'AURA': ['аура'],
      'ESSAY': ['эссе'],
      'THESIS': ['тезис'],
      'AXIOM': ['аксиом'],
      'DOGMA': ['догм'],
      'ETHOS': ['этос'],
      'LOGIC': ['логик'],
      'IRONY': ['ирони'],
      'SATIRE': ['сатир'],
      'PARODY': ['парод'],
      'NUANCE': ['нюанс'],
      'MOTIF': ['мотив'],
      'THEME': ['тема'],
      'GENRE': ['жанр'],
      'PROSE': ['проз'],
      'LYRIC': ['лирик'],
      'METRIC': ['метрик'],
      'STATUS': ['статус'],
      'ASSET': ['ассет'],
      'FISCAL': ['фискал'],
      'TACT': ['такт'],
      'STOIC': ['стоик'],
      'DILEMMA': ['дилемм'],
      'ANOMALY': ['аномал'],
      'PARADOX': ['парадокс'],
      'HALO': ['гало'],
    },
    'id': {
      'MOTOR': ['motor'],
      'HOTEL': ['hotel'],
      'RADIO': ['radio'],
      'SPORT': ['sport'],
      'CAMERA': ['kamera'],
      'ROBOT': ['robot'],
      'TENNIS': ['tenis'],
      'SOFA': ['sofa'],
      'SALAD': ['salad'],
      'PASTA': ['pasta'],
      'YOGURT': ['yogurt', 'yoghurt'],
      'MANGO': ['mango'],
      'PANDA': ['panda'],
      'ZEBRA': ['zebra'],
      'BISON': ['bison'],
      'HYENA': ['hiena'],
      'GAZELLE': ['gazel'],
      'KAYAK': ['kayak'],
      'FERRY': ['feri'],
      'TRAILER': ['trailer'],
      'CABLE': ['kabel'],
      'LAMP': ['lampu'],
      'BALCONY': ['balkon'],
      'GARAGE': ['garasi'],
      'COLUMN': ['kolom'],
      'PILLAR': ['pilar'],
      'SANDAL': ['sandal'],
      'TUNIC': ['tunik'],
      'BLOUSE': ['blus'],
      'DENIM': ['denim'],
      'LINEN': ['linen'],
      'WOOL': ['wol'],
      'ENERGY': ['energi'],
      'METHOD': ['metode'],
      'OPTION': ['opsi'],
      'PATTERN': ['patern'],
      'ROUTINE': ['rutin'],
      'SIGNAL': ['sinyal'],
      'GLOBAL': ['global'],
      'LOCAL': ['lokal'],
      'NORMAL': ['normal'],
      'ACTIVE': ['aktif'],
      'BASIC': ['basis'],
      'AURA': ['aura'],
      'ESSAY': ['esai'],
      'THESIS': ['tesis'],
      'AXIOM': ['aksioma'],
      'DOGMA': ['dogma'],
      'ETHOS': ['etos'],
      'LOGIC': ['logika'],
      'IRONY': ['ironi'],
      'SATIRE': ['satire', 'satir'],
      'PARODY': ['parodi'],
      'NUANCE': ['nuansa'],
      'MOTIF': ['motif'],
      'THEME': ['tema'],
      'GENRE': ['genre'],
      'PROSE': ['prosa'],
      'LYRIC': ['lirik'],
      'METRIC': ['metrik'],
      'RATIO': ['rasio'],
      'SCALE': ['skala'],
      'STATUS': ['status'],
      'ASSET': ['aset'],
      'FISCAL': ['fiskal'],
      'STOIC': ['stoik'],
      'DILEMMA': ['dilema'],
      'ANOMALY': ['anomali'],
      'PARADOX': ['paradoks'],
    },
  };
  static const englishFunctionWords = {
    'the',
    'with',
    'without',
    'and',
    'of',
    'from',
  };
  // Legitimate technical nouns are reported, not suppressed or treated as leaks
  // merely because they occur in a different answer's clue.
  static const borrowedVocabulary = {
    'ru': [
      'цитрус',
      'шоколада',
      'спагетти',
      'графитовым',
      'цилиндр',
      'скульптур',
      'скульптуры',
      'примат',
      'кристалл',
      'конуса',
      'керамики',
    ],
    'id': [
      'kristal',
      'spageti',
      'grafit',
      'primata',
      'piston',
      'tentakel',
      'portabel',
      'flaks',
      'antusias',
      'transaksi',
      'monoton',
      'satellit',
    ],
  };
}
