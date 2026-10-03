import 'package:arrowword/app/app.dart';
import 'package:arrowword/app/home_screen.dart';
import 'package:arrowword/app/puzzle_progress_store.dart';
import 'package:arrowword/app/puzzle_session.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:arrowword/features/puzzle/presentation/puzzle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Fixtures extends PuzzleSequenceGenerator {
  _Fixtures(this.results) : super(prototypeCatalogue, prototypeSequenceConfig);
  final List<SequencePuzzleResult> results;
  @override
  SequencePuzzleResult generateNext({
    required int puzzleIndex,
    List<PuzzleHistoryEntry> history = const [],
  }) => results[puzzleIndex - 1];
}

void main() {
  late List<SequencePuzzleResult> results;
  setUpAll(
    () => results = PuzzleSequenceGenerator(
      prototypeCatalogue,
      prototypeSequenceConfig,
    ).generateRange(count: 2).puzzles,
  );
  testWidgets(
    'fresh Home starts Puzzle 1, back refreshes Continue, restart retains letters',
    (tester) async {
      final store = MemoryPuzzleProgressStore();
      final session = await PuzzleSession.restore(
        store: store,
        generator: _Fixtures(results),
      );
      addTearDown(session.dispose);
      await tester.pumpWidget(ArrowwordApp(session: session));
      expect(find.text('Arrowword'), findsOneWidget);
      expect(find.text('Bulmaca 1'), findsOneWidget);
      expect(find.text('Başla'), findsOneWidget);
      expect(find.byType(PuzzleScreen), findsNothing);
      await tester.tap(find.text('Başla'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<PuzzleScreen>(find.byType(PuzzleScreen)).puzzle.id,
        results.first.puzzle!.id,
      );
      final answer = results.first.puzzle!.answers.first;
      await tester.tap(
        find.byKey(ValueKey('cell-${answer.start.row}-${answer.start.column}')),
      );
      await tester.enterText(find.byType(TextField), 'A');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await session.flush;
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Devam Et'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      final restored = await PuzzleSession.restore(
        store: store,
        generator: _Fixtures(results),
      );
      addTearDown(restored.dispose);
      await tester.pumpWidget(ArrowwordApp(session: restored));
      expect(find.text('Devam Et'), findsOneWidget);
      expect(restored.letters[answer.start], 'A');
    },
  );
  testWidgets(
    'saved Puzzle 2 Home opens exactly that puzzle with its letters',
    (tester) async {
      final second = results[1];
      final p = second.puzzle!.answers.first.start;
      final store = MemoryPuzzleProgressStore(
        PuzzleProgress(
          catalogVersion: 3,
          puzzleIndex: 2,
          puzzleId: second.puzzle!.id,
          signature: second.generation!.metrics!.structuralSignature,
          letters: {'${p.row},${p.column}': 'B'},
        ).encode(),
      );
      final session = await PuzzleSession.restore(
        store: store,
        generator: _Fixtures(results),
      );
      addTearDown(session.dispose);
      await tester.pumpWidget(ArrowwordApp(session: session));
      expect(find.text('Bulmaca 2'), findsOneWidget);
      expect(find.text('Devam Et'), findsOneWidget);
      await tester.tap(find.text('Devam Et'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<PuzzleScreen>(find.byType(PuzzleScreen)).puzzle.id,
        second.puzzle!.id,
      );
      expect(
        find.descendant(
          of: find.byKey(ValueKey('cell-${p.row}-${p.column}')),
          matching: find.text('B'),
        ),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Bulmaca 2'), findsOneWidget);
    },
  );
  testWidgets(
    'development launch bypasses Home without touching player progress',
    (tester) async {
      final store = MemoryPuzzleProgressStore('untouched player record');
      final session = await PuzzleSession.restore(
        store: store,
        generator: _Fixtures(results),
        developmentIndex: 2,
      );
      addTearDown(session.dispose);
      await tester.pumpWidget(
        ArrowwordApp(session: session, openPuzzleDirectly: true),
      );
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.text('Bulmaca 2'), findsOneWidget);
      final p = session.current.puzzle!.answers.first.start;
      await tester.tap(find.byKey(ValueKey('cell-${p.row}-${p.column}')));
      await tester.enterText(find.byType(TextField), 'C');
      await session.flush;
      expect(store.record, 'untouched player record');
      expect(store.writes, 0);
    },
  );
}
