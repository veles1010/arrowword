import 'package:arrowword/features/puzzle/data/manual_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_game.dart';
import 'package:arrowword/features/puzzle/presentation/puzzle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final text in ['水', 'あ', '한', 'ё', 'Я', 'ı', 'ſ', 'ß', 'Ａ', 'ABC']) {
    test('domain rejects non-A-Z single-letter input: $text', () {
      final game = PuzzleGame(manualPuzzle);
      final position = game.selectedPosition;
      game.enterLetter(text);
      expect(game.enteredLetters, isEmpty);
      expect(game.selectedPosition, position);
      game.dispose();
    });
  }
  for (final (script, composition, committed) in [
    ('Japanese', 'k', 'か'),
    ('Korean', 'ㅎ', '한'),
    ('Chinese', 'shui', '水'),
    ('Russian', 'ё', 'ё'),
  ]) {
    testWidgets('$script composition/commit cannot delete or corrupt letters', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: PuzzleScreen(puzzle: manualPuzzle)),
      );
      final dynamic state = tester.state(find.byType(PuzzleScreen));
      final PuzzleGame game = state.game;
      final position = game.selectedPosition;
      game.enterLetter('a');
      game.tapCell(position);
      await tester.showKeyboard(find.byType(TextField));
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: composition,
          selection: TextSelection.collapsed(offset: composition.length),
          composing: TextRange(start: 0, end: composition.length),
        ),
      );
      await tester.pump();
      expect(game.letterAt(position), 'A');
      expect(game.selectedPosition, position);
      expect(
        (state.input as TextEditingController).value.composing.isValid,
        isTrue,
      );
      // Cancelling/erasing an unfinished native composition is not a grid delete.
      tester.testTextInput.updateEditingValue(TextEditingValue.empty);
      await tester.pump();
      expect(game.letterAt(position), 'A');
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: composition,
          selection: TextSelection.collapsed(offset: composition.length),
          composing: TextRange(start: 0, end: composition.length),
        ),
      );
      await tester.pump();
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: committed,
          selection: TextSelection.collapsed(offset: committed.length),
        ),
      );
      await tester.pump();
      expect(game.letterAt(position), 'A');
      expect(
        game.enteredLetters.values.every(
          (letter) => RegExp(r'^[A-Z]$').hasMatch(letter),
        ),
        isTrue,
      );
      expect(game.selectedPosition, position);
      await tester.enterText(find.byType(TextField), 'b');
      expect(game.letterAt(position), 'B');
      game.tapCell(position);
      await tester.enterText(find.byType(TextField), '');
      expect(game.letterAt(position), isNull);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'multi-character paste retains established last-Latin-letter rule',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: PuzzleScreen(puzzle: manualPuzzle)),
      );
      final dynamic state = tester.state(find.byType(PuzzleScreen));
      final PuzzleGame game = state.game;
      final position = game.selectedPosition;
      await tester.enterText(find.byType(TextField), 'abc水');
      expect(game.enteredLetters, {position: 'C'});
      expect(tester.takeException(), isNull);
    },
  );
}
