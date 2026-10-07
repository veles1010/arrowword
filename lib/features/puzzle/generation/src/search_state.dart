import 'dart:math';

import '../../domain/puzzle.dart';
import '../word_entry.dart';

/// Generator-internal data; kept separate to test the optimized search against
/// an independent, deliberately slow reference. Presentation uses only Puzzle.
class WordOccurrence {
  const WordOccurrence(this.word, this.offset);
  final int word, offset;
}

class SearchCatalog {
  SearchCatalog(List<WordEntry> entries, this.rows, this.columns)
    : words = List.unmodifiable(entries),
      codes = List.unmodifiable(entries.map((w) => w.solution.codeUnits)),
      _placements = List.filled(entries.length * 2 * rows * columns, null) {
    longestWord = codes.fold(0, (n, word) => max(n, word.length));
    final letters = List.generate(26, (_) => <WordOccurrence>[]);
    for (var word = 0; word < words.length; word++) {
      for (var offset = 0; offset < codes[word].length; offset++) {
        letters[codes[word][offset] - 65].add(WordOccurrence(word, offset));
      }
    }
    byLetter = List.unmodifiable(
      letters.map(List<WordOccurrence>.unmodifiable),
    );
  }

  final List<WordEntry> words;
  final List<List<int>> codes;
  final int rows, columns;
  late final List<List<WordOccurrence>> byLetter;
  late final int longestWord;
  final List<SearchPlacement?> _placements;

  // Collision-free within this catalog: word, direction and in-grid start.
  SearchPlacement? placement(int word, int direction, int row, int column) {
    final length = codes[word].length;
    if (row < 0 ||
        column < 0 ||
        row >= rows ||
        column >= columns ||
        (direction == 1 && (column == 0 || column + length > columns)) ||
        (direction == 2 && (row == 0 || row + length > rows))) {
      return null;
    }
    final id = ((word * 2 + direction - 1) * rows + row) * columns + column;
    return _placements[id] ??= SearchPlacement._(
      id,
      word,
      direction,
      row,
      column,
      codes[word],
      columns,
      rows,
    );
  }

  PuzzleAnswer answer(SearchPlacement p) => PuzzleAnswer(
    id: words[p.word].id,
    solution: words[p.word].solution,
    turkishClue: words[p.word].turkishClue,
    clueId: words[p.word].clueId,
    start: GridPosition(p.row, p.column),
    direction: p.direction == 1 ? AnswerDirection.right : AnswerDirection.down,
    cluePosition: GridPosition(p.clue ~/ columns, p.clue % columns),
  );
}

class SearchPlacement {
  SearchPlacement._(
    this.id,
    this.word,
    this.direction,
    this.row,
    this.column,
    this.codes,
    int columns,
    int rows,
  ) : cells = List.unmodifiable(
        List.generate(
          codes.length,
          (i) => row * columns + column + i * (direction == 1 ? 1 : columns),
        ),
      ),
      clue = row * columns + column - (direction == 1 ? 1 : columns),
      minRow = row - (direction == 2 ? 1 : 0),
      minColumn = column - (direction == 1 ? 1 : 0),
      maxRow = row + (direction == 2 ? codes.length - 1 : 0),
      maxColumn = column + (direction == 1 ? codes.length - 1 : 0),
      after = direction == 1
          ? (column + codes.length < columns
                ? row * columns + column + codes.length
                : -1)
          : (row + codes.length < rows
                ? (row + codes.length) * columns + column
                : -1);

  final int id, word, direction, row, column, clue, after;
  final int minRow, maxRow, minColumn, maxColumn;
  final List<int> codes, cells;
}

typedef SearchBounds = ({int minRow, int maxRow, int minColumn, int maxColumn});

class SearchState {
  SearchState(this.catalog)
    : letters = List.filled(catalog.rows * catalog.columns, 0),
      directions = List.filled(catalog.rows * catalog.columns, 0),
      clues = List.filled(catalog.rows * catalog.columns, false),
      used = List.filled(catalog.words.length, false);

  final SearchCatalog catalog;
  final List<int> letters, directions;
  final List<bool> clues, used;
  final List<SearchPlacement> placed = [];
  final List<int> _tokens = [];
  final List<({SearchBounds? bounds, int crossings})> _undo = [];
  SearchBounds? bounds;
  int rightCount = 0, crossingCount = 0;
  int get downCount => placed.length - rightCount;
  String get key => _tokens.join(',');

  /// Maximum letter span on one side of a crossing before a grid edge, clue,
  /// or same-axis owner. No word can legally cross those barriers. Matching
  /// perpendicular letters remain allowed so multi-crossings are not pruned.
  int crossingSpace(int cell, int direction, int sign) {
    var row = cell ~/ catalog.columns;
    var column = cell % catalog.columns;
    var space = 0;
    while (true) {
      if (direction == 1) {
        column += sign;
      } else {
        row += sign;
      }
      if (row < 0 ||
          row >= catalog.rows ||
          column < 0 ||
          column >= catalog.columns) {
        break;
      }
      final next = row * catalog.columns + column;
      if (clues[next] || directions[next] & direction != 0) break;
      space++;
    }
    return space;
  }

  SearchBounds expandedBounds(SearchPlacement p) {
    final b = bounds;
    return (
      minRow: b == null ? p.minRow : min(b.minRow, p.minRow),
      maxRow: b == null ? p.maxRow : max(b.maxRow, p.maxRow),
      minColumn: b == null ? p.minColumn : min(b.minColumn, p.minColumn),
      maxColumn: b == null ? p.maxColumn : max(b.maxColumn, p.maxColumn),
    );
  }

  /// Returns new crossing count, or -1 for an illegal placement. Geometry and
  /// clue offset are guaranteed by the catalog, not re-allocated per check.
  int canPlace(SearchPlacement p) {
    if (used[p.word] ||
        clues[p.clue] ||
        letters[p.clue] != 0 ||
        (p.after >= 0 && letters[p.after] != 0)) {
      return -1;
    }
    var crossings = 0;
    final columns = catalog.columns;
    for (var i = 0; i < p.cells.length; i++) {
      final cell = p.cells[i];
      if (clues[cell]) return -1;
      if (letters[cell] != 0) {
        if (letters[cell] != p.codes[i] ||
            directions[cell] & p.direction != 0) {
          return -1;
        }
        crossings++;
      } else if (p.direction == 1) {
        if ((cell >= columns && letters[cell - columns] != 0) ||
            (cell + columns < letters.length && letters[cell + columns] != 0)) {
          return -1;
        }
      } else {
        if ((cell % columns > 0 && letters[cell - 1] != 0) ||
            (cell % columns + 1 < columns && letters[cell + 1] != 0)) {
          return -1;
        }
      }
    }
    return crossings > 0 ? crossings : -1;
  }

  int placementScore(SearchPlacement p, int crossings) {
    final b = expandedBounds(p);
    final columns = b.maxColumn - b.minColumn + 1;
    final rows = b.maxRow - b.minRow + 1;
    final right = rightCount + (p.direction == 1 ? 1 : 0);
    return 400 * crossings -
        2 * rows * columns -
        12 * columns -
        8 * (2 * right - placed.length - 1).abs();
  }

  /// Caller validates all non-anchor placements. Undo is strictly LIFO.
  void place(SearchPlacement p) {
    _undo.add((bounds: bounds, crossings: crossingCount));
    bounds = expandedBounds(p);
    placed.add(p);
    final index = _tokens.indexWhere((token) => token > p.id);
    _tokens.insert(index < 0 ? _tokens.length : index, p.id);
    used[p.word] = true;
    clues[p.clue] = true;
    if (p.direction == 1) rightCount++;
    for (var i = 0; i < p.cells.length; i++) {
      final cell = p.cells[i];
      if (letters[cell] != 0) crossingCount++;
      letters[cell] = p.codes[i];
      directions[cell] |= p.direction;
    }
  }

  void unplace() {
    final p = placed.removeLast();
    final previous = _undo.removeLast();
    bounds = previous.bounds;
    crossingCount = previous.crossings;
    _tokens.remove(p.id);
    used[p.word] = false;
    clues[p.clue] = false;
    if (p.direction == 1) rightCount--;
    for (final cell in p.cells) {
      directions[cell] &= ~p.direction;
      if (directions[cell] == 0) letters[cell] = 0;
    }
  }
}

class SearchWork {
  int candidateChecks = 0, candidatePlacementsGenerated = 0;
  int legalCandidates = 0, duplicateCandidates = 0;
  int boundsRejected = 0, occupiedCrossingRejected = 0;
  int spanRejected = 0;
  int candidatesRejected = 0;
}

class LegalPlacement {
  const LegalPlacement(this.placement, this.crossings, this.order);
  final SearchPlacement placement;
  final int crossings;
  // The first discovery in legacy word/answer/letter/offset order. Restoring
  // this order before seeded tie draws preserves useful search semantics.
  final int order;
}

List<LegalPlacement> enumerateCandidates(
  SearchState state,
  SearchWork work,
  int maxChecks,
) {
  final catalog = state.catalog;
  final found = <LegalPlacement>[];
  final seen = <int>{};
  final longest = catalog.longestWord;
  final orderStride = (state.placed.length + 1) * longest * longest;
  for (var a = 0; a < state.placed.length; a++) {
    final existing = state.placed[a];
    final direction = 3 - existing.direction;
    for (var i = 0; i < existing.cells.length; i++) {
      final cell = existing.cells[i];
      // A cell already owned on both axes cannot accept another answer.
      if (state.directions[cell] == 3) {
        work.occupiedCrossingRejected++;
        continue;
      }
      final before = state.crossingSpace(cell, direction, -1);
      final after = state.crossingSpace(cell, direction, 1);
      for (final occurrence in catalog.byLetter[existing.codes[i] - 65]) {
        if (state.used[occurrence.word]) continue;
        work.candidatePlacementsGenerated++;
        if (occurrence.offset > before ||
            catalog.codes[occurrence.word].length - occurrence.offset - 1 >
                after) {
          work.spanRejected++;
          continue;
        }
        final p = catalog.placement(
          occurrence.word,
          direction,
          cell ~/ catalog.columns - (direction == 2 ? occurrence.offset : 0),
          cell % catalog.columns - (direction == 1 ? occurrence.offset : 0),
        );
        if (p == null) {
          work.boundsRejected++;
          continue;
        }
        if (!seen.add(p.id)) {
          work.duplicateCandidates++;
          continue;
        }
        if (work.candidateChecks >= maxChecks) return found;
        work.candidateChecks++;
        final crossings = state.canPlace(p);
        if (crossings < 0) {
          work.candidatesRejected++;
          continue;
        }
        work.legalCandidates++;
        found.add(
          LegalPlacement(
            p,
            crossings,
            occurrence.word * orderStride +
                a * longest * longest +
                i * longest +
                occurrence.offset,
          ),
        );
      }
    }
  }
  found.sort((a, b) => a.order.compareTo(b.order));
  return found;
}
