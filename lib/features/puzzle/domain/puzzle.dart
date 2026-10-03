import 'dart:collection';

enum AnswerDirection { right, down }

class GridPosition {
  const GridPosition(this.row, this.column);
  final int row, column;
  @override
  bool operator ==(Object other) =>
      other is GridPosition && row == other.row && column == other.column;
  @override
  int get hashCode => Object.hash(row, column);
}

class PuzzleDisplayBounds {
  const PuzzleDisplayBounds({
    required this.minRow,
    required this.maxRow,
    required this.minColumn,
    required this.maxColumn,
  });

  final int minRow, maxRow, minColumn, maxColumn;
  int get rowCount => maxRow - minRow + 1;
  int get columnCount => maxColumn - minColumn + 1;

  bool containsLogical(GridPosition position) =>
      position.row >= minRow &&
      position.row <= maxRow &&
      position.column >= minColumn &&
      position.column <= maxColumn;

  bool containsDisplay(GridPosition position) =>
      position.row >= 0 &&
      position.row < rowCount &&
      position.column >= 0 &&
      position.column < columnCount;

  GridPosition toDisplay(GridPosition logicalPosition) => GridPosition(
    logicalPosition.row - minRow,
    logicalPosition.column - minColumn,
  );

  GridPosition toLogical(GridPosition displayPosition) => GridPosition(
    displayPosition.row + minRow,
    displayPosition.column + minColumn,
  );
}

class PuzzleAnswer {
  const PuzzleAnswer({
    required this.id,
    required this.solution,
    required this.turkishClue,
    required this.start,
    required this.direction,
    required this.cluePosition,
  });
  final String id, solution, turkishClue;
  final GridPosition start, cluePosition;
  final AnswerDirection direction;
  int get length => solution.length;
  List<GridPosition> get positions => List.generate(
    length,
    (i) => direction == AnswerDirection.right
        ? GridPosition(start.row, start.column + i)
        : GridPosition(start.row + i, start.column),
  );
}

enum PuzzleCellType { clue, letter, blocked }

class PuzzleCell {
  const PuzzleCell({required this.type, this.clues = const []});
  final PuzzleCellType type;
  final List<PuzzleAnswer> clues;
}

class Puzzle {
  Puzzle({
    required this.id,
    required this.label,
    required this.rowCount,
    required this.columnCount,
    required List<PuzzleAnswer> answers,
  }) : answers = List.unmodifiable(answers) {
    for (final a in this.answers) {
      _cluesAt.putIfAbsent(a.cluePosition, () => []).add(a);
      for (final p in a.positions) {
        _answersAt.putIfAbsent(p, () => []).add(a);
      }
    }
  }
  final String id, label;
  final int rowCount, columnCount;
  final List<PuzzleAnswer> answers;
  final Map<GridPosition, List<PuzzleAnswer>> _answersAt = {}, _cluesAt = {};
  bool contains(GridPosition p) =>
      p.row >= 0 && p.row < rowCount && p.column >= 0 && p.column < columnCount;
  UnmodifiableListView<PuzzleAnswer> answersAt(GridPosition p) =>
      UnmodifiableListView(_answersAt[p] ?? const []);
  Iterable<GridPosition> get meaningfulPositions => [
    ..._cluesAt.keys,
    ..._answersAt.keys,
  ];

  bool isMeaningful(GridPosition position) =>
      _cluesAt.containsKey(position) || _answersAt.containsKey(position);

  PuzzleDisplayBounds get displayBounds {
    final positions = meaningfulPositions.toList();
    if (positions.isEmpty) {
      return const PuzzleDisplayBounds(
        minRow: 0,
        maxRow: 0,
        minColumn: 0,
        maxColumn: 0,
      );
    }
    return PuzzleDisplayBounds(
      minRow: positions.map((position) => position.row).reduce(_min),
      maxRow: positions.map((position) => position.row).reduce(_max),
      minColumn: positions.map((position) => position.column).reduce(_min),
      maxColumn: positions.map((position) => position.column).reduce(_max),
    );
  }

  Iterable<GridPosition> get crossingPositions => _answersAt.entries
      .where((entry) => entry.value.length > 1)
      .map((entry) => entry.key);

  bool get isAnswerGraphConnected {
    if (answers.isEmpty) return true;
    final visited = <PuzzleAnswer>{answers.first};
    final pending = <PuzzleAnswer>[answers.first];
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      for (final position in current.positions) {
        for (final neighbor in answersAt(position)) {
          if (visited.add(neighbor)) pending.add(neighbor);
        }
      }
    }
    return visited.length == answers.length;
  }

  PuzzleCell cellAt(GridPosition p) {
    final c = _cluesAt[p];
    if (c != null) return PuzzleCell(type: PuzzleCellType.clue, clues: c);
    return _answersAt.containsKey(p)
        ? const PuzzleCell(type: PuzzleCellType.letter)
        : const PuzzleCell(type: PuzzleCellType.blocked);
  }
}

int _min(int left, int right) => left < right ? left : right;
int _max(int left, int right) => left > right ? left : right;
