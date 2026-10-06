import '../generation/word_entry.dart';
import 'word_catalogue.dart';

/// Developer/test gate for independent v1 banks; never invoked on Easy startup.
/// With 4–7 letters on 10x10, a pair can put both starts at axis coordinate 1:
/// a match at (i,j) crosses at (j+1,i+1), and both clue cells remain in bounds.
int crossingPositionOpportunities(String a, String b) {
  var count = 0;
  for (var i = 0; i < a.length; i++) {
    for (var j = 0; j < b.length; j++) {
      if (a[i] == b[j]) count++;
    }
  }
  return count;
}

class TrackCatalogueAudit {
  TrackCatalogueAudit(
    WordCatalogue catalogue, {
    Iterable<WordEntry> forbidden = const [],
    int expectedCount = 300,
    int minimumPartners = 100,
  }) {
    final errors = <String>[];
    if (!catalogue.isValid) {
      errors.addAll(catalogue.issues.where((i) => !i.warning).map((i) => '$i'));
    }
    if (catalogue.entries.length != expectedCount) {
      errors.add('Expected $expectedCount entries.');
    }
    final excluded = forbidden.map((w) => w.solution).toSet();
    final clues = <String, String>{};
    final partners = <String, int>{};
    final positions = <String, int>{};
    for (final word in catalogue.entries) {
      if (excluded.contains(word.solution)) {
        errors.add('Overlapping answer: ${word.solution}');
      }
      final clue = word.turkishClue
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (clues.containsKey(clue)) {
        errors.add('Duplicate clue: ${word.id} / ${clues[clue]}');
      }
      clues[clue] = word.id;
      if (RegExp(
        '\\b${word.solution}\\b',
        caseSensitive: false,
      ).hasMatch(word.turkishClue)) {
        errors.add('Answer leakage: ${word.id}');
      }
      if (RegExp(r'[0-9()]').hasMatch(word.turkishClue)) {
        errors.add('Clue hint/parentheses: ${word.id}');
      }
      var neighborCount = 0, opportunities = 0;
      for (final other in catalogue.entries) {
        if (word.id == other.id) continue;
        final matches = crossingPositionOpportunities(
          word.solution,
          other.solution,
        );
        if (matches > 0) neighborCount++;
        opportunities += matches;
      }
      if (neighborCount < minimumPartners) {
        errors.add('Low crossing partners: ${word.id}: $neighborCount');
      }
      partners[word.id] = neighborCount;
      positions[word.id] = opportunities;
    }
    issues = List.unmodifiable(errors);
    partnerCounts = Map.unmodifiable(partners);
    positionOpportunities = Map.unmodifiable(positions);
    // Observational semantic-overlap heuristic; human review is still required.
    final near = <String>[];
    final stop = {
      'bir',
      've',
      'veya',
      'olan',
      'şey',
      'şeyi',
      'için',
      'biçimde',
      'hale',
    };
    Set<String> tokens(String clue) => clue
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => !stop.contains(t))
        .toSet();
    final entries = catalogue.entries;
    for (var i = 0; i < entries.length; i++) {
      final a = tokens(entries[i].turkishClue);
      for (var j = i + 1; j < entries.length; j++) {
        final b = tokens(entries[j].turkishClue);
        final union = a.union(b);
        if (union.isNotEmpty &&
            a.intersection(b).length / union.length >= .65) {
          near.add('${entries[i].id} / ${entries[j].id}');
        }
      }
    }
    nearDuplicateClues = List.unmodifiable(near);
  }
  late final List<String> issues, nearDuplicateClues;
  late final Map<String, int> partnerCounts, positionOpportunities;
  bool get isValid => issues.isEmpty;
  int get minimumPartners =>
      partnerCounts.values.reduce((a, b) => a < b ? a : b);
  int get maximumPartners =>
      partnerCounts.values.reduce((a, b) => a > b ? a : b);
  double get averagePartners =>
      partnerCounts.values.reduce((a, b) => a + b) / partnerCounts.length;
}
