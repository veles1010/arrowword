import 'package:arrowword/features/puzzle/data/manual_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PuzzleGame game;
  setUp(() => game = PuzzleGame(manualPuzzle));
  tearDown(() => game.dispose());
  test(
    'selected hint reveals correct letter once and blocks typing/backspace',
    () {
      final p = game.selectedPosition;
      final expected = game.activeAnswer.solution[0];
      expect(game.revealSelectedLetter(), isTrue);
      expect(game.letterAt(p), expected);
      expect(game.hintsUsed, 1);
      game.enterLetter('Z');
      game.backspace();
      expect(game.letterAt(p), expected);
      expect(game.revealSelectedLetter(), isFalse);
      expect(game.hintsUsed, 1);
    },
  );
  test('backspace from empty next cell cannot clear preceding hint', () {
    final p = game.selectedPosition;
    game.revealSelectedLetter();
    game.tapCell(game.activeAnswer.positions[1]);
    game.backspace();
    expect(game.isHint(p), isTrue);
    expect(game.letterAt(p), isNotNull);
  });
  test('Temizle retains hint letters but clears normal entries', () {
    final p = game.selectedPosition;
    game.revealSelectedLetter();
    final other = game.activeAnswer.positions[1];
    game.tapCell(other);
    game.enterLetter('Z');
    game.reset();
    expect(game.letterAt(p), isNotNull);
    expect(game.letterAt(other), isNull);
    expect(game.hintsUsed, 1);
  });
  test('crossing hint is a single shared locked value', () {
    final p = manualPuzzle.crossingPositions.first;
    game.tapCell(p);
    game.revealSelectedLetter();
    for (final answer in manualPuzzle.answersAt(p)) {
      expect(game.letterAt(p), answer.solution[answer.positions.indexOf(p)]);
    }
    game.tapCell(p);
    expect(game.revealSelectedLetter(), isFalse);
    expect(game.hintsUsed, 1);
  });
  test(
    'already-correct entered letter is no-op without lock or hint count',
    () {
      final p = game.selectedPosition;
      game.enterLetter(game.activeAnswer.solution[0]);
      game.tapCell(p);
      expect(game.revealSelectedLetter(), isFalse);
      expect(game.isHint(p), isFalse);
      expect(game.hintsUsed, 0);
    },
  );
  test('non-letter cells never become editable selection or hint targets', () {
    final p = game.selectedPosition;
    game.tapCell(manualPuzzle.answers.first.cluePosition);
    game.tapCell(const GridPosition(-1, -1));
    expect(game.selectedPosition, p);
    game.enterLetter(game.activeAnswer.solution[0]);
    game.tapCell(p);
    expect(game.canRevealSelected, isFalse);
    expect(game.revealSelectedLetter(), isFalse);
    expect(game.revealedCells, isEmpty);
  });
  test('final missing letter hint completes normally and restored hints stay locked', () {
    final p = game.selectedPosition;
    final solution = <GridPosition, String>{
      for (final answer in manualPuzzle.answers)
        for (var i = 0; i < answer.length; i++)
          answer.positions[i]: answer.solution[i],
    }..remove(p);
    game.restoreLetters(solution);
    expect(game.isComplete, isFalse);
    game.revealSelectedLetter();
    expect(game.isComplete, isTrue);
    final restored = PuzzleGame(manualPuzzle)
      ..restoreLetters({}, revealedCells: game.revealedCells);
    addTearDown(restored.dispose);
    restored.enterLetter('Z');
    restored.backspace();
    restored.reset();
    expect(restored.letterAt(p), game.letterAt(p));
    expect(restored.hintsUsed, 1);
  });
}
