import 'package:arrowword/app/app.dart';
import 'package:arrowword/app/home_screen.dart';
import 'package:arrowword/app/puzzle_progress_store.dart';
import 'package:arrowword/app/puzzle_progression_screen.dart';
import 'package:arrowword/app/puzzle_session.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/presentation/puzzle_screen.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Reuse one valid generated board; progression tests do not need to exercise
// the generator's cooldown policy or generate hundreds of distinct boards.
class _Fixtures extends PuzzleSequenceGenerator {
  _Fixtures(this.fixture) : super(prototypeCatalogue, prototypeSequenceConfig);
  final SequencePuzzleResult fixture;

  @override
  SequencePuzzleResult generateNext({
    required int puzzleIndex,
    List<PuzzleHistoryEntry> history = const [],
  }) => SequencePuzzleResult(
    puzzleIndex: puzzleIndex,
    seed: fixture.seed,
    catalogVersion: fixture.catalogVersion,
    pool: fixture.pool,
    puzzle: Puzzle(
      id: 'progression-fixture-$puzzleIndex',
      label: fixture.puzzle!.label,
      rowCount: fixture.puzzle!.rowCount,
      columnCount: fixture.puzzle!.columnCount,
      answers: fixture.puzzle!.answers,
    ),
    generation: fixture.generation,
  );
}

Finder _tile(int index) => find.byKey(ValueKey('puzzle-tile-$index'));
Finder _score(int index) => find.byKey(ValueKey('puzzle-score-$index'));
Finder _status(int index, String text) =>
    find.descendant(of: _tile(index), matching: find.text(text));

Map<GridPosition, String> _solution(PuzzleSession session) => {
  for (final answer in session.current.puzzle!.answers)
    for (var i = 0; i < answer.length; i++)
      answer.positions[i]: answer.solution[i],
};

void _complete(PuzzleSession session) {
  session.updateLetters(_solution(session));
  session.recognizeCompletion();
}

Future<void> _openProgression(
  WidgetTester tester,
  PuzzleSession session,
) async {
  await tester.pumpWidget(ArrowwordApp(session: session));
  await tester.tap(find.text('Bulmacalar'));
  await tester.pumpAndSettle();
  expect(find.byType(PuzzleProgressionScreen), findsOneWidget);
}

void main() {
  late SequencePuzzleResult fixture;
  setUpAll(() {
    fixture = PuzzleSequenceGenerator(
      prototypeCatalogue,
      prototypeSequenceConfig,
    ).generateNext(puzzleIndex: 1);
    expect(fixture.isSuccess, isTrue);
  });

  PuzzleSession sessionAt(int index, {PuzzleProgressStore? store}) {
    final session = PuzzleSession(
      generator: _Fixtures(fixture),
      startIndex: index,
      store: store,
    );
    addTearDown(session.dispose);
    return session;
  }

  testWidgets(
    'fresh progression offers current puzzle and five locked previews',
    (tester) async {
      await _openProgression(tester, sessionAt(1));
      expect(_status(1, 'Devam Et'), findsOneWidget);
      expect(_score(1), findsNothing);
      for (var index = 2; index <= 6; index++) {
        await tester.ensureVisible(_tile(index));
        expect(_status(index, 'Kilitli'), findsOneWidget);
        expect(_score(index), findsNothing);
        expect(
          find.descendant(
            of: _tile(index),
            matching: find.text('Bulmaca $index'),
          ),
          findsOneWidget,
        );
      }
      expect(_tile(7), findsNothing);
    },
  );

  testWidgets('completed and locked tiles cannot open gameplay', (
    tester,
  ) async {
    final session = sessionAt(6);
    await _openProgression(tester, session);
    for (var index = 1; index <= 5; index++) {
      await tester.ensureVisible(_tile(index));
      expect(_status(index, 'Tamamlandı'), findsOneWidget);
      expect(_score(index), findsNothing);
      expect(_status(index, '0 puan'), findsNothing);
      expect(_status(index, '-'), findsNothing);
      await tester.tap(_tile(index));
      await tester.pumpAndSettle();
      expect(find.byType(PuzzleScreen), findsNothing);
    }
    await tester.ensureVisible(_tile(7));
    expect(_status(7, 'Kilitli'), findsOneWidget);
    await tester.tap(_tile(7));
    await tester.pumpAndSettle();
    expect(find.byType(PuzzleScreen), findsNothing);
    expect(session.current.puzzleIndex, 6);
  });

  testWidgets(
    'current opens exact session board and back returns through Home',
    (tester) async {
      final session = sessionAt(6);
      await _openProgression(tester, session);
      await tester.ensureVisible(_tile(6));
      expect(_status(6, 'Devam Et'), findsOneWidget);
      await tester.tap(_tile(6));
      await tester.pumpAndSettle();
      final screen = tester.widget<PuzzleScreen>(find.byType(PuzzleScreen));
      expect(screen.puzzle, same(session.current.puzzle));
      expect(screen.title, 'Bulmaca 6');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(PuzzleProgressionScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  testWidgets('advancing refreshes completed current and locked statuses', (
    tester,
  ) async {
    final session = sessionAt(1);
    await _openProgression(tester, session);
    await tester.tap(_tile(1));
    await tester.pumpAndSettle();
    final expected = _solution(session);
    for (final entry in expected.entries) {
      await tester.tap(
        find.byKey(ValueKey('cell-${entry.key.row}-${entry.key.column}')),
      );
      await tester.enterText(find.byType(TextField), entry.value);
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(session.completedThrough, 1);
    final score = session.completedScores[1]!.score;
    await tester.tap(find.text('Kapat'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(_status(1, 'Devam Et'), findsOneWidget);
    expect(_status(1, '$score puan'), findsOneWidget);
    expect(_score(1), findsOneWidget);
    await tester.tap(_tile(1));
    await tester.pumpAndSettle();
    expect(find.text('Sonraki Bulmaca'), findsOneWidget);
    await tester.tap(find.text('Sonraki Bulmaca'));
    await tester.pumpAndSettle();
    expect(session.current.puzzleIndex, 2);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(_status(1, 'Tamamlandı'), findsOneWidget);
    expect(_status(1, '$score puan'), findsOneWidget);
    expect(_status(2, 'Devam Et'), findsOneWidget);
    expect(_score(2), findsNothing);
    expect(_status(3, 'Kilitli'), findsOneWidget);
    expect(_score(3), findsNothing);
    await tester.tap(_tile(1));
    await tester.pumpAndSettle();
    expect(find.byType(PuzzleScreen), findsNothing);
    await tester.ensureVisible(_tile(7));
    expect(_status(7, 'Kilitli'), findsOneWidget);
    expect(_tile(8), findsNothing);
  });

  testWidgets('solved current remains accessible before advancing', (
    tester,
  ) async {
    final session = sessionAt(1);
    await _openProgression(tester, session);
    _complete(session);
    await tester.pumpAndSettle();
    expect(session.completedThrough, 1);
    expect(_status(1, 'Devam Et'), findsOneWidget);
    expect(_status(1, '${session.currentScore!.score} puan'), findsOneWidget);
    expect(_score(1), findsOneWidget);
    await tester.tap(_tile(1));
    await tester.pumpAndSettle();
    expect(find.byType(PuzzleScreen), findsOneWidget);
    expect(session.current.puzzleIndex, 1);
  });

  testWidgets('session recreation retains completion and current letters', (
    tester,
  ) async {
    final store = MemoryPuzzleProgressStore();
    final session = sessionAt(6, store: store);
    final position = session.current.puzzle!.answers.first.start;
    session.updateLetters({position: 'B'});
    await session.flush;
    final restored = await PuzzleSession.restore(
      store: store,
      generator: _Fixtures(fixture),
    );
    addTearDown(restored.dispose);
    expect(restored.completedThrough, 5);
    expect(restored.current.puzzleIndex, 6);
    expect(restored.letters[position], 'B');
    await _openProgression(tester, restored);
    await tester.ensureVisible(_tile(6));
    await tester.tap(_tile(6));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(ValueKey('cell-${position.row}-${position.column}')),
        matching: find.text('B'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('recreated session displays its persisted completed score', (
    tester,
  ) async {
    final store = MemoryPuzzleProgressStore();
    final session = sessionAt(1, store: store);
    session.checkpointElapsed(const Duration(seconds: 75));
    _complete(session);
    final score = session.currentScore!.score;
    await session.flush;
    final restored = await PuzzleSession.restore(
      store: store,
      generator: _Fixtures(fixture),
    );
    addTearDown(restored.dispose);
    await _openProgression(tester, restored);
    expect(_status(1, 'Devam Et'), findsOneWidget);
    expect(_status(1, '$score puan'), findsOneWidget);
    expect(_score(1), findsOneWidget);
    expect(_score(2), findsNothing);
    expect(_score(3), findsNothing);
    await tester.tap(_tile(1));
    await tester.pumpAndSettle();
    expect(find.byType(PuzzleScreen), findsOneWidget);
    await tester.tap(find.text('Sonraki Bulmaca'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(_status(1, 'Tamamlandı'), findsOneWidget);
    expect(_status(1, '$score puan'), findsOneWidget);
    expect(_score(2), findsNothing);
    await tester.tap(_tile(1));
    await tester.pumpAndSettle();
    expect(find.byType(PuzzleScreen), findsNothing);
  });

  testWidgets('a genuine earned zero score is shown, not treated as legacy', (
    tester,
  ) async {
    final session = sessionAt(1);
    session.updateAttemptProgress(
      _solution(session),
      {},
      const Duration(seconds: 600),
      40,
    );
    session.recognizeCompletion();
    expect(session.currentScore!.score, 0);
    await _openProgression(tester, session);
    expect(_status(1, '0 puan'), findsOneWidget);
    expect(_score(1), findsOneWidget);
  });

  testWidgets('high scored current index fits compact enlarged text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final session = sessionAt(1000);
    _complete(session);
    await _openProgression(tester, session);
    expect(_tile(1000).hitTestable(), findsOneWidget);
    expect(_status(1000, 'Devam Et'), findsOneWidget);
    expect(_score(1000), findsOneWidget);
    expect(
      _status(1000, '${session.currentScore!.score} puan'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    await tester.pumpAndSettle();
    await tester.tap(_tile(1000));
    await tester.pumpAndSettle();
    expect(find.byType(PuzzleScreen), findsOneWidget);
    expect(find.text('Bulmaca 1000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
