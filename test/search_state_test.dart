import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_validator.dart';
import 'package:arrowword/features/puzzle/generation/src/search_state.dart';
import 'package:arrowword/features/puzzle/generation/word_entry.dart';
import 'package:flutter_test/flutter_test.dart';

SearchCatalog catalog({int rows = 7, int columns = 8}) {
  final words = [
    'TREE',
    'RAIN',
    'NEON',
    'ECHO',
    'EAR',
    'ROAD',
    'NODE',
    'NOTE',
    'TONE',
    'CONE',
    'RING',
    'ROSE',
    'DEER',
  ]..sort();
  return SearchCatalog(
    words.map((w) => WordEntry(w, 'İpucu')).toList(),
    rows,
    columns,
  );
}

SearchPlacement at(
  SearchCatalog c,
  String word,
  int direction,
  int row,
  int column,
) => c.placement(
  c.words.indexWhere((w) => w.solution == word),
  direction,
  row,
  column,
)!;

Puzzle puzzle(SearchState s, [PuzzleAnswer? added]) => Puzzle(
  id: 'reference',
  label: 'Test',
  rowCount: s.catalog.rows,
  columnCount: s.catalog.columns,
  answers: [...s.placed.map(s.catalog.answer), ?added],
);

String signature(PuzzleAnswer a) =>
    '${a.solution}:${a.direction.name}:${a.start.row},${a.start.column}:'
    '${a.cluePosition.row},${a.cluePosition.column}';

// Intentionally does NOT use the catalog placement factory, index, span filter,
// or incremental validator. Exhaust all starts and ask the independent strict
// domain validator. This catches omissions as well as illegal extra candidates.
Set<String> bruteForce(SearchState s) {
  final result = <String>{};
  for (var w = 0; w < s.catalog.words.length; w++) {
    if (s.used[w]) continue;
    final word = s.catalog.words[w];
    for (final direction in AnswerDirection.values) {
      for (var row = 0; row < s.catalog.rows; row++) {
        for (var column = 0; column < s.catalog.columns; column++) {
          final a = PuzzleAnswer(
            id: word.solution.toLowerCase(),
            solution: word.solution,
            turkishClue: word.turkishClue,
            direction: direction,
            start: GridPosition(row, column),
            cluePosition: direction == AnswerDirection.right
                ? GridPosition(row, column - 1)
                : GridPosition(row - 1, column),
          );
          if (const PuzzleValidator().validate(puzzle(s, a)).isValid) {
            result.add(signature(a));
          }
        }
      }
    }
  }
  return result;
}

List<String> legacyOrder(SearchState s, Set<String> legal) {
  final result = <String>{};
  for (final word in s.catalog.words) {
    for (final p in s.placed) {
      final existing = s.catalog.answer(p);
      for (var i = 0; i < existing.length; i++) {
        for (var j = 0; j < word.solution.length; j++) {
          if (existing.solution[i] != word.solution[j]) continue;
          final cross = existing.positions[i];
          final horizontal = existing.direction == AnswerDirection.down;
          final start = GridPosition(
            cross.row - (horizontal ? 0 : j),
            cross.column - (horizontal ? j : 0),
          );
          final a = PuzzleAnswer(
            id: word.solution,
            solution: word.solution,
            turkishClue: word.turkishClue,
            start: start,
            direction: horizontal
                ? AnswerDirection.right
                : AnswerDirection.down,
            cluePosition: GridPosition(
              start.row - (horizontal ? 0 : 1),
              start.column - (horizontal ? 1 : 0),
            ),
          );
          final key = signature(a);
          if (legal.contains(key)) result.add(key);
        }
      }
    }
  }
  return result.toList();
}

Map<String, Object?> snapshot(SearchState s) => {
  'letters': [...s.letters],
  'directions': [...s.directions],
  'clues': [...s.clues],
  'used': [...s.used],
  'bounds': s.bounds,
  'right': s.rightCount,
  'down': s.downCount,
  'crossings': s.crossingCount,
  'key': s.key,
  'placed': s.placed.map((p) => p.id).toList(),
};

void main() {
  test('letter index has every occurrence in sorted word/offset order', () {
    final c = catalog();
    for (var letter = 65; letter <= 90; letter++) {
      final expected = <String>[];
      for (var w = 0; w < c.words.length; w++) {
        for (var i = 0; i < c.words[w].solution.length; i++) {
          if (c.words[w].solution.codeUnitAt(i) == letter) {
            expected.add('$w:$i');
          }
        }
      }
      expect(
        c.byLetter[letter - 65].map((o) => '${o.word}:${o.offset}'),
        expected,
      );
    }
    expect(() => c.byLetter[0].clear(), throwsUnsupportedError);
  });

  test('placement catalog reuses geometry and rejects invalid clues/ends', () {
    final c = catalog();
    final w = c.words.indexWhere((w) => w.solution == 'TREE');
    expect(identical(c.placement(w, 1, 1, 1), c.placement(w, 1, 1, 1)), isTrue);
    expect(c.placement(w, 1, 1, 0), isNull);
    expect(c.placement(w, 2, 0, 1), isNull);
    expect(c.placement(w, 1, 1, 6), isNull);
    expect(c.placement(w, 2, 6, 1), isNull);
  });

  test(
    'place/unplace restores every field, including a two-crossing cycle',
    () {
      final c = catalog();
      final s = SearchState(c);
      final placements = [
        at(c, 'TREE', 1, 1, 1),
        at(c, 'RAIN', 2, 1, 2),
        at(c, 'NEON', 1, 4, 2),
        at(c, 'ECHO', 2, 1, 4),
      ];
      final snapshots = <Map<String, Object?>>[];
      for (var i = 0; i < placements.length; i++) {
        snapshots.add(snapshot(s));
        if (i > 0) expect(s.canPlace(placements[i]), i == 3 ? 2 : 1);
        s.place(placements[i]);
        final model = puzzle(s);
        expect(const PuzzleValidator().validate(model).isValid, isTrue);
        expect(s.crossingCount, model.crossingPositions.length);
        expect(
          s.rightCount,
          model.answers
              .where((a) => a.direction == AnswerDirection.right)
              .length,
        );
        expect(s.bounds, (
          minRow: model.displayBounds.minRow,
          maxRow: model.displayBounds.maxRow,
          minColumn: model.displayBounds.minColumn,
          maxColumn: model.displayBounds.maxColumn,
        ));
      }
      expect(s.crossingCount, 4);
      for (final before in snapshots.reversed) {
        s.unplace();
        expect(snapshot(s), before);
      }
    },
  );

  test(
    'canonical key ignores insertion order but distinguishes placements',
    () {
      final c = catalog();
      final first = SearchState(c)
        ..place(at(c, 'TREE', 1, 1, 1))
        ..place(at(c, 'RAIN', 2, 1, 2));
      final reverse = SearchState(c)
        ..place(at(c, 'RAIN', 2, 1, 2))
        ..place(at(c, 'TREE', 1, 1, 1));
      final shifted = SearchState(c)
        ..place(at(c, 'TREE', 1, 2, 1))
        ..place(at(c, 'RAIN', 2, 2, 2));
      expect(first.key, reverse.key);
      expect(first.key, isNot(shifted.key));
      final keys = <String>{};
      for (var w = 0; w < c.words.length; w++) {
        for (var d = 1; d <= 2; d++) {
          for (var r = 0; r < c.rows; r++) {
            for (var col = 0; col < c.columns; col++) {
              final p = c.placement(w, d, r, col);
              if (p == null) continue;
              final s = SearchState(c)..place(p);
              expect(keys.add(s.key), isTrue);
            }
          }
        }
      }
    },
  );

  for (final transpose in [false, true]) {
    test(
      'indexed candidates equal brute force; legacy order and scores ($transpose)',
      () {
        final c = catalog(rows: transpose ? 8 : 7, columns: transpose ? 7 : 8);
        final s = SearchState(c);
        final definitions = [
          ('TREE', 1, 1, 1),
          ('RAIN', 2, 1, 2),
          ('NEON', 1, 4, 2),
          ('ECHO', 2, 1, 4),
        ];
        for (final d in definitions) {
          s.place(
            at(
              c,
              d.$1,
              transpose ? 3 - d.$2 : d.$2,
              transpose ? d.$4 : d.$3,
              transpose ? d.$3 : d.$4,
            ),
          );
          final before = snapshot(s);
          final expected = bruteForce(s);
          final work = SearchWork();
          final candidates = enumerateCandidates(s, work, 100000);
          final actual = candidates
              .map((p) => signature(c.answer(p.placement)))
              .toList();
          expect(actual.toSet(), expected);
          expect(actual, legacyOrder(s, expected));
          expect(actual.toSet().length, actual.length);
          expect(
            enumerateCandidates(
              s,
              SearchWork(),
              100000,
            ).map((p) => p.placement.id),
            candidates.map((p) => p.placement.id),
          );
          for (final candidate in candidates) {
            final model = puzzle(s, c.answer(candidate.placement));
            final crossings = candidate.placement.cells
                .where((cell) => s.letters[cell] != 0)
                .length;
            final b = model.displayBounds;
            final right = model.answers
                .where((a) => a.direction == AnswerDirection.right)
                .length;
            expect(
              s.placementScore(candidate.placement, candidate.crossings),
              400 * crossings -
                  2 * b.rowCount * b.columnCount -
                  12 * b.columnCount -
                  8 * (2 * right - model.answers.length).abs(),
            );
          }
          expect(
            work.candidateChecks,
            work.legalCandidates + work.candidatesRejected,
          );
          expect(
            work.candidatePlacementsGenerated,
            work.candidateChecks +
                work.spanRejected +
                work.boundsRejected +
                work.duplicateCandidates,
          );
          expect(snapshot(s), before);
        }
      },
    );
  }
}
