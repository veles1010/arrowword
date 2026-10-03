import '../domain/puzzle.dart';
import 'puzzle_validator.dart';
import 'puzzle_quality.dart';

class PuzzleMetrics {
  PuzzleMetrics(Puzzle puzzle) {
    final bounds = puzzle.displayBounds;
    final validation = const PuzzleValidator().validate(puzzle);
    answerCount = puzzle.answers.length;
    horizontalCount = puzzle.answers
        .where((a) => a.direction == AnswerDirection.right)
        .length;
    verticalCount = answerCount - horizontalCount;
    crossingCount = puzzle.crossingPositions.length;
    displayRowCount = bounds.rowCount;
    displayColumnCount = bounds.columnCount;
    boundingBoxArea = displayRowCount * displayColumnCount;
    meaningfulCellCount = puzzle.meaningfulPositions.toSet().length;
    density = meaningfulCellCount / boundingBoxArea;
    isConnected = puzzle.isAnswerGraphConnected;
    phantomAdjacencyCount = validation.phantomAdjacencyCount;
    horizontalRunCount = validation.horizontalRuns.length;
    verticalRunCount = validation.verticalRuns.length;
    final degrees = <String, int>{};
    var expansion = 0;
    var tails = 0;
    for (final answer in puzzle.answers) {
      final neighbors = answer.positions.expand(puzzle.answersAt).toSet()
        ..remove(answer);
      degrees[answer.id] = neighbors.length;
      if (neighbors.length != 1) continue;
      final rest = Puzzle(
        id: puzzle.id,
        label: puzzle.label,
        rowCount: puzzle.rowCount,
        columnCount: puzzle.columnCount,
        answers: puzzle.answers.where((other) => other != answer).toList(),
      ).displayBounds;
      expansion += boundingBoxArea - rest.rowCount * rest.columnCount;
      final crossing = answer.positions.firstWhere(
        (position) => puzzle.answersAt(position).length > 1,
      );
      final distances = [answer.cluePosition, ...answer.positions].map(
        (position) =>
            (position.row - crossing.row).abs() +
            (position.column - crossing.column).abs(),
      );
      tails += distances.reduce((a, b) => a > b ? a : b);
    }
    answerDegrees = Map.unmodifiable(degrees);
    leafAnswerCount = degrees.values.where((degree) => degree == 1).length;
    maximumAnswerDegree = degrees.values.fold(0, (a, b) => a > b ? a : b);
    averageAnswerDegree = degrees.isEmpty
        ? 0
        : degrees.values.fold(0, (a, b) => a + b) / degrees.length;
    leafExpansionArea = expansion;
    danglingLength = tails;
    quality = PuzzleQuality(
      crossings: crossingCount,
      rows: displayRowCount,
      columns: displayColumnCount,
      meaningfulCells: meaningfulCellCount,
      directionImbalance: (horizontalCount - verticalCount).abs(),
      leafCount: leafAnswerCount,
      leafExpansionArea: expansion,
      danglingLength: tails,
    );
    structuralSignature = puzzleStructuralSignature(puzzle);
  }

  late final int answerCount, horizontalCount, verticalCount, crossingCount;
  late final int displayRowCount, displayColumnCount, boundingBoxArea;
  late final int meaningfulCellCount, phantomAdjacencyCount;
  late final int horizontalRunCount, verticalRunCount;
  late final double density, averageAnswerDegree;
  late final Map<String, int> answerDegrees;
  late final int leafAnswerCount,
      maximumAnswerDegree,
      leafExpansionArea,
      danglingLength;
  late final PuzzleQuality quality;
  late final String structuralSignature;
  int get qualityScore => quality.score;
  late final bool isConnected;

  /// Positive means this board wins. Only strictly valid complete boards should
  /// enter this comparison. Final signature makes ties independent of traversal.
  int compareQuality(PuzzleMetrics other) {
    final comparisons = [
      qualityScore.compareTo(other.qualityScore),
      crossingCount.compareTo(other.crossingCount),
      other.boundingBoxArea.compareTo(boundingBoxArea),
      other.displayColumnCount.compareTo(displayColumnCount),
      other.leafAnswerCount.compareTo(leafAnswerCount),
      other.quality.directionImbalance.compareTo(quality.directionImbalance),
      other.structuralSignature.compareTo(structuralSignature),
    ];
    return comparisons.firstWhere((value) => value != 0, orElse: () => 0);
  }
}

String puzzleStructuralSignature(Puzzle puzzle) {
  final entries =
      puzzle.answers
          .map(
            (answer) =>
                '${answer.id}:${answer.solution}:${answer.direction.index}:'
                '${answer.start.row},${answer.start.column}:'
                '${answer.cluePosition.row},${answer.cluePosition.column}',
          )
          .toList()
        ..sort();
  return entries.join('|');
}
