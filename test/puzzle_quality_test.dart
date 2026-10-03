import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_metrics.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_quality.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_validator.dart';
import 'package:flutter_test/flutter_test.dart';

PuzzleQuality sample({
  int crossings = 10,
  int rows = 9,
  int columns = 8,
  int cells = 42,
  int leaves = 2,
  int expansion = 8,
  int tails = 6,
  int imbalance = 0,
}) => PuzzleQuality(
  crossings: crossings,
  rows: rows,
  columns: columns,
  meaningfulCells: cells,
  directionImbalance: imbalance,
  leafCount: leaves,
  leafExpansionArea: expansion,
  danglingLength: tails,
);

Puzzle cross({int offset = 0, bool reverse = false}) {
  final answers = [
    PuzzleAnswer(
      id: 'tree',
      solution: 'TREE',
      turkishClue: 'Ağaç',
      direction: AnswerDirection.right,
      start: GridPosition(1 + offset, 1 + offset),
      cluePosition: GridPosition(1 + offset, offset),
    ),
    PuzzleAnswer(
      id: 'rain',
      solution: 'RAIN',
      turkishClue: 'Yağmur',
      direction: AnswerDirection.down,
      start: GridPosition(1 + offset, 2 + offset),
      cluePosition: GridPosition(offset, 2 + offset),
    ),
  ];
  return Puzzle(
    id: 'test',
    label: 'Test',
    rowCount: 10,
    columnCount: 10,
    answers: reverse ? answers.reversed.toList() : answers,
  );
}

void main() {
  test(
    'additional genuine crossing adds 400 with all other metrics held fixed',
    () {
      expect(sample(crossings: 11).score - sample().score, 400);
    },
  );
  test('smaller area improves compactness component and overall score', () {
    expect(sample(rows: 8).areaPenalty, lessThan(sample().areaPenalty));
    expect(sample(rows: 8).score, greaterThan(sample().score));
  });
  test('narrower boards improve the portrait-width component', () {
    expect(
      sample(columns: 7).portraitWidthPenalty,
      lessThan(sample().portraitWidthPenalty),
    );
  });
  test('portrait orientation wins over equal-area landscape orientation', () {
    expect(
      sample(rows: 10, columns: 8).score,
      greaterThan(sample(rows: 8, columns: 10).score),
    );
    expect(sample(rows: 10, columns: 8).aspectPenalty, 0);
    expect(sample(rows: 8, columns: 10).aspectPenalty, greaterThan(0));
    expect(sample(rows: 10, columns: 4).aspectPenalty, greaterThan(0));
  });
  test('density counts all meaningful cells and improves score', () {
    expect(sample(cells: 45).score, greaterThan(sample().score));
  });
  test('fewer leaf nodes improves graph-integration component by 60 each', () {
    expect(sample(leaves: 1).score - sample().score, 60);
  });
  test('longer tails and leaf-expanded empty area both carry a penalty', () {
    expect(sample(expansion: 9).score, sample().score - 2);
    expect(sample(tails: 7).score, sample().score - 8);
  });
  test('direction balance is rewarded without becoming a hard rule', () {
    expect(sample(imbalance: 2).score, sample().score - 24);
  });
  test(
    'graph degrees and shared-cell-aware leaf removal are measured correctly',
    () {
      final puzzle = cross();
      final metrics = PuzzleMetrics(puzzle);
      expect(const PuzzleValidator().validate(puzzle).isValid, isTrue);
      expect(metrics.answerDegrees, {'tree': 1, 'rain': 1});
      expect(metrics.leafAnswerCount, 2);
      expect(metrics.averageAnswerDegree, 1);
      expect(metrics.maximumAnswerDegree, 1);
      // 5x5 full bounds; each remaining four-letter word plus clue spans 5x1.
      expect(metrics.leafExpansionArea, 40);
      expect(metrics.danglingLength, 5);
      expect(metrics.meaningfulCellCount, 9);
      expect(metrics.density, 9 / 25);
    },
  );
  test(
    'complete-board ties are canonical and independent of answer ordering',
    () {
      final original = PuzzleMetrics(cross());
      final reordered = PuzzleMetrics(cross(reverse: true));
      final shifted = PuzzleMetrics(cross(offset: 1));
      expect(original.compareQuality(reordered), 0);
      expect(original.structuralSignature, reordered.structuralSignature);
      expect(original.qualityScore, shifted.qualityScore);
      expect(original.compareQuality(shifted), greaterThan(0));
      expect(shifted.compareQuality(original), lessThan(0));
    },
  );
}
