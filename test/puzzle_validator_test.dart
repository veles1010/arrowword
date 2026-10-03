import 'package:arrowword/features/puzzle/data/manual_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_validator.dart';
import 'package:flutter_test/flutter_test.dart';

PuzzleAnswer answer(
  String word,
  int row,
  int column,
  AnswerDirection direction, {
  GridPosition? clue,
}) => PuzzleAnswer(
  id: word,
  solution: word,
  turkishClue: 'İpucu',
  start: GridPosition(row, column),
  direction: direction,
  cluePosition:
      clue ??
      (direction == AnswerDirection.right
          ? GridPosition(row, column - 1)
          : GridPosition(row - 1, column)),
);
Puzzle board(List<PuzzleAnswer> answers) => Puzzle(
  id: 'test',
  label: 'Test',
  rowCount: 10,
  columnCount: 10,
  answers: answers,
);

void main() {
  const validator = PuzzleValidator();
  const right = AnswerDirection.right;
  const down = AnswerDirection.down;

  test('rejects RAINCB: unrelated C and B falsely extend vertical RAIN', () {
    final puzzle = board([
      answer('RAIN', 1, 1, down),
      answer('CAT', 5, 1, right),
      answer('BOAT', 6, 1, right),
    ]);
    final result = validator.validate(puzzle);
    expect(result.isValid, isFalse);
    expect(result.phantomAdjacencyCount, greaterThanOrEqualTo(2));
    expect(
      result.verticalRuns.any(
        (run) =>
            run.positions.first == const GridPosition(1, 1) &&
            run.positions.length == 6,
      ),
      isTrue,
    );
    expect(result.hasValidRuns, isFalse);
    expect(result.errors, contains('False answer extension: RAIN.'));
  });

  test('rejects horizontal RAINCB just as strictly', () {
    final result = validator.validate(
      board([
        answer('RAIN', 1, 1, right),
        answer('CAT', 1, 5, down),
        answer('BOAT', 1, 6, down),
      ]),
    );
    expect(result.isValid, isFalse);
    expect(result.phantomAdjacencyCount, greaterThanOrEqualTo(2));
    expect(
      result.horizontalRuns.any(
        (run) =>
            run.positions.first == const GridPosition(1, 1) &&
            run.positions.length == 6,
      ),
      isTrue,
    );
    expect(result.errors, contains('False answer extension: RAIN.'));
  });

  test('valid crossing and exact maximal runs pass', () {
    final result = validator.validate(
      board([answer('TREE', 1, 1, right), answer('RAIN', 1, 2, down)]),
    );
    expect(result.errors, isEmpty);
    expect(result.phantomAdjacencyCount, 0);
    expect(result.horizontalRuns, hasLength(1));
    expect(result.verticalRuns, hasLength(1));
  });

  test(
    'historical manual fixture stays connected but fails strict visual rules',
    () {
      expect(manualPuzzle.isAnswerGraphConnected, isTrue);
      final result = validator.validate(manualPuzzle);
      expect(result.hasValidLetterAdjacency, isFalse);
      expect(result.hasValidRuns, isFalse);
      expect(result.errors, contains('False answer extension: rain.'));
    },
  );

  test('rejects same-axis overlap even with matching letters', () {
    final result = validator.validate(
      board([answer('TREE', 1, 1, right), answer('TREE', 1, 1, right)]),
    );
    expect(result.errors, contains('Same-direction overlap.'));
    expect(result.errors, contains('Duplicate clue position.'));
    expect(result.errors, contains('Duplicate solution.'));
  });

  test('rejects mismatched crossing letters', () {
    final result = validator.validate(
      board([answer('TREE', 1, 1, right), answer('FISH', 1, 2, down)]),
    );
    expect(result.errors, contains('Conflicting crossing.'));
  });

  test('rejects clue collision and wrong clue offset independently', () {
    final result = validator.validate(
      board([answer('TREE', 1, 1, right), answer('RAIN', 2, 2, down)]),
    );
    expect(result.errors, contains('Clue overlaps letter.'));
    final offset = validator.validate(
      board([answer('TREE', 1, 1, right, clue: const GridPosition(0, 0))]),
    );
    expect(offset.errors, contains('Non-adjacent clue: TREE.'));
  });

  test('rejects out-of-grid letters and clues', () {
    final result = validator.validate(
      board([answer('RAIN', 8, 0, down), answer('TREE', 2, 0, right)]),
    );
    expect(result.errors, contains('Letter outside grid: RAIN.'));
    expect(result.errors, contains('Clue outside grid: TREE.'));
  });

  test('rejects perpendicular side touching even away from word endpoints', () {
    final result = validator.validate(
      board([answer('TREE', 2, 1, right), answer('RAIN', 3, 1, right)]),
    );
    expect(result.phantomAdjacencyCount, 4);
    expect(result.unexplainedRunCount, 4);
  });
}
