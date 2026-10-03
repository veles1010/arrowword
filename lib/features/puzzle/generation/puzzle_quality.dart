import 'dart:math' as math;

/// Quality of a strictly valid board, never a substitute for validation.
/// All ranking arithmetic is integer-based, including truncated density points.
class PuzzleQuality {
  const PuzzleQuality({
    required this.crossings,
    required this.rows,
    required this.columns,
    required this.meaningfulCells,
    required this.directionImbalance,
    required this.leafCount,
    required this.leafExpansionArea,
    required this.danglingLength,
  });

  final int crossings, rows, columns, meaningfulCells, directionImbalance;
  final int leafCount, leafExpansionArea, danglingLength;
  int get area => rows * columns;
  int get densityReward => area == 0 ? 0 : (200 * meaningfulCells) ~/ area;
  int get crossingReward => 400 * crossings;
  // Quadratic width cost reflects the cell-size loss on portrait phones.
  int get portraitWidthPenalty => 5 * columns * columns;
  int get areaPenalty => 4 * area;
  // Square through 2:1 portrait boards have no aspect penalty. Landscape and
  // unusually tall/narrow boards do; no visible dimension is a hard limit.
  int get aspectPenalty =>
      (40 * math.max(0, columns - rows) + 20 * math.max(0, rows - 2 * columns))
          .toInt();
  int get leafPenalty => 60 * leafCount;
  int get danglingPenalty => 2 * leafExpansionArea + 8 * danglingLength;

  // One additional crossing is worth 400 points, versus 180 for narrowing
  // 10 columns to 8. Density rewards meaningful clue AND letter cells. Area
  // plus density penalize internal whitespace without counting it twice.
  // Removing a leaf must retain its shared crossing when measuring expansion.
  int get score =>
      crossingReward +
      densityReward -
      portraitWidthPenalty -
      areaPenalty -
      aspectPenalty -
      12 * directionImbalance -
      leafPenalty -
      danglingPenalty;
}
