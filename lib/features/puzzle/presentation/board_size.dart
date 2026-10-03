import 'dart:math' as math;

/// Fits the complete visible board into the remaining content area.
class BoardSize {
  BoardSize.fit({
    required double availableWidth,
    required double availableHeight,
    required int rows,
    required int columns,
  }) {
    if (!availableWidth.isFinite ||
        !availableHeight.isFinite ||
        rows <= 0 ||
        columns <= 0) {
      throw ArgumentError(
        'Board constraints must be finite with positive counts.',
      );
    }
    cellSize = math.min(
      math.max(0, availableWidth) / columns,
      math.max(0, availableHeight) / rows,
    );
    width = cellSize * columns;
    height = cellSize * rows;
  }

  late final double cellSize;
  late final double width;
  late final double height;
}
