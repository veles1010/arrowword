import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_generator.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_validator.dart';
import 'package:arrowword/features/puzzle/generation/word_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/catalogue_v1.dart';

const seeds = [1, 2, 3, 42, 100, 20261003];
const generator = PuzzleGenerator();
const config = PuzzleGenerationConfig();
const baselineScores = {
  1: 3610,
  2: 3700,
  3: 3538,
  42: 4028,
  100: 3231,
  20261003: 3695,
};

String signature(Puzzle puzzle) => puzzle.answers
    .map(
      (answer) =>
          '${answer.id}:${answer.solution}:${answer.direction.name}:'
          '${answer.start.row},${answer.start.column}:'
          '${answer.cluePosition.row},${answer.cluePosition.column}',
    )
    .join('|');

void verifyGenerated(Puzzle puzzle) {
  expect(puzzle.rowCount, 10);
  expect(puzzle.columnCount, 10);
  expect(puzzle.answers, hasLength(10));
  expect(puzzle.answers.map((a) => a.solution).toSet(), hasLength(10));
  expect(puzzle.answers.map((a) => a.id).toSet(), hasLength(10));
  final clues = puzzle.answers.map((a) => a.cluePosition).toSet();
  expect(clues, hasLength(10));
  final cells = <GridPosition, List<PuzzleAnswer>>{};
  for (final answer in puzzle.answers) {
    expect(answer.solution, matches(RegExp(r'^[A-Z]+$')));
    expect(answer.positions.length, answer.solution.length);
    expect(answer.positions.toSet().length, answer.length);
    expect(answer.positions.first, answer.start);
    expect(answer.positions.every(puzzle.contains), isTrue);
    expect(puzzle.contains(answer.cluePosition), isTrue);
    final horizontal = answer.direction == AnswerDirection.right;
    expect(
      answer.cluePosition,
      horizontal
          ? GridPosition(answer.start.row, answer.start.column - 1)
          : GridPosition(answer.start.row - 1, answer.start.column),
    );
    for (final position in answer.positions) {
      expect(clues.contains(position), isFalse);
      cells.putIfAbsent(position, () => []).add(answer);
    }
  }
  var crossings = 0;
  for (final entry in cells.entries) {
    expect(entry.value.length, lessThanOrEqualTo(2));
    if (entry.value.length == 2) {
      crossings++;
      final a = entry.value.first;
      final b = entry.value.last;
      expect(a.direction, isNot(b.direction));
      expect(
        a.solution[a.positions.indexOf(entry.key)],
        b.solution[b.positions.indexOf(entry.key)],
      );
    }
  }
  expect(crossings, greaterThanOrEqualTo(9));
  expect(puzzle.crossingPositions.length, crossings);
  for (final direction in AnswerDirection.values) {
    expect(
      puzzle.answers.where((a) => a.direction == direction).length,
      greaterThanOrEqualTo(4),
    );
  }
  final reached = <PuzzleAnswer>{puzzle.answers.first};
  final queue = [puzzle.answers.first];
  while (queue.isNotEmpty) {
    for (final position in queue.removeLast().positions) {
      for (final neighbor in cells[position]!) {
        if (reached.add(neighbor)) queue.add(neighbor);
      }
    }
  }
  expect(reached, hasLength(10));
  expect(puzzle.isAnswerGraphConnected, isTrue);
  expect(
    [...cells.keys, ...clues].every(puzzle.displayBounds.containsLogical),
    isTrue,
  );

  // Independently scan every row/column, rather than trusting validator flags.
  for (final direction in AnswerDirection.values) {
    final horizontal = direction == AnswerDirection.right;
    final lineCount = horizontal ? puzzle.rowCount : puzzle.columnCount;
    final lineLength = horizontal ? puzzle.columnCount : puzzle.rowCount;
    for (var line = 0; line < lineCount; line++) {
      final run = <GridPosition>[];
      for (var offset = 0; offset <= lineLength; offset++) {
        final position = horizontal
            ? GridPosition(line, offset)
            : GridPosition(offset, line);
        if (cells.containsKey(position)) {
          if (run.isNotEmpty) {
            expect(
              cells[run.last]!.any(
                (answer) =>
                    answer.direction == direction &&
                    cells[position]!.contains(answer),
              ),
              isTrue,
            );
          }
          run.add(position);
        } else {
          if (run.length >= 2) {
            expect(
              puzzle.answers.where(
                (answer) =>
                    answer.direction == direction &&
                    answer.start == run.first &&
                    answer.length == run.length,
              ),
              hasLength(1),
            );
          }
          run.clear();
        }
      }
    }
  }
  for (final answer in puzzle.answers) {
    final end = answer.positions.last;
    final after = answer.direction == AnswerDirection.right
        ? GridPosition(end.row, end.column + 1)
        : GridPosition(end.row + 1, end.column);
    expect(cells.containsKey(after), isFalse);
  }
  final validation = const PuzzleValidator().validate(
    puzzle,
    expectedAnswerCount: 10,
  );
  expect(validation.errors, isEmpty);
  expect(validation.phantomAdjacencyCount, 0);
  expect(validation.unexplainedRunCount, 0);
  expect(
    validation.horizontalRuns.length,
    puzzle.answers.where((a) => a.direction == AnswerDirection.right).length,
  );
  expect(
    validation.verticalRuns.length,
    puzzle.answers.where((a) => a.direction == AnswerDirection.down).length,
  );
}

void main() {
  final results = <int, PuzzleGenerationResult>{};
  setUpAll(() {
    for (final seed in seeds) {
      results[seed] = generator.generate(wordBank: legacyWordBank, seed: seed);
    }
  });

  test('v1 performance fixture retains 60 unique entries of length 4–7', () {
    expect(legacyWordBank, hasLength(60));
    expect(legacyWordBank.map((word) => word.solution).toSet(), hasLength(60));
    for (final word in legacyWordBank) {
      expect(word.solution, matches(RegExp(r'^[A-Z]{4,7}$')));
      expect(word.turkishClue.trim(), isNotEmpty);
    }
  });

  for (final seed in seeds) {
    test('seed $seed satisfies all strict placement and visual-run rules', () {
      final result = results[seed]!;
      expect(result.isSuccess, isTrue, reason: result.failureReason);
      verifyGenerated(result.puzzle!);
      expect(result.metrics!.phantomAdjacencyCount, 0);
      if (seed == 20261003) {
        expect(result.metrics!.crossingCount, greaterThanOrEqualTo(11));
        expect(result.metrics!.leafAnswerCount, lessThanOrEqualTo(1));
      }
      expect(
        result.bestCompleteScore,
        greaterThanOrEqualTo(baselineScores[seed]!),
      );
      // A broad deterministic work-count guard, not a machine-speed assertion.
      expect(result.candidateChecks, lessThan(1400000));
      expect(
        result.candidateChecks,
        result.legalCandidates + result.candidatesRejected,
      );
      expect(
        result.searchNodes,
        result.visitedStateHits + result.visitedStateMisses,
      );
      expect(result.completeSolutionsFound, greaterThan(1));
      expect(
        result.bestCompleteScore,
        greaterThanOrEqualTo(result.firstCompleteScore!),
      );
      expect(result.anchorsTried, greaterThan(0));
      expect(result.searchNodes, lessThanOrEqualTo(config.maxSearchNodes));
      expect(result.backtracks, lessThanOrEqualTo(config.maxBacktracks));
      expect(
        result.candidateChecks,
        lessThanOrEqualTo(config.maxCandidateChecks),
      );
    });
  }

  test(
    'identical seed, bank and config reproduce exact structure and search',
    () {
      final first = results[20261003]!;
      final second = generator.generate(
        wordBank: legacyWordBank,
        seed: 20261003,
      );
      expect(signature(second.puzzle!), signature(first.puzzle!));
      expect(second.searchNodes, first.searchNodes);
      expect(second.candidateChecks, first.candidateChecks);
      expect(second.metrics!.qualityScore, first.metrics!.qualityScore);
      expect(second.completeSolutionsFound, first.completeSolutionsFound);
      expect(second.firstCompleteScore, first.firstCompleteScore);
      expect(second.anchorsTried, first.anchorsTried);
      expect(
        second.candidatePlacementsGenerated,
        first.candidatePlacementsGenerated,
      );
      expect(second.legalCandidates, first.legalCandidates);
      expect(second.visitedStateHits, first.visitedStateHits);
    },
  );

  test('predetermined different seeds produce different structures', () {
    expect(
      results.values.map((r) => signature(r.puzzle!)).toSet().length,
      greaterThan(1),
    );
  });

  test('best complete board survives budget exhaustion and beats first complete', () {
    // A documented robustness seed exercises actual production search ordering.
    // Compare outcomes, not an exact score, word set or traversal count.
    final result = results[42]!;
    expect(result.isSuccess, isTrue);
    expect(result.completeSolutionsFound, greaterThan(1));
    expect(result.bestCompleteScore, greaterThan(result.firstCompleteScore!));
    expect(
      result.candidateChecks == config.maxCandidateChecks ||
          result.searchNodes == config.maxSearchNodes ||
          result.backtracks == config.maxBacktracks,
      isTrue,
    );
    expect(result.puzzle!.answers, hasLength(10));
    expect(
      const PuzzleValidator()
          .validate(result.puzzle!, expectedAnswerCount: 10)
          .isValid,
      isTrue,
    );
    expect(result.bestCompleteScore, result.metrics!.qualityScore);
  });

  test('word normalization and bank order do not alter generation', () {
    final reordered = legacyWordBank.reversed
        .map(
          (word) =>
              WordEntry(' ${word.solution.toLowerCase()} ', word.turkishClue),
        )
        .toList();
    final result = generator.generate(wordBank: reordered, seed: 2);
    expect(signature(result.puzzle!), signature(results[2]!.puzzle!));
  });

  test(
    'tiny bank returns explicit failure with no partial puzzle or metrics',
    () {
      final result = generator.generate(
        wordBank: const [WordEntry('APPLE', 'Elma')],
        seed: 1,
      );
      expect(result.isSuccess, isFalse);
      expect(result.failureReason, contains('Not enough'));
      expect(result.puzzle, isNull);
      expect(result.metrics, isNull);
    },
  );

  test('unconnectable bank exhausts finite anchor choices cleanly', () {
    final result = generator.generate(
      wordBank: const [WordEntry('CAT', 'Kedi'), WordEntry('BOW', 'Yay')],
      seed: 42,
      config: const PuzzleGenerationConfig(
        targetAnswerCount: 2,
        minAnswersPerDirection: 1,
        minCrossings: 1,
      ),
    );
    expect(result.puzzle, isNull);
    expect(result.failureReason, isNotEmpty);
    expect(result.searchNodes, greaterThan(0));
    expect(result.searchNodes, lessThan(10));
  });

  test('hard node, backtrack and candidate budgets always terminate', () {
    for (final limited in [
      const PuzzleGenerationConfig(maxSearchNodes: 1),
      const PuzzleGenerationConfig(maxCandidateChecks: 1),
      const PuzzleGenerationConfig(maxBacktracks: 1),
    ]) {
      final result = generator.generate(
        wordBank: legacyWordBank,
        seed: 20261003,
        config: limited,
      );
      expect(result.isSuccess, isFalse);
      expect(result.failureReason, contains('budget'));
      expect(result.searchNodes, lessThanOrEqualTo(limited.maxSearchNodes));
      expect(result.backtracks, lessThanOrEqualTo(limited.maxBacktracks));
      expect(
        result.candidateChecks,
        lessThanOrEqualTo(limited.maxCandidateChecks),
      );
    }
  });

  test('invalid and duplicate normalized entries return failure', () {
    for (final bank in [
      const [WordEntry('ICE CREAM', 'Dondurma')],
      const [WordEntry('APPLE', '')],
      const [WordEntry('APPLE', 'Elma'), WordEntry(' apple ', 'Elma')],
    ]) {
      expect(generator.generate(wordBank: bank, seed: 1).isSuccess, isFalse);
    }
    expect(
      generator
          .generate(
            wordBank: legacyWordBank,
            seed: 1,
            config: const PuzzleGenerationConfig(rows: 0),
          )
          .isSuccess,
      isFalse,
    );
  });
}
