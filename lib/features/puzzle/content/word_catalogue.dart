import '../generation/word_entry.dart';

class ContentIssue {
  const ContentIssue(
    this.code,
    this.entryId,
    this.message, {
    this.warning = false,
  });
  final String code, entryId, message;
  final bool warning;
  @override
  String toString() =>
      '${warning ? 'warning' : 'error'} $code [$entryId]: $message';
}

/// Compile-time/local content, normalized and frozen at the pipeline boundary.
/// Version changes require deliberate compatibility decisions, not persistence.
class WordCatalogue {
  WordCatalogue({
    required this.version,
    required List<WordEntry> entries,
    this.minLength = 4,
    this.maxLength = 7,
  }) : entries = List.unmodifiable(
         entries.map((w) => w.normalized()).toList()
           ..sort((a, b) => a.id.compareTo(b.id)),
       ) {
    health = CatalogueHealth(this.entries);
    final problems = <ContentIssue>[];
    void error(String code, String id, String message) =>
        problems.add(ContentIssue(code, id, message));
    if (version < 1 || minLength < 2 || maxLength < minLength) {
      error('configuration', '', 'Invalid catalogue version or length range.');
    }
    if (entries.isEmpty) error('empty_catalogue', '', 'No entries.');
    final ids = <String>{}, solutions = <String>{};
    final token = RegExp(r'^[a-z][a-z0-9_-]*$');
    for (final word in this.entries) {
      if (!token.hasMatch(word.id)) error('id', word.id, 'Invalid stable id.');
      if (!ids.add(word.id)) {
        error('duplicate_id', word.id, 'Duplicate stable id.');
      }
      if (!solutions.add(word.solution)) {
        error('duplicate_solution', word.id, 'Duplicate normalized solution.');
      }
      if (!RegExp(r'^[A-Z]+$').hasMatch(word.solution)) {
        error('characters', word.id, 'Expected English A–Z.');
      }
      if (word.solution.length < minLength ||
          word.solution.length > maxLength) {
        error('length', word.id, 'Expected $minLength–$maxLength letters.');
      }
      if (word.turkishClue.isEmpty) {
        error('clue', word.id, 'Empty Turkish clue.');
      }
      if (word.tags.any((tag) => !token.hasMatch(tag))) {
        error('tag', word.id, 'Invalid tag.');
      }
      if (word.tags.toSet().length != word.tags.length) {
        error('duplicate_tag', word.id, 'Duplicate tag.');
      }
      if (health.partnerCounts[word.id] == 0) {
        problems.add(
          ContentIssue(
            'no_partners',
            word.id,
            'No other solution shares an English letter.',
            warning: true,
          ),
        );
      }
    }
    issues = List.unmodifiable(problems);
  }

  final int version, minLength, maxLength;
  final List<WordEntry> entries;
  late final List<ContentIssue> issues;
  late final CatalogueHealth health;
  bool get isValid => !issues.any((issue) => !issue.warning);
}

class CatalogueHealth {
  CatalogueHealth(List<WordEntry> entries) {
    totalCount = entries.length;
    uniqueSolutionCount = entries.map((w) => w.solution).toSet().length;
    final difficulties = {for (final d in WordDifficulty.values) d: 0};
    final lengths = <int, int>{};
    final letters = {for (var c = 65; c <= 90; c++) String.fromCharCode(c): 0};
    final masks = <Set<String>>[];
    for (final word in entries) {
      difficulties[word.difficulty] = difficulties[word.difficulty]! + 1;
      lengths.update(word.solution.length, (n) => n + 1, ifAbsent: () => 1);
      final chars = word.solution.split('').where(letters.containsKey).toList();
      for (final c in chars) {
        letters[c] = letters[c]! + 1;
      }
      masks.add(chars.toSet());
    }
    final partners = <String, int>{};
    for (var i = 0; i < entries.length; i++) {
      var count = 0;
      for (var j = 0; j < entries.length; j++) {
        if (i != j &&
            entries[i].solution != entries[j].solution &&
            masks[i].any(masks[j].contains)) {
          count++;
        }
      }
      partners[entries[i].id] = count;
    }
    difficultyCounts = Map.unmodifiable(difficulties);
    lengthCounts = Map.unmodifiable({
      for (final k in lengths.keys.toList()..sort()) k: lengths[k]!,
    });
    letterFrequency = Map.unmodifiable(letters);
    partnerCounts = Map.unmodifiable(partners);
  }
  late final int totalCount, uniqueSolutionCount;
  late final Map<WordDifficulty, int> difficultyCounts;
  late final Map<int, int> lengthCounts;
  late final Map<String, int> letterFrequency, partnerCounts;
  List<String> lowPartnerIds({int maximum = 2}) =>
      partnerCounts.keys.where((id) => partnerCounts[id]! <= maximum).toList()
        ..sort();
  double get averagePartners => partnerCounts.isEmpty
      ? 0
      : partnerCounts.values.reduce((a, b) => a + b) / partnerCounts.length;
}
