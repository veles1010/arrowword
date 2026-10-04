import 'dart:convert';

import 'package:arrowword/app/app.dart';
import 'package:arrowword/app/puzzle_progress_store.dart';
import 'package:arrowword/app/puzzle_session.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_game.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixtureGenerator extends PuzzleSequenceGenerator {
  _FixtureGenerator(this.results, {this.failNext = false})
    : super(prototypeCatalogue, prototypeSequenceConfig);
  final List<SequencePuzzleResult> results;
  final bool failNext;
  @override
  SequencePuzzleResult generateNext({
    required int puzzleIndex,
    List<PuzzleHistoryEntry> history = const [],
  }) {
    expect(
      history.map((h) => h.puzzleIndex),
      List.generate(puzzleIndex - 1, (i) => i + 1),
    );
    if (failNext && puzzleIndex == 2) {
      return SequencePuzzleResult(
        puzzleIndex: 2,
        seed: derivePuzzleSeed(prototypeBaseSeed, 2),
        catalogVersion: 3,
        pool: results.first.pool,
        failureReason: 'Test failure',
      );
    }
    return results[puzzleIndex - 1];
  }
}

void main() {
  late List<SequencePuzzleResult> fixtures;
  setUpAll(
    () => fixtures = PuzzleSequenceGenerator(
      prototypeCatalogue,
      prototypeSequenceConfig,
    ).generateRange(count: 2).puzzles,
  );
  Future<PuzzleSession> open(
    MemoryPuzzleProgressStore store, {
    int? dev,
    bool fail = false,
  }) async {
    final session = await PuzzleSession.restore(
      store: store,
      generator: _FixtureGenerator(fixtures, failNext: fail),
      developmentIndex: dev,
    );
    addTearDown(session.dispose);
    return session;
  }

  PuzzleGame game(PuzzleSession session) {
    final game = PuzzleGame(session.current.puzzle!)
      ..restoreLetters(session.letters);
    game.addListener(() => session.updateLetters(game.enteredLetters));
    addTearDown(game.dispose);
    return game;
  }

  test('no saved state starts empty Puzzle 1', () async {
    final session = await open(MemoryPuzzleProgressStore());
    expect(session.current.puzzleIndex, 1);
    expect(session.letters, isEmpty);
  });
  test('partial entries survive restart with exact deterministic identity and index', () async {
    final store = MemoryPuzzleProgressStore();
    final session = await open(store);
    session.nextPuzzle();
    final playing = game(session);
    playing.enterLetter('A');
    await session.flush;
    final restored = await open(store);
    expect(restored.current.puzzleIndex, 2);
    expect(restored.current.puzzle!.id, session.current.puzzle!.id);
    expect(
      restored.current.generation!.metrics!.structuralSignature,
      session.current.generation!.metrics!.structuralSignature,
    );
    expect(restored.letters, playing.enteredLetters);
  });
  test('selection and validation do not write progress', () async {
    final store = MemoryPuzzleProgressStore();
    final session = await open(store);
    final playing = game(session);
    playing.tapCell(playing.selectedPosition);
    playing.check();
    await session.flush;
    expect(store.writes, 0);
  });
  test('backspace persists removal', () async {
    final store = MemoryPuzzleProgressStore();
    final session = await open(store);
    final playing = game(session);
    final position = playing.selectedPosition;
    playing.enterLetter('A');
    playing.tapCell(position);
    playing.backspace();
    await session.flush;
    expect((await open(store)).letters, isEmpty);
  });
  test('Temizle reset clears persisted letters', () async {
    final store = MemoryPuzzleProgressStore();
    final session = await open(store);
    final playing = game(session);
    playing.enterLetter('A');
    playing.reset();
    await session.flush;
    expect(PuzzleProgress.decode(store.record!).letters, isEmpty);
  });
  test('next puzzle saves new index with empty progress', () async {
    final store = MemoryPuzzleProgressStore();
    final session = await open(store);
    game(session).enterLetter('A');
    session.nextPuzzle();
    await session.flush;
    final restored = await open(store);
    expect(restored.current.puzzleIndex, 2);
    expect(restored.letters, isEmpty);
  });
  test('corrupt record is cleared safely', () async {
    final store = MemoryPuzzleProgressStore('{broken');
    final session = await open(store);
    expect(session.current.puzzleIndex, 1);
    expect(store.record, isNull);
  });
  test(
    'schema, compatibility and identity mismatch never apply old letters',
    () async {
      for (final mutation in [
        {'schemaVersion': 4},
        {'catalogVersion': 2},
        {'puzzleId': 'different'},
        {'signature': 'different'},
        {'puzzleIndex': 0},
      ]) {
        final store = MemoryPuzzleProgressStore();
        final initial = await open(store);
        game(initial).enterLetter('A');
        await initial.flush;
        final data = jsonDecode(store.record!) as Map<String, dynamic>;
        data.addAll(mutation);
        store.record = jsonEncode(data);
        final restored = await open(store);
        expect(restored.current.puzzleIndex, 1);
        expect(restored.letters, isEmpty);
        expect(store.record, isNull);
      }
    },
  );
  test(
    'invalid coordinates and values are ignored, valid letter cell restored',
    () async {
      final store = MemoryPuzzleProgressStore();
      final session = await open(store);
      final playing = game(session);
      playing.enterLetter('A');
      await session.flush;
      final answer = session.current.puzzle!.answers.first;
      final data = jsonDecode(store.record!) as Map<String, dynamic>;
      (data['letters'] as Map).addAll(<String, dynamic>{
        '999,999': 'A',
        '-1,0': 'B',
        'bad': 'C',
        '${answer.cluePosition.row},${answer.cluePosition.column}': 'D',
        '0,0': '🍎',
        '1,0': 'a',
        '2,0': 'AB',
      });
      store.record = jsonEncode(data);
      expect((await open(store)).letters, playing.enteredLetters);
    },
  );
  test('development override ignores progress and never reads or writes player save', () async {
    final store = MemoryPuzzleProgressStore();
    final normal = await open(store);
    game(normal).enterLetter('A');
    await normal.flush;
    final saved = store.record;
    final dev = await open(store, dev: 1);
    expect(dev.letters, isEmpty);
    game(dev).enterLetter('B');
    dev.nextPuzzle();
    await dev.flush;
    expect(dev.current.puzzleIndex, 2);
    expect(store.record, saved);
    final at2 = await open(store, dev: 2);
    expect(at2.current.puzzleIndex, 2);
    expect(at2.letters, isEmpty);
    expect(store.record, saved);
  });
  test('next-generation failure preserves saved current progress', () async {
    final store = MemoryPuzzleProgressStore();
    final session = await open(store, fail: true);
    game(session).enterLetter('A');
    await session.flush;
    final saved = store.record;
    session.nextPuzzle();
    await session.flush;
    expect(session.current.isSuccess, isFalse);
    expect(store.record, saved);
    expect((await open(store)).letters, isNotEmpty);
  });
  testWidgets(
    'solved restore reopens completion and continues without editing',
    (tester) async {
      final store = MemoryPuzzleProgressStore();
      final initial = await open(store);
      final solution = <GridPosition, String>{};
      for (final answer in initial.current.puzzle!.answers) {
        for (var i = 0; i < answer.length; i++) {
          solution[answer.positions[i]] = answer.solution[i];
        }
      }
      initial.updateLetters(solution);
      await initial.flush;
      final restored = await open(store);
      expect(game(restored).isComplete, isTrue);
      await tester.pumpWidget(ArrowwordApp(session: restored));
      await tester.tap(find.text('Devam Et'));
      await tester.pumpAndSettle();
      expect(find.text('Bulmaca tamamlandı!'), findsOneWidget);
      await restored.flush;
      expect(restored.completedThrough, 1);
      expect(PuzzleProgress.decode(store.record!).completedThrough, 1);
      await tester.tap(find.text('Sonraki Bulmaca'));
      await tester.pumpAndSettle();
      await restored.flush;
      expect(find.text('Bulmaca 2'), findsOneWidget);
      expect(PuzzleProgress.decode(store.record!).letters, isEmpty);
    },
  );
}
