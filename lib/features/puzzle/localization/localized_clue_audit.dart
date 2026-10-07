import '../generation/word_entry.dart';

/// Editorial diagnostics only, independent of runtime clue lookup/generation.
class LocalizedClueAudit {
  LocalizedClueAudit(this.words, this.clues, this.english) {
    final expected = words.map((word) => word.clueId!).toSet();
    if (clues.length != expected.length ||
        expected.any((id) => !clues.containsKey(id)) ||
        clues.keys.any((id) => !expected.contains(id))) {
      errors.add('Clue ID coverage differs from catalogue');
    }
    final seen = <String, String>{};
    for (final word in words) {
      final id = word.clueId!;
      final clue = clues[id];
      if (clue == null || clue.trim().isEmpty) {
        errors.add('$id: missing clue');
        continue;
      }
      final normalized = clue.trim().toLowerCase().replaceAll(
        RegExp(r'\s+'),
        ' ',
      );
      if (seen.containsKey(normalized)) {
        errors.add('$id: duplicate of ${seen[normalized]}');
      }
      seen[normalized] = id;
      final tokens = tokenize(clue);
      final answer = word.solution.toLowerCase();
      if (tokens.contains(answer)) errors.add('$id: direct answer leakage');
      final stem = answer.endsWith('e')
          ? answer.substring(0, answer.length - 1)
          : answer;
      final englishForms = {
        '${answer}s',
        '${answer}es',
        '${answer}ed',
        '${answer}ing',
        '${stem}ed',
        '${stem}ing',
      };
      if (tokens.any(englishForms.contains)) {
        errors.add('$id: English inflection leakage');
      }
      if (clue == english[id]) errors.add('$id: untranslated English clue');
      final root = answer.endsWith('e')
          ? answer.substring(0, answer.length - 1)
          : answer;
      if (tokens.any((token) => token.startsWith(root) && token != answer)) {
        rootWarnings.add('$id ($answer): $clue');
      }
      if (tokens.length > 10 || clue.runes.length > 85) {
        lengthWarnings.add('$id: $clue');
      }
      if (RegExp(r'[\x00-\x1f<>]|[!?]{2}|\uFFFD').hasMatch(clue) ||
          clue.endsWith('.')) {
        punctuationWarnings.add('$id: $clue');
      }
    }
  }
  final List<WordEntry> words;
  final Map<String, String> clues, english;
  final errors = <String>[];
  final rootWarnings = <String>[];
  final lengthWarnings = <String>[];
  final punctuationWarnings = <String>[];
  static List<String> tokenize(String clue) => RegExp(
    r'[\p{L}\p{M}]+',
    unicode: true,
  ).allMatches(clue.toLowerCase()).map((m) => m.group(0)!).toList();
  Map<String, Object> statistics(String track) {
    final values = clues.entries
        .where((entry) => entry.key.startsWith('${track}_'))
        .map((e) => e.value)
        .toList();
    final counts = values.map((s) => tokenize(s).length).toList();
    final lengths = values.map((s) => s.runes.length).toList();
    return {
      'count': values.length,
      'averageWords': counts.reduce((a, b) => a + b) / counts.length,
      'maxWords': counts.reduce((a, b) => a > b ? a : b),
      'averageCharacters': lengths.reduce((a, b) => a + b) / lengths.length,
      'maxCharacters': lengths.reduce((a, b) => a > b ? a : b),
    };
  }
}
