import 'package:arrowword/app/puzzle_progress_store.dart';
import 'package:arrowword/app/app.dart';
import 'package:arrowword/app/puzzle_session.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

class _Fixtures extends PuzzleSequenceGenerator {
  _Fixtures(this.results, {this.failNext = false})
    : super(prototypeCatalogue, prototypeSequenceConfig);
  final List<SequencePuzzleResult> results;
  final bool failNext;
  final List<int> calls = [];
  @override
  SequencePuzzleResult generateNext({
    required int puzzleIndex,
    List<PuzzleHistoryEntry> history = const [],
  }) {
    calls.add(puzzleIndex);
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
  late List<SequencePuzzleResult> results;
  setUpAll(() {
    results = PuzzleSequenceGenerator(
      prototypeCatalogue,
      prototypeSequenceConfig,
    ).generateRange(count: 2).puzzles;
  });

  Future<PuzzleSession> open(
    MemoryPuzzleProgressStore store, {
    int? dev,
    _Fixtures? generator,
  }) async {
    final session = await PuzzleSession.restore(
      store: store,
      generator: generator ?? _Fixtures(results),
      developmentIndex: dev,
    );
    addTearDown(session.dispose);
    return session;
  }

  Map<GridPosition, String> solution(PuzzleSession session) => {
    for (final answer in session.current.puzzle!.answers)
      for (var i = 0; i < answer.length; i++)
        answer.positions[i]: answer.solution[i],
  };

  void solve(PuzzleSession session, {Set<GridPosition> hints = const {}}) {
    session.updateAttemptProgress(
      solution(session),
      hints,
      const Duration(seconds: 180),
      2,
    );
    session.recognizeCompletion();
  }

  String legacyRecord({required bool completed}) {
    final result = results[1];
    final letters = <GridPosition, String>{
      for (final answer in result.puzzle!.answers)
        for (var i = 0; i < answer.length; i++)
          answer.positions[i]: answer.solution[i],
    };
    final hint = letters.keys.first;
    if (!completed) letters.remove(letters.keys.last);
    return PuzzleProgress(
      schemaVersion: 4,
      catalogVersion: 3,
      puzzleIndex: 2,
      puzzleId: result.puzzle!.id,
      signature: result.generation!.metrics!.structuralSignature,
      completedThrough: completed ? 2 : 1,
      letters: {
        for (final entry in letters.entries)
          if (entry.key != hint)
            '${entry.key.row},${entry.key.column}': entry.value,
      },
      revealedCells: ['${hint.row},${hint.column}'],
      hintsUsed: 1,
      history: [
        ProgressHistoryEntry(
          puzzleIndex: 1,
          wordIds: results.first.toHistory().words.keys.toList(),
        ),
      ],
    ).encode();
  }

  test(
    'completion scores once and survives restart as an immutable result',
    () async {
      final store = MemoryPuzzleProgressStore();
      final session = await open(store);
      session.recognizeCompletion();
      expect(session.currentScore, isNull);
      solve(session);
      final score = session.currentScore!;
      expect(score.score, 1250);
      expect(score.elapsedSeconds, 180);
      expect(score.wrongChecks, 2);
      session.recognizeCompletion();
      expect(session.currentScore, same(score));
      expect(() => session.completedScores.clear(), throwsUnsupportedError);
      await session.flush;
      final saved = store.record;
      final restored = await open(store);
      restored.recognizeCompletion();
      await restored.flush;
      expect(restored.currentScore!.toJson(), score.toJson());
      expect(store.record, saved);
    },
  );

  test(
    'elapsed milliseconds and wrong checks persist and do not regress',
    () async {
      final store = MemoryPuzzleProgressStore();
      final session = await open(store);
      session.updateAttemptProgress(
        {},
        {},
        const Duration(milliseconds: 12345),
        3,
      );
      session.checkpointElapsed(const Duration(milliseconds: 12567));
      session.updateAttemptProgress({}, {}, const Duration(seconds: 1), 1);
      await session.flush;
      final restored = await open(store);
      expect(restored.elapsed.inMilliseconds, 12567);
      expect(restored.wrongChecks, 3);
    },
  );

  test('revealed cells contribute to the completed score', () async {
    final session = await open(MemoryPuzzleProgressStore());
    final hint = session.current.puzzle!.answers.first.start;
    solve(session, hints: {hint});
    expect(session.currentScore!.hintsUsed, 1);
    expect(session.currentScore!.score, 1150);
    await session.flush;
  });

  test(
    'next puzzle resets attempts while retaining the score archive',
    () async {
      final store = MemoryPuzzleProgressStore();
      final session = await open(store);
      solve(session, hints: {session.current.puzzle!.answers.first.start});
      final score = session.currentScore!.toJson();
      session.nextPuzzle();
      await session.flush;
      final restored = await open(store);
      expect(restored.current.puzzleIndex, 2);
      expect(restored.elapsed, Duration.zero);
      expect(restored.wrongChecks, 0);
      expect(restored.hintsUsed, 0);
      expect(restored.letters, isEmpty);
      expect(restored.currentScore, isNull);
      expect(restored.completedScores[1]!.toJson(), score);
    },
  );

  testWidgets(
    'disposing completed screen cannot transfer its timer into Next',
    (tester) async {
      final session = await open(MemoryPuzzleProgressStore());
      session.updateAttemptProgress(
        solution(session),
        {},
        const Duration(seconds: 180),
        2,
      );
      await tester.pumpWidget(ArrowwordApp(session: session));
      await tester.tap(find.text('Devam Et'));
      await tester.pumpAndSettle();
      expect(find.text('Bulmaca tamamlandı!'), findsOneWidget);
      expect(session.currentScore!.score, 1250);
      await tester.tap(find.text('Sonraki Bulmaca'));
      await tester.pumpAndSettle();
      expect(session.current.puzzleIndex, 2);
      expect(session.elapsed, Duration.zero);
      expect(session.wrongChecks, 0);
      expect(session.currentScore, isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test(
    'schema 4 incomplete migration preserves progress with zero statistics',
    () async {
      final raw = legacyRecord(completed: false);
      final old = PuzzleProgress.decode(raw);
      final store = MemoryPuzzleProgressStore(raw);
      final generator = _Fixtures(results);
      final session = await open(store, generator: generator);
      expect(generator.calls, [2]);
      expect(session.hintsUsed, 1);
      expect(session.letters.length, old.letters.length + 1);
      expect(session.completedThrough, 1);
      expect(session.elapsed, Duration.zero);
      expect(session.wrongChecks, 0);
      expect(session.completedScores, isEmpty);
      final saved = PuzzleProgress.decode(store.record!);
      expect(saved.schemaVersion, 5);
      expect(saved.letters, old.letters);
      expect(saved.revealedCells, old.revealedCells);
      expect(
        saved.history.single.wordIds.toSet(),
        old.history.single.wordIds.toSet(),
      );
    },
  );

  test('legacy completed solved puzzle never fabricates a score', () async {
    final store = MemoryPuzzleProgressStore(legacyRecord(completed: true));
    final session = await open(store);
    expect(session.letters, solution(session));
    session.recognizeCompletion();
    await session.flush;
    expect(session.completedThrough, 2);
    expect(session.currentScore, isNull);
    expect(PuzzleProgress.decode(store.record!).completedScores, isEmpty);
  });

  test('development completion leaves the player record unchanged', () async {
    final store = MemoryPuzzleProgressStore();
    final player = await open(store);
    player.checkpointElapsed(const Duration(seconds: 20));
    await player.flush;
    final saved = store.record;
    final developer = await open(store, dev: 1);
    solve(developer);
    developer.nextPuzzle();
    await developer.flush;
    expect(store.record, saved);
  });

  test(
    'failed next generation preserves the completed result and save',
    () async {
      final store = MemoryPuzzleProgressStore();
      final session = await open(
        store,
        generator: _Fixtures(results, failNext: true),
      );
      solve(session);
      await session.flush;
      final saved = store.record;
      final score = session.currentScore!.toJson();
      session.nextPuzzle();
      await session.flush;
      expect(session.current.isSuccess, isFalse);
      expect(store.record, saved);
      expect(session.completedScores[1]!.toJson(), score);
      expect((await open(store)).currentScore!.toJson(), score);
    },
  );

  test(
    'mutations after completion preserve the original score snapshot',
    () async {
      final store = MemoryPuzzleProgressStore();
      final session = await open(store);
      solve(session, hints: {session.current.puzzle!.answers.first.start});
      final score = session.currentScore!.toJson();
      session.updateAttemptProgress({}, {}, const Duration(hours: 1), 99);
      session.recognizeCompletion();
      await session.flush;
      final restored = await open(store);
      expect(restored.letters, isEmpty);
      expect(restored.hintsUsed, 0);
      expect(restored.elapsed, const Duration(seconds: 180));
      expect(restored.wrongChecks, 2);
      expect(restored.currentScore!.toJson(), score);
    },
  );
}
