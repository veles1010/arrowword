import 'package:arrowword/features/puzzle/data/manual_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PuzzleGame game;
  setUp(() => game = PuzzleGame(manualPuzzle));
  tearDown(() => game.dispose());

  test('empty and incomplete correct entries do not count as wrong checks', () {
    game.check();
    game.enterLetter(manualPuzzle.answers.first.solution[0]);
    game.check();
    expect(game.wrongChecks, 0);
  });
  test('each explicit check counts once, not once per wrong letter', () {
    game.enterLetter('Z');
    game.enterLetter('Z');
    expect(game.wrongChecks, 0);
    game.check();
    expect(game.wrongChecks, 1);
    game.check();
    expect(game.wrongChecks, 2);
    expect(game.isIncorrect(manualPuzzle.answers.first.start), isTrue);
  });
  test('correct completed puzzle never incurs wrong checks', () {
    game.restoreLetters({
      for (final a in manualPuzzle.answers)
        for (var i = 0; i < a.length; i++) a.positions[i]: a.solution[i],
    });
    expect(game.isComplete, isTrue);
    game.check();
    game.check();
    expect(game.wrongChecks, 0);
  });
  test('navigation, removal and hints do not count as checks', () {
    game.enterLetter('Z');
    game.backspace();
    game.tapClue(manualPuzzle.answers.last);
    game.revealSelectedLetter();
    game.check();
    expect(game.hintsUsed, 1);
    expect(game.wrongChecks, 0);
  });
  test('restored checks and reset remain part of the same attempt', () {
    final restored = PuzzleGame(manualPuzzle, wrongChecks: 3);
    addTearDown(restored.dispose);
    restored.enterLetter('Z');
    restored.check();
    restored.reset();
    restored.check();
    expect(restored.wrongChecks, 4);
  });
}
