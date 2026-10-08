import 'package:arrowword/app/app_settings.dart';
import 'package:arrowword/app/arrowword_theme.dart';
import 'package:arrowword/audio/game_audio.dart';
import 'package:arrowword/features/puzzle/data/manual_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_game.dart';
import 'package:arrowword/features/puzzle/presentation/puzzle_keyboard.dart';
import 'package:arrowword/features/puzzle/presentation/puzzle_screen.dart';
import 'package:arrowword/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

class _Audio extends AudioBackend {
  final sounds = <GameSound>[];
  @override
  Future<void> play(GameSound sound) async => sounds.add(sound);
  @override
  Future<void> resumeMusic() async {}
  @override
  Future<void> pauseMusic() async {}
  @override
  Future<void> stopEffects() async {}
  @override
  Future<void> dispose() async {}
}

void main() {
  final word = manualPuzzle.answers.first;
  final hint = word.positions[1];
  PuzzleGame gameOf(WidgetTester tester) {
    final dynamic state = tester.state(find.byType(PuzzleScreen));
    return state.game as PuzzleGame;
  }

  Future<void> letter(WidgetTester tester, String value) async {
    await tester.tap(find.byKey(ValueKey('keyboard-$value')));
    await tester.pump();
  }

  Future<void> open(WidgetTester tester, {GameAudio? audio}) async {
    final screen = PuzzleScreen(
      puzzle: manualPuzzle,
      initialRevealedCells: {hint},
    );
    await tester.pumpWidget(
      MaterialApp(
        home: audio == null
            ? screen
            : GameAudioScope(audio: audio, child: screen),
      ),
    );
    await tester.pump();
  }

  test(
    'matching revealed letter passes through without changing attempt data',
    () {
      final game = PuzzleGame(manualPuzzle)
        ..restoreLetters({}, revealedCells: {hint});
      addTearDown(game.dispose);
      game.enterLetter('W');
      expect(game.selectedPosition, hint);
      expect(game.enterLetter('a'), LetterInputResult.hintPassed);
      expect(game.selectedPosition, word.positions[2]);
      expect(game.letterAt(hint), 'A');
      expect(game.hintsUsed, 1);
      expect(game.wrongChecks, 0);
    },
  );
  test('mismatched hint and non-Latin input do not mutate or advance', () {
    final game = PuzzleGame(manualPuzzle)
      ..restoreLetters({}, revealedCells: {hint});
    addTearDown(game.dispose);
    game.tapCell(hint);
    final before = game.enteredLetters;
    expect(game.enterLetter('Z'), LetterInputResult.hintRejected);
    expect(game.enterLetter('А'), LetterInputResult.ignored);
    expect(game.enteredLetters, before);
    expect(game.selectedPosition, hint);
    expect(game.wrongChecks, 0);
    game.check();
    expect(game.wrongChecks, 0);
  });
  test('backspace crosses hints without deleting revealed letters', () {
    final game = PuzzleGame(manualPuzzle)
      ..restoreLetters({}, revealedCells: {hint});
    addTearDown(game.dispose);
    game.enterLetter('W');
    game.backspace();
    expect(game.selectedPosition, word.positions.first);
    expect(game.letterAt(word.positions.first), isNull);
    expect(game.letterAt(hint), 'A');
    game.tapCell(word.positions[2]);
    game.backspace();
    expect(game.selectedPosition, word.positions.first);
    expect(game.letterAt(hint), 'A');
  });
  test('pass-through skips adjacent hints and stays safe at word end', () {
    final game = PuzzleGame(manualPuzzle)
      ..restoreLetters(
        {},
        revealedCells: {hint, word.positions[2], word.positions.last},
      );
    addTearDown(game.dispose);
    game.tapCell(hint);
    game.enterLetter('A');
    expect(game.selectedPosition, word.positions[3]);
    game.tapCell(word.positions.last);
    expect(game.enterLetter('R'), LetterInputResult.hintPassed);
    expect(game.selectedPosition, word.positions.last);
    expect(game.hintsUsed, 3);
  });

  testWidgets('27 keys, QWERTY order, touch input and no system keyboard', (
    tester,
  ) async {
    await open(tester);
    expect(find.byType(PuzzleKeyboard), findsOneWidget);
    for (final code in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')) {
      expect(find.byKey(ValueKey('keyboard-$code')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('keyboard-backspace')), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).keyboardType,
      TextInputType.none,
    );
    expect(
      tester.testTextInput.setClientArgs!['inputType']['name'],
      'TextInputType.none',
    );
    final letters = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(PuzzleKeyboard),
            matching: find.byType(Text),
          ),
        )
        .map((t) => t.data)
        .join();
    expect(letters, 'QWERTYUIOPASDFGHJKLZXCVBNM');
    await letter(tester, 'W');
    expect(gameOf(tester).letterAt(word.positions.first), 'W');
  });
  testWidgets('whole word types across a revealed cell with no reselection', (
    tester,
  ) async {
    await open(tester);
    for (final value in word.solution.split('')) {
      await letter(tester, value);
    }
    final game = gameOf(tester);
    expect(word.positions.map(game.letterAt).join(), word.solution);
    expect(game.hintsUsed, 1);
    expect(game.wrongChecks, 0);
  });
  testWidgets(
    'hint rejection flashes only; no dialog, advance or wrong check',
    (tester) async {
      await open(tester);
      await letter(tester, 'W');
      final game = gameOf(tester);
      final cell = find.byKey(ValueKey('cell-${hint.row}-${hint.column}'));
      Color? fill() =>
          (tester
                      .widget<Container>(
                        find.descendant(
                          of: cell,
                          matching: find.byType(Container),
                        ),
                      )
                      .decoration
                  as BoxDecoration)
              .color;
      final original = fill();
      final before = game.enteredLetters;
      await letter(tester, 'Z');
      expect(fill(), Theme.of(tester.element(cell)).colorScheme.errorContainer);
      expect(game.enteredLetters, before);
      expect(game.selectedPosition, hint);
      expect(game.wrongChecks, 0);
      expect(find.byType(AlertDialog), findsNothing);
      await tester.pump(const Duration(milliseconds: 230));
      expect(fill(), original);
      await letter(tester, 'A');
      expect(game.selectedPosition, word.positions[2]);
    },
  );
  testWidgets('on-screen Backspace preserves hints and clears editable cells', (
    tester,
  ) async {
    await open(tester);
    await letter(tester, 'W');
    await tester.tap(find.byKey(const ValueKey('keyboard-backspace')));
    await tester.pump();
    final game = gameOf(tester);
    expect(game.selectedPosition, word.positions.first);
    expect(game.letterAt(word.positions.first), isNull);
    expect(game.letterAt(hint), 'A');
  });
  testWidgets('hardware A-Z and Backspace use the same protected input path', (
    tester,
  ) async {
    await open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyW, character: 'w');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA, character: 'a');
    await tester.pump();
    expect(gameOf(tester).selectedPosition, word.positions[2]);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(gameOf(tester).letterAt(hint), 'A');
    expect(gameOf(tester).letterAt(word.positions.first), isNull);
  });
  testWidgets(
    'only changed editable letters sound; hint pass/rejection are silent',
    (tester) async {
      final backend = _Audio();
      final audio = GameAudio(AppSettings(MemorySettingsStore()), backend)
        ..setActive(true);
      await open(tester, audio: audio);
      await letter(tester, 'W');
      await letter(tester, 'Z');
      await letter(tester, 'A');
      await audio.flush;
      expect(backend.sounds, [GameSound.letter]);
      await tester.pump(const Duration(milliseconds: 230));
      await tester.pumpWidget(const SizedBox());
      await audio.dispose();
    },
  );

  for (final dark in [false, true]) {
    for (final scale in [1.0, 1.3, 1.5]) {
      testWidgets('compact 320/360, dark=$dark scale=$scale remains usable', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        for (final width in [320.0, 360.0]) {
          tester.view.physicalSize = Size(width, 640);
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? ArrowwordTheme.dark() : ArrowwordTheme.light(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: PuzzleScreen(puzzle: manualPuzzle),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          for (final value in 'QWERTYUIOPASDFGHJKLZXCVBNM'.split('')) {
            final key = find.byKey(ValueKey('keyboard-$value'));
            expect(key.hitTestable(), findsOneWidget);
            expect(tester.getSize(key).height, greaterThanOrEqualTo(44));
          }
          final board = tester.getRect(
            find.byKey(const ValueKey('puzzle-board')),
          );
          expect(board.height, greaterThan(0));
          expect(
            board.bottom,
            lessThan(tester.getRect(find.byType(PuzzleKeyboard)).top),
          );
        }
      });
    }
  }
  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('keyboard remains English A-Z under $locale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PuzzleScreen(puzzle: manualPuzzle),
        ),
      );
      await letter(tester, 'W');
      expect(gameOf(tester).letterAt(word.positions.first), 'W');
      expect(find.byKey(const ValueKey('keyboard-I')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('keys expose button semantics and localized delete action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await open(tester);
    expect(find.bySemanticsLabel('Q'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Q'))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    final label = MaterialLocalizations.of(
      tester.element(find.byType(PuzzleKeyboard)),
    ).deleteButtonTooltip;
    expect(find.bySemanticsLabel(label), findsOneWidget);
    semantics.dispose();
  });
}
