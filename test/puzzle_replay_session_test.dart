import 'dart:convert';

import 'package:arrowword/app/puzzle_progress_store.dart';
import 'package:arrowword/app/puzzle_session.dart';
import 'package:arrowword/app/puzzle_replay_attempt.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_score.dart';
import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

class _CachedGenerator extends PuzzleSequenceGenerator {
  _CachedGenerator(this.results)
    : super(prototypeCatalogue, prototypeSequenceConfig);
  final List<SequencePuzzleResult> results;
  final List<int> calls = [];
  final List<List<PuzzleHistoryEntry>> prefixes = [];
  bool fail = false;
  bool mismatch = false;
  @override
  SequencePuzzleResult generateNext({
    required int puzzleIndex,
    List<PuzzleHistoryEntry> history = const [],
  }) {
    calls.add(puzzleIndex);
    prefixes.add(List.of(history));
    if (fail) throw StateError('Generation failed');
    return results[mismatch ? 0 : puzzleIndex - 1];
  }
}

void main() {
  late List<SequencePuzzleResult> results;
  setUpAll(() {
    results = PuzzleSequenceGenerator(
      prototypeCatalogue,
      prototypeSequenceConfig,
    ).generateRange(count: 3).puzzles;
  });

  test(
    'ephemeral attempt discards partial data and finalizes only once',
    () async {
      final store = MemoryPuzzleProgressStore();
      final session = PuzzleSession(
        generator: _CachedGenerator(results),
        startIndex: 3,
        store: store,
      );
      addTearDown(session.dispose);
      final currentCell = session.current.puzzle!.answers.first.start;
      final normalHint = session.current.puzzle!.answers.first.positions[1];
      session.updateAttemptProgress(
        {currentCell: 'A'},
        {normalHint},
        const Duration(seconds: 17),
        2,
      );
      await session.flush;
      final normalRecord = PuzzleProgress.decode(store.record!);
      final writes = store.writes;
      final attempt = PuzzleReplayAttempt(session: session, puzzleIndex: 2);
      expect(attempt.letters, isEmpty);
      expect(attempt.revealedCells, isEmpty);
      expect(attempt.hintsUsed, 0);
      expect(attempt.elapsed, Duration.zero);
      expect(attempt.wrongChecks, 0);
      final puzzle = attempt.generation.puzzle!;
      final first = puzzle.answers.first.start;
      attempt.updateProgress({first: 'Z'}, {}, const Duration(seconds: 150), 1);
      attempt.complete();
      await session.flush;
      expect(attempt.result, isNull);
      expect(store.writes, writes);
      final fresh = PuzzleReplayAttempt(session: session, puzzleIndex: 2);
      expect(fresh.letters, isEmpty);
      final solution = <GridPosition, String>{
        for (final a in puzzle.answers)
          for (var i = 0; i < a.length; i++) a.positions[i]: a.solution[i],
      };
      attempt.updateProgress(
        solution,
        {first},
        const Duration(seconds: 154),
        1,
      );
      attempt.complete();
      await session.flush;
      final winner = attempt.result!;
      expect(winner.score, 1175);
      expect(attempt.isNewBest, isTrue);
      final saved = PuzzleProgress.decode(store.record!);
      expect(saved.completedScores[2]!.toJson(), winner.toJson());
      expect(saved.letters, normalRecord.letters);
      expect(saved.revealedCells, normalRecord.revealedCells);
      expect(saved.elapsedMilliseconds, normalRecord.elapsedMilliseconds);
      expect(saved.wrongChecks, normalRecord.wrongChecks);
      expect(saved.completedThrough, normalRecord.completedThrough);
      expect(saved.puzzleIndex, normalRecord.puzzleIndex);
      expect(
        saved.history.map((e) => e.wordIds),
        normalRecord.history.map((e) => e.wordIds),
      );
      final restarted = await PuzzleSession.restore(
        store: store,
        generator: _CachedGenerator(results),
      );
      addTearDown(restarted.dispose);
      expect(restarted.letters, session.letters);
      expect(restarted.revealedCells, {normalHint});
      expect(restarted.elapsed, session.elapsed);
      expect(restarted.wrongChecks, session.wrongChecks);
      expect(restarted.completedThrough, session.completedThrough);
      expect(restarted.current.puzzleIndex, session.current.puzzleIndex);
      expect(restarted.completedScores[2]!.toJson(), winner.toJson());
      final completedWrites = store.writes;
      attempt.complete();
      attempt.updateProgress({}, {}, const Duration(hours: 1), 99);
      attempt.checkpointElapsed(const Duration(hours: 2));
      await session.flush;
      expect(attempt.result, same(winner));
      expect(attempt.elapsed, const Duration(seconds: 154));
      expect(attempt.wrongChecks, 1);
      expect(store.writes, completedWrites);
    },
  );

  test(
    'replay generates only requested index and preserves current attempt',
    () async {
      final generator = _CachedGenerator(results);
      final store = MemoryPuzzleProgressStore();
      final session = PuzzleSession(
        generator: generator,
        startIndex: 3,
        store: store,
      );
      addTearDown(session.dispose);
      final answer = session.current.puzzle!.answers.first;
      final cell = answer.positions.first;
      session.updateAttemptProgress(
        {cell: answer.solution[0]},
        {cell},
        const Duration(seconds: 37),
        2,
      );
      await session.flush;
      final current = session.current;
      final history = session.history;
      final record = store.record;
      final writes = store.writes;
      var notifications = 0;
      session.addListener(() => notifications++);
      final replay = session.buildReplayPuzzle(2);
      expect(replay.isSuccess, isTrue);
      expect(generator.calls, [1, 2, 3, 2]);
      expect(generator.prefixes.last.map((entry) => entry.puzzleIndex), [1]);
      final actual = PuzzleSequenceGenerator(
        prototypeCatalogue,
        prototypeSequenceConfig,
      ).generateNext(puzzleIndex: 2, history: [results.first.toHistory()]);
      expect(
        replay.generation!.metrics!.structuralSignature,
        actual.generation!.metrics!.structuralSignature,
      );
      expect(session.current, same(current));
      expect(session.history, history);
      expect(session.letters, {cell: answer.solution[0]});
      expect(session.revealedCells, {cell});
      expect(session.elapsed, const Duration(seconds: 37));
      expect(session.wrongChecks, 2);
      expect(session.completedThrough, 2);
      expect(session.completedScores, isEmpty);
      expect(store.record, record);
      expect(store.writes, writes);
      expect(notifications, 0);
      for (final index in [-1, 0, 3, 4]) {
        expect(session.buildReplayPuzzle(index).failureReason, isNotNull);
      }
      expect(generator.calls, [1, 2, 3, 2]);
      generator.fail = true;
      expect(
        session.buildReplayPuzzle(2).failureReason,
        'Bulmaca tekrar oluşturulamadı.',
      );
      generator.fail = false;
      generator.mismatch = true;
      expect(session.buildReplayPuzzle(2).isSuccess, isFalse);
      expect(session.current, same(current));
      expect(store.record, record);
    },
  );

  test(
    'only improvements write and notify while normal attempt survives restore',
    () async {
      final store = MemoryPuzzleProgressStore();
      final session = PuzzleSession(
        generator: _CachedGenerator(results),
        startIndex: 3,
        store: store,
      );
      addTearDown(session.dispose);
      session.updateAttemptProgress({}, {}, const Duration(seconds: 42), 3);
      await session.flush;
      var notifications = 0;
      session.addListener(() => notifications++);
      CompletedPuzzleScore result(
        int seconds, {
        int index = 2,
        int hints = 0,
      }) => CompletedPuzzleScore.calculate(
        puzzleIndex: index,
        elapsedSeconds: seconds,
        hintsUsed: hints,
        wrongChecks: 0,
      );
      final first = result(110, hints: 1);
      expect(session.recordReplayScore(first), isTrue);
      await session.flush;
      final record = store.record;
      final writes = store.writes;
      expect(session.recordReplayScore(result(110, hints: 1)), isFalse);
      expect(session.recordReplayScore(result(100, hints: 2)), isFalse);
      expect(session.recordReplayScore(result(10, index: 3)), isFalse);
      await session.flush;
      expect(session.completedScores[2], same(first));
      expect(store.record, record);
      expect(store.writes, writes);
      expect(notifications, 1);
      expect(session.recordReplayScore(result(109, hints: 1)), isTrue);
      expect(session.recordReplayScore(result(120)), isTrue);
      await session.flush;
      final restored = await PuzzleSession.restore(
        store: store,
        generator: _CachedGenerator(results),
      );
      addTearDown(restored.dispose);
      expect(restored.completedScores[2]!.elapsedSeconds, 120);
      expect(restored.elapsed, const Duration(seconds: 42));
      expect(restored.wrongChecks, 3);
      expect(restored.completedThrough, 2);
      expect(restored.current.puzzleIndex, 3);
    },
  );

  test(
    'legacy completed boards acquire a best only after replay completion',
    () async {
      final store = MemoryPuzzleProgressStore();
      final initial = PuzzleSession(
        generator: _CachedGenerator(results),
        startIndex: 3,
        store: store,
      );
      addTearDown(initial.dispose);
      initial.checkpointElapsed(const Duration(seconds: 12));
      await initial.flush;
      final legacy = jsonDecode(store.record!) as Map<String, dynamic>;
      legacy['schemaVersion'] = 4;
      legacy.remove('completedScores');
      legacy.remove('elapsedMilliseconds');
      legacy.remove('wrongChecks');
      store.record = jsonEncode(legacy);
      final session = await PuzzleSession.restore(
        store: store,
        generator: _CachedGenerator(results),
      );
      addTearDown(session.dispose);
      expect(session.completedScores, isEmpty);
      final writes = store.writes;
      expect(session.buildReplayPuzzle(2).isSuccess, isTrue);
      expect(session.completedScores, isEmpty);
      expect(store.writes, writes);
      expect(
        session.recordReplayScore(
          CompletedPuzzleScore.calculate(
            puzzleIndex: 2,
            elapsedSeconds: 60,
            hintsUsed: 0,
            wrongChecks: 0,
          ),
        ),
        isTrue,
      );
      await session.flush;
      expect(PuzzleProgress.decode(store.record!).completedScores.keys, [2]);
      expect(session.completedThrough, 2);
    },
  );

  test(
    'development replay best never writes the real progress store',
    () async {
      final store = MemoryPuzzleProgressStore('real progress');
      final session = await PuzzleSession.restore(
        store: store,
        generator: _CachedGenerator(results),
        developmentIndex: 3,
      );
      addTearDown(session.dispose);
      expect(
        session.recordReplayScore(
          CompletedPuzzleScore.calculate(
            puzzleIndex: 1,
            elapsedSeconds: 60,
            hintsUsed: 0,
            wrongChecks: 0,
          ),
        ),
        isTrue,
      );
      await session.flush;
      expect(store.record, 'real progress');
      expect(store.writes, 0);
    },
  );

  test(
    'unavailable current generation cannot lose a replay score write',
    () async {
      final store = MemoryPuzzleProgressStore();
      final session = PuzzleSession(
        generator: _CachedGenerator(results),
        startIndex: 3,
        store: store,
      );
      addTearDown(session.dispose);
      session.checkpointElapsed(const Duration(seconds: 12));
      await session.flush;
      final saved = store.record;
      final current = session.current;
      session.current = SequencePuzzleResult(
        puzzleIndex: 4,
        seed: current.seed,
        catalogVersion: current.catalogVersion,
        pool: current.pool,
        failureReason: 'Unavailable next puzzle',
      );
      expect(session.buildReplayPuzzle(2).isSuccess, isFalse);
      expect(
        session.recordReplayScore(
          CompletedPuzzleScore.calculate(
            puzzleIndex: 2,
            elapsedSeconds: 60,
            hintsUsed: 0,
            wrongChecks: 0,
          ),
        ),
        isFalse,
      );
      await session.flush;
      expect(session.completedScores, isEmpty);
      expect(store.record, saved);
    },
  );
}
