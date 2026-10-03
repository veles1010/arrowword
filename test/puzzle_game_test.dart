import 'package:arrowword/features/puzzle/data/manual_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('manual puzzle structure', () {
    test('has valid bounds, lengths, clue positions, and crossings', () {
      expect(manualPuzzle.answers, hasLength(10));
      for (final answer in manualPuzzle.answers) {
        expect(answer.solution, matches(RegExp(r'^[A-Z]+$')));
        expect(answer.positions, hasLength(answer.length));
        expect(answer.positions.every(manualPuzzle.contains), isTrue);
        expect(manualPuzzle.contains(answer.cluePosition), isTrue);
        expect(manualPuzzle.answersAt(answer.cluePosition), isEmpty);
        for (final position in answer.positions) {
          final answerIndex = answer.positions.indexOf(position);
          for (final other in manualPuzzle.answersAt(position)) {
            expect(
              answer.solution[answerIndex],
              other.solution[other.positions.indexOf(position)],
            );
          }
        }
      }
    });
    test('forms one connected answer graph with genuine crossings', () {
      expect(manualPuzzle.crossingPositions, hasLength(13));
      expect(manualPuzzle.isAnswerGraphConnected, isTrue);
    });
    test(
      'shared crossing cells expose both answers',
      () => expect(
        manualPuzzle
            .answersAt(const GridPosition(3, 4))
            .map((answer) => answer.id),
        containsAll(['water', 'table']),
      ),
    );

    test('display bounds include every meaningful logical cell', () {
      final bounds = manualPuzzle.displayBounds;
      expect(bounds.minRow, 0);
      expect(bounds.maxRow, 9);
      expect(bounds.minColumn, 1);
      expect(bounds.maxColumn, 7);
      expect(
        manualPuzzle.meaningfulPositions.every(bounds.containsLogical),
        isTrue,
      );
    });

    test('cropped outer rows and columns contain no meaningful cells', () {
      final bounds = manualPuzzle.displayBounds;
      for (var row = 0; row < bounds.minRow; row++) {
        for (var column = 0; column < manualPuzzle.columnCount; column++) {
          expect(manualPuzzle.isMeaningful(GridPosition(row, column)), isFalse);
        }
      }
      for (var row = bounds.maxRow + 1; row < manualPuzzle.rowCount; row++) {
        for (var column = 0; column < manualPuzzle.columnCount; column++) {
          expect(manualPuzzle.isMeaningful(GridPosition(row, column)), isFalse);
        }
      }
      for (var column = 0; column < bounds.minColumn; column++) {
        for (var row = 0; row < manualPuzzle.rowCount; row++) {
          expect(manualPuzzle.isMeaningful(GridPosition(row, column)), isFalse);
        }
      }
      for (
        var column = bounds.maxColumn + 1;
        column < manualPuzzle.columnCount;
        column++
      ) {
        for (var row = 0; row < manualPuzzle.rowCount; row++) {
          expect(manualPuzzle.isMeaningful(GridPosition(row, column)), isFalse);
        }
      }
    });

    test('display coordinate conversion round-trips logical coordinates', () {
      final bounds = manualPuzzle.displayBounds;
      const logical = GridPosition(8, 6);
      final display = bounds.toDisplay(logical);
      expect(display, const GridPosition(8, 5));
      expect(bounds.containsDisplay(display), isTrue);
      expect(bounds.toLogical(display), logical);
    });
  });
  group('game input', () {
    late PuzzleGame game;
    setUp(() => game = PuzzleGame(manualPuzzle));
    test('input updates the selected cell and advances', () {
      game.enterLetter('w');
      expect(game.letterAt(const GridPosition(3, 2)), 'W');
      expect(game.selectedPosition, const GridPosition(3, 3));
    });
    test('backspace clears the previous cell when current is empty', () {
      game.enterLetter('W');
      game.backspace();
      expect(game.selectedPosition, const GridPosition(3, 2));
      expect(game.letterAt(const GridPosition(3, 2)), isNull);
    });
    test('completion is false until every shared cell is correct', () {
      expect(game.isComplete, isFalse);
      for (final answer in manualPuzzle.answers) {
        for (var index = 0; index < answer.length; index++) {
          game.tapCell(answer.positions[index]);
          game.enterLetter(answer.solution[index]);
        }
      }
      expect(game.isComplete, isTrue);
    });
  });
}
