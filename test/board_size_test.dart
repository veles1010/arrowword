import 'package:arrowword/features/puzzle/presentation/board_size.dart';
import 'package:flutter_test/flutter_test.dart';

BoardSize fit(double width, double height) => BoardSize.fit(
  availableWidth: width,
  availableHeight: height,
  rows: 10,
  columns: 7,
);

void main() {
  test(
    'square board cells fit both constraints across phone content sizes',
    () {
      for (final width in [280.0, 300.0, 355.0, 392.0]) {
        for (final height in [180.0, 252.0, 414.0, 460.0, 664.0]) {
          final board = fit(width, height);
          expect(board.cellSize, lessThanOrEqualTo(width / 7));
          expect(board.cellSize, lessThanOrEqualTo(height / 10));
          expect(board.width, lessThanOrEqualTo(width + 1e-9));
          expect(board.height, lessThanOrEqualTo(height + 1e-9));
          expect(board.width / 7, closeTo(board.height / 10, 1e-9));
        }
      }
    },
  );

  test('uses full width when width limits the board', () {
    final board = fit(300, 460);
    expect(board.width, closeTo(300, 1e-9));
    expect(board.height, closeTo(3000 / 7, 1e-9));
  });

  test('uses full height when height limits the board', () {
    final board = fit(392, 414);
    expect(board.cellSize, 41.4);
    expect(board.height, 414);
  });

  test('reducing either constraint cannot increase cell size', () {
    for (final width in [300.0, 392.0]) {
      for (final height in [252.0, 460.0, 664.0]) {
        final original = fit(width, height).cellSize;
        expect(fit(width - 40, height).cellSize, lessThanOrEqualTo(original));
        expect(fit(width, height - 100).cellSize, lessThanOrEqualTo(original));
      }
    }
  });

  test('exhausted space gives zero rather than negative dimensions', () {
    expect(fit(-10, 20).cellSize, 0);
    expect(fit(300, 0).height, 0);
    expect(fit(300, -1).width, 0);
  });
}
