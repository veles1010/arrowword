import 'package:arrowword/features/puzzle/content/word_catalogue.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/generation/word_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/catalogue_v1.dart';

void main() {
  WordCatalogue catalogue(List<WordEntry> words) =>
      WordCatalogue(version: 1, entries: words);
  Set<String> codes(List<WordEntry> words) =>
      catalogue(words).issues.map((i) => i.code).toSet();
  test(
    'v2 catalogue has 300 valid, crossable entries and deliberate metadata',
    () {
      final c = prototypeCatalogue;
      expect(c.isValid, isTrue);
      expect(c.issues, isEmpty);
      expect(c.version, 2);
      expect(c.health.lowPartnerIds(maximum: 0), isEmpty);
      expect(c.entries.every((w) => w.tags.isNotEmpty), isTrue);
      expect(c.entries, hasLength(300));
      expect(c.entries.map((w) => w.id).toSet(), hasLength(300));
      expect(c.health.difficultyCounts, {
        WordDifficulty.easy: 210,
        WordDifficulty.medium: 75,
        WordDifficulty.hard: 15,
      });
      expect(c.health.lengthCounts, {4: 68, 5: 102, 6: 99, 7: 31});
    },
  );
  test('all 60 original pairs and metadata survive v2 unchanged', () {
    expect(legacyWordBank, hasLength(60));
    final entries = {for (final w in prototypeCatalogue.entries) w.id: w};
    for (final original in legacyWordBank) {
      final current = entries[original.id]!;
      expect(current.solution, original.solution);
      expect(current.turkishClue, original.turkishClue);
      expect(current.difficulty, original.difficulty);
      expect(current.tags, original.tags);
    }
    expect(
      entries.keys.toSet().difference(legacyWordBank.map((w) => w.id).toSet()),
      hasLength(240),
    );
  });
  test(
    'normalizes solutions/clues but preserves explicit identity and metadata',
    () {
      final c = catalogue([
        const WordEntry(
          ' apple ',
          ' Elma ',
          id: 'fruit-001',
          difficulty: WordDifficulty.medium,
          tags: ['food', 'plant'],
        ),
      ]);
      final w = c.entries.single;
      expect(w.solution, 'APPLE');
      expect(w.turkishClue, 'Elma');
      expect(w.id, 'fruit-001');
      expect(w.tags, ['food', 'plant']);
      expect(w.difficulty, WordDifficulty.medium);
      expect(c.isValid, isTrue); // Zero partners is a warning, not a rejection.
    },
  );
  test('duplicate ids and normalized solutions are explicit errors', () {
    expect(
      codes([
        const WordEntry('APPLE', 'Elma', id: 'same'),
        const WordEntry('PEAR', 'Armut', id: 'same'),
      ]),
      contains('duplicate_id'),
    );
    expect(
      codes([
        const WordEntry('APPLE', 'Elma', id: 'one'),
        const WordEntry(' apple ', 'Elma', id: 'two'),
      ]),
      contains('duplicate_solution'),
    );
  });
  test('rejects empty clues and invalid English solution characters', () {
    for (final solution in ['ICE CREAM', 'CAFÉ', 'A1BC', 'AB-CD', '']) {
      expect(
        codes([WordEntry(solution, 'İpucu', id: 'word')]),
        contains('characters'),
      );
    }
    expect(codes([const WordEntry('APPLE', '   ')]), contains('clue'));
  });
  test('length policy is configurable and never silently drops entries', () {
    final c = catalogue([
      const WordEntry('CAT', 'Kedi'),
      const WordEntry('ELEPHANT', 'Fil'),
    ]);
    expect(c.entries, hasLength(2));
    expect(c.issues.where((i) => i.code == 'length'), hasLength(2));
    expect(
      WordCatalogue(
        version: 1,
        entries: c.entries,
        minLength: 3,
        maxLength: 8,
      ).isValid,
      isTrue,
    );
  });
  test('invalid ids, tags and duplicate tags are reported', () {
    expect(codes([const WordEntry('APPLE', 'Elma', id: '')]), contains('id'));
    expect(
      codes([const WordEntry('APPLE', 'Elma', id: 'Bad ID')]),
      contains('id'),
    );
    expect(
      codes([
        const WordEntry('APPLE', 'Elma', tags: ['', 'food', 'food']),
      ]),
      containsAll(['tag', 'duplicate_tag']),
    );
  });
  test(
    'invalid catalogue configuration and empty catalogue fail explicitly',
    () {
      expect(catalogue([]).isValid, isFalse);
      expect(
        WordCatalogue(
          version: 0,
          entries: [],
          minLength: 7,
          maxLength: 4,
        ).issues.map((i) => i.code),
        contains('configuration'),
      );
    },
  );
  test(
    'crossing partners count words, not repeated letters; zero is warning',
    () {
      final c = catalogue([
        const WordEntry('TREE', 'Ağaç'),
        const WordEntry('DEER', 'Geyik'),
        const WordEntry('MAMA', 'Anne'),
      ]);
      expect(c.health.partnerCounts, {'deer': 1, 'mama': 0, 'tree': 1});
      expect(c.health.letterFrequency['E'], 4);
      expect(c.health.lowPartnerIds(maximum: 0), ['mama']);
      expect(c.issues.single.warning, isTrue);
      expect(c.isValid, isTrue);
    },
  );
  test('catalogue snapshots metadata and provides read-only collections', () {
    final tags = ['food'];
    final words = [WordEntry('APPLE', 'Elma', tags: tags)];
    final c = catalogue(words);
    words.clear();
    tags.clear();
    expect(c.entries.single.tags, ['food']);
    expect(() => c.entries.clear(), throwsUnsupportedError);
    expect(() => c.entries.single.tags.clear(), throwsUnsupportedError);
  });
}
