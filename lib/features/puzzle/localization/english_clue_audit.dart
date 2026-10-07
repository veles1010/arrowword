import '../generation/word_entry.dart';

/// Editorial diagnostics only. Never imported by puzzle search or selection.
class EnglishClueAudit {
  EnglishClueAudit(Iterable<WordEntry> words, Map<String, String> clues) {
    final entries = words.toList();
    final expected = entries.map((w) => w.clueId!).toSet();
    if (clues.length != entries.length ||
        !expected.containsAll(clues.keys) ||
        !clues.keys.toSet().containsAll(expected)) {
      errors.add('Clue ID coverage differs from catalogue');
    }
    final seen = <String, String>{};
    final answers = entries.map((w) => w.solution.toLowerCase()).toSet();
    for (final word in entries) {
      final id = word.clueId!;
      final clue = clues[id];
      if (clue == null || clue.trim().isEmpty) {
        errors.add('$id: missing or empty clue');
        continue;
      }
      final normalized = clue.trim().toLowerCase().replaceAll(
        RegExp(r'\s+'),
        ' ',
      );
      final previous = seen[normalized];
      if (previous != null) {
        errors.add('$id: duplicate of $previous');
      }
      seen[normalized] = id;
      final tokens = EnglishClueAudit.tokens(clue);
      final answer = word.solution.toLowerCase();
      if (tokens.contains(answer)) {
        errors.add('$id: direct answer leak ($answer)');
      } else if (tokens.any(definiteForms(answer).contains)) {
        errors.add('$id: inflected/derived answer leak ($answer)');
      }
      final root = answer.endsWith('e')
          ? answer.substring(0, answer.length - 1)
          : answer;
      final related = tokens
          .where(
            (t) => t != answer && t.length > root.length && t.contains(root),
          )
          .toSet();
      if (related.isNotEmpty) {
        rootWarnings.add('$id ${word.solution}: ${related.join(', ')}');
      }
      final count = RegExp(r"[A-Za-z0-9]+(?:['’-][A-Za-z0-9]+)*")
          .allMatches(clue)
          .length;
      final track = id.split('_').first;
      (wordCounts[track] ??= []).add(count);
      (characterCounts[track] ??= []).add(clue.length);
      final target = switch (track) {
        'easy' => 5,
        'medium' => 7,
        _ => 8,
      };
      if (count > target || clue.length > 65) {
        lengthWarnings.add(
          '$id ${word.solution}: $count words, ${clue.length} chars',
        );
      }
      if (RegExp(r'[^A-Za-z0-9\s\x27’,.\-]').hasMatch(clue) ||
          clue.endsWith('.') ||
          RegExp(r'\s{2,}|\d|[!?;:]').hasMatch(clue)) {
        punctuationWarnings.add('$id ${word.solution}: $clue');
      }
      if (RegExp(
        r'^(a type of thing|something that|a kind of)\b',
        caseSensitive: false,
      ).hasMatch(clue)) {
        genericWarnings.add('$id ${word.solution}: $clue');
      }
      final other = tokens
          .where((t) => t != answer && answers.contains(t))
          .toSet();
      if (other.isNotEmpty) {
        crossReferences.add('$id ${word.solution}: ${other.join(', ')}');
      }
    }
  }

  final errors = <String>[];
  final rootWarnings = <String>[];
  final lengthWarnings = <String>[];
  final punctuationWarnings = <String>[];
  final genericWarnings = <String>[];

  /// Informational: normal defining vocabulary may legitimately be another answer.
  final crossReferences = <String>[];
  final wordCounts = <String, List<int>>{};
  final characterCounts = <String, List<int>>{};
  bool get isValid => errors.isEmpty;

  static List<String> tokens(String value) =>
      RegExp(r'[a-z]+')
          .allMatches(value.toLowerCase())
          .map((m) => m[0]!)
          .toList();

  static Set<String> definiteForms(String answer) {
    final base = answer.toLowerCase();
    final stem = base.endsWith('e') ? base.substring(0, base.length - 1) : base;
    final forms = <String>{
      base,
      '${base}s',
      '${base}es',
      '${base}ed',
      '${base}ing',
      '${stem}ing',
      '${base}d',
    };
    for (final suffix in [
      'ly',
      'ness',
      'ful',
      'less',
      'ment',
      'er',
      'ers',
      'est',
      'y',
      'ish',
      'al',
      'ic',
      'ity',
      'ism',
      'ist',
      'ous',
      'able',
    ]) {
      forms.add('$base$suffix');
      forms.add('$stem$suffix');
    }
    if (base.endsWith('y')) {
      final yStem = base.substring(0, base.length - 1);
      forms.addAll(['${yStem}ies', '${yStem}ied', '${yStem}iness']);
    }
    if (RegExp(r'[aeiou][bcdfghjklmnpqrstvwxyz]$').hasMatch(base)) {
      forms.addAll([
        '$base${base[base.length - 1]}ing',
        '$base${base[base.length - 1]}ed',
      ]);
    }
    forms.addAll(
      const <String, List<String>>{
            'choose': ['choice', 'choices', 'chose', 'chosen'],
            'write': ['written', 'wrote'],
            'catch': ['caught'],
            'throw': ['threw', 'thrown'],
            'lend': ['lent'],
            'borrow': ['borrowing'],
            'wise': ['wisdom'],
            'think': ['thought'],
            'speak': ['spoke', 'spoken', 'speech'],
            'breathe': ['breath', 'breaths'],
            'believe': ['belief', 'beliefs'],
            'fly': ['flew', 'flown'],
            'tooth': ['teeth'],
            'foot': ['feet'],
            'mouse': ['mice'],
            'farm': ['farmhouse', 'farmhouses', 'farmland'],
            'rain': ['rainfall'],
            'child': ['children'],
            'person': ['people'],
          }[base] ??
          const [],
    );
    return forms;
  }

  Map<String, Object> statistics(String track) {
    final words = wordCounts[track] ?? [];
    final chars = characterCounts[track] ?? [];
    num average(List<int> values) =>
        values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;
    int maximum(List<int> values) =>
        values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
    return {
      'count': words.length,
      'averageWords': average(words),
      'maxWords': maximum(words),
      'averageCharacters': average(chars),
      'maxCharacters': maximum(chars),
    };
  }
}
