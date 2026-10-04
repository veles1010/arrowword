import 'dart:async';
import 'dart:convert';

import 'package:arrowword/app/daily_progress_store.dart';
import 'package:arrowword/app/daily_session.dart';
import 'package:arrowword/features/puzzle/daily/daily_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_game.dart';
import 'package:flutter_test/flutter_test.dart';

Puzzle _puzzle(String date, {String solution = 'CAT', String? id}) => Puzzle(
  id: id ?? dailyPuzzleId(date),
  label: 'Fixture daily',
  rowCount: 2,
  columnCount: 4,
  answers: [
    PuzzleAnswer(
      id: 'cat',
      solution: solution,
      turkishClue: 'Kedi',
      start: const GridPosition(1, 1),
      direction: AnswerDirection.right,
      cluePosition: const GridPosition(1, 0),
    ),
  ],
);

Map<GridPosition, String> _solution(DailyPuzzleAttempt attempt) => {
  for (final answer in attempt.generation.puzzle!.answers)
    for (var index = 0; index < answer.length; index++)
      answer.positions[index]: answer.solution[index],
};

class _DelayedStore extends MemoryDailyProgressStore {
  final releaseFirst = Completer<void>();
  int started = 0;

  @override
  Future<void> write(String record) async {
    started++;
    if (started == 1) await releaseFirst.future;
    await super.write(record);
  }
}

void main() {
  final day = DateTime(2026, 10, 4, 14);

  Future<DailySession> restore(
    MemoryDailyProgressStore store, {
    DateTime Function()? localNow,
    DailyPuzzleGeneration Function(String)? generator,
  }) async {
    final session = await DailySession.restore(
      store: store,
      localNow: localNow ?? () => day,
      generator:
          generator ?? (date) => DailyPuzzleGeneration.success(_puzzle(date)),
    );
    addTearDown(session.dispose);
    return session;
  }

  test(
    'metadata restore is lazy and reopening uses one daily attempt',
    () async {
      final store = MemoryDailyProgressStore();
      final calls = <String>[];
      final session = await restore(
        store,
        generator: (date) {
          calls.add(date);
          return DailyPuzzleGeneration.success(_puzzle(date));
        },
      );
      expect(session.dateKey, '2026-10-04');
      expect(session.todayResult, isNull);
      expect(session.hasCurrentProgress, isFalse);
      expect(session.results, isEmpty);
      expect(calls, isEmpty);
      expect(store.writes, 0);
      final attempt = session.openToday()!;
      expect(attempt.letters, isEmpty);
      expect(attempt.revealedCells, isEmpty);
      expect(attempt.elapsed, Duration.zero);
      expect(attempt.wrongChecks, 0);
      expect(session.openToday(), same(attempt));
      expect(calls, ['2026-10-04']);
      expect(session.hasCurrentProgress, isTrue);
      await session.flush;
      expect(jsonDecode(store.record!)['schemaVersion'], 1);
      expect(
        DailyProgress.decode(store.record!).attempt!.dateKey,
        session.dateKey,
      );
    },
  );

  test('resumes letters, locked hints and accumulated statistics', () async {
    final store = MemoryDailyProgressStore();
    final session = await restore(store);
    final attempt = session.openToday()!;
    const hint = GridPosition(1, 1);
    const entered = GridPosition(1, 2);
    attempt.updateProgress(
      {hint: 'Z', entered: 'A', const GridPosition(9, 9): 'X'},
      {hint, const GridPosition(9, 9)},
      const Duration(milliseconds: 12345),
      3,
    );
    attempt.checkpointElapsed(const Duration(milliseconds: 12567));
    attempt.updateProgress({entered: 'A'}, {}, const Duration(seconds: 1), 1);
    await session.flush;
    final saved = DailyProgress.decode(store.record!).attempt!;
    expect(saved.letters, {'1,2': 'A'});
    expect(saved.revealedCells, ['1,1']);
    expect(saved.hintsUsed, 1);
    expect(saved.elapsedMilliseconds, 12567);
    expect(saved.wrongChecks, 3);
    var calls = 0;
    final resumed = await restore(
      store,
      generator: (date) {
        calls++;
        return DailyPuzzleGeneration.success(_puzzle(date));
      },
    );
    expect(resumed.hasCurrentProgress, isTrue);
    expect(calls, 0);
    final reopened = resumed.openToday()!;
    expect(reopened.letters, {hint: 'C', entered: 'A'});
    expect(reopened.revealedCells, {hint});
    expect(reopened.elapsed.inMilliseconds, 12567);
    expect(reopened.wrongChecks, 3);
    final game = PuzzleGame(
      reopened.generation.puzzle!,
      wrongChecks: reopened.wrongChecks,
    );
    addTearDown(game.dispose);
    game.restoreLetters(
      reopened.letters,
      revealedCells: reopened.revealedCells,
    );
    game.tapCell(hint);
    game.enterLetter('Z');
    game.backspace();
    expect(game.letterAt(hint), 'C');
    game.reset();
    expect(game.enteredLetters, {hint: 'C'});
    expect(game.hintsUsed, 1);
    expect(game.wrongChecks, 3);
    await resumed.flush;
  });

  test('completion verifies cells and preserves the first result', () async {
    final store = MemoryDailyProgressStore();
    final session = await restore(store);
    var notifications = 0;
    session.addListener(() => notifications++);
    final attempt = session.openToday()!;
    attempt.updateProgress(
      {const GridPosition(1, 1): 'Z'},
      {},
      const Duration(seconds: 154),
      1,
    );
    attempt.complete();
    expect(attempt.result, isNull);
    expect(session.results, isEmpty);
    attempt.updateProgress(
      _solution(attempt),
      {const GridPosition(1, 1)},
      const Duration(seconds: 154),
      1,
    );
    expect(session.results, isEmpty);
    attempt.complete();
    final result = attempt.result!;
    expect(result.score, 1175);
    expect(result.elapsedSeconds, 154);
    expect(result.hintsUsed, 1);
    expect(result.wrongChecks, 1);
    expect(result.scoringVersion, 1);
    expect(result.dailySeedVersion, 1);
    expect(result.catalogueVersion, 3);
    expect(session.todayResult, same(result));
    expect(session.hasCurrentProgress, isFalse);
    expect(session.openToday(), isNull);
    expect(() => session.results.clear(), throwsUnsupportedError);
    expect(() => attempt.letters.clear(), throwsUnsupportedError);
    expect(() => attempt.revealedCells.clear(), throwsUnsupportedError);
    await session.flush;
    final record = store.record;
    final writes = store.writes;
    expect(DailyProgress.decode(record!).attempt, isNull);
    attempt.complete();
    attempt.checkpointElapsed(const Duration(hours: 3));
    attempt.updateProgress({}, {}, const Duration(hours: 5), 99);
    await session.flush;
    expect(attempt.result, same(result));
    expect(attempt.elapsed, const Duration(seconds: 154));
    expect(attempt.wrongChecks, 1);
    expect(store.writes, writes);
    expect(notifications, 2);
    final resumed = await restore(
      store,
      generator: (_) => throw StateError('Completed day must not generate'),
    );
    expect(resumed.todayResult!.toJson(), result.toJson());
    expect(resumed.openToday(), isNull);
    await resumed.flush;
    expect(store.record, record);
  });

  test('stale progress is ignored and archived dates are retained', () async {
    var now = day;
    final store = MemoryDailyProgressStore();
    final session = await restore(store, localNow: () => now);
    final original = session.openToday()!;
    original.updateProgress(
      {const GridPosition(1, 1): 'C'},
      {},
      const Duration(seconds: 14),
      2,
    );
    await session.flush;
    now = DateTime(2026, 10, 5);
    final nextSession = await restore(store, localNow: () => now);
    expect(nextSession.hasCurrentProgress, isFalse);
    expect(nextSession.results, isEmpty);
    final next = nextSession.openToday()!;
    expect(next.dateKey, '2026-10-05');
    expect(next.letters, isEmpty);
    expect(next.elapsed, Duration.zero);
    expect(next.wrongChecks, 0);
    next.updateProgress(_solution(next), {}, const Duration(seconds: 80), 0);
    next.complete();
    await nextSession.flush;
    now = DateTime(2026, 10, 6);
    final latest = await restore(store, localNow: () => now);
    expect(latest.todayResult, isNull);
    expect(latest.results.keys, ['2026-10-05']);
    expect(latest.hasCurrentProgress, isFalse);
    latest.openToday();
    await latest.flush;
    expect(DailyProgress.decode(store.record!).results.keys, ['2026-10-05']);
  });

  test('completion remains single when a listener reenters it', () async {
    final store = MemoryDailyProgressStore();
    final session = await restore(store);
    final attempt = session.openToday()!;
    attempt.updateProgress(
      _solution(attempt),
      {},
      const Duration(seconds: 60),
      0,
    );
    await session.flush;
    final writes = store.writes;
    var completionNotifications = 0;
    session.addListener(() {
      completionNotifications++;
      attempt.complete();
    });
    attempt.complete();
    await session.flush;
    expect(completionNotifications, 1);
    expect(store.writes, writes + 1);
    expect(session.todayResult, same(attempt.result));
  });

  test(
    'open attempt completes against its original date after midnight',
    () async {
      var now = DateTime(2026, 10, 4, 23, 59);
      final store = MemoryDailyProgressStore();
      final session = await restore(store, localNow: () => now);
      final original = session.openToday()!;
      now = DateTime(2026, 10, 5, 0, 1);
      session.refreshDate();
      expect(session.dateKey, '2026-10-05');
      expect(session.hasCurrentProgress, isFalse);
      original.updateProgress(
        _solution(original),
        {},
        const Duration(seconds: 121),
        0,
      );
      original.complete();
      expect(original.result!.dateKey, '2026-10-04');
      expect(session.todayResult, isNull);
      expect(session.results.keys, ['2026-10-04']);
      final today = session.openToday()!;
      expect(today.dateKey, '2026-10-05');
      expect(today.letters, isEmpty);
      await session.flush;
    },
  );

  test(
    'older callbacks cannot replace a newer compact daily attempt',
    () async {
      var now = day;
      final store = MemoryDailyProgressStore();
      final session = await restore(store, localNow: () => now);
      final original = session.openToday()!;
      now = DateTime(2026, 10, 5);
      final today = session.openToday()!;
      today.checkpointElapsed(const Duration(seconds: 9));
      original.updateProgress(
        _solution(original),
        {},
        const Duration(seconds: 130),
        0,
      );
      original.complete();
      await session.flush;
      final saved = DailyProgress.decode(store.record!);
      expect(saved.attempt!.dateKey, '2026-10-05');
      expect(saved.attempt!.elapsedMilliseconds, 9000);
      expect(saved.results.keys, ['2026-10-04']);
    },
  );

  test(
    'matching generation validates saved identity before restoring',
    () async {
      final store = MemoryDailyProgressStore();
      final original = await restore(store);
      original.openToday()!.updateProgress(
        {const GridPosition(1, 1): 'C'},
        {const GridPosition(1, 2)},
        const Duration(seconds: 50),
        3,
      );
      await original.flush;
      final raw = store.record;
      final changed = await restore(
        store,
        generator: (date) =>
            DailyPuzzleGeneration.success(_puzzle(date, solution: 'DOG')),
      );
      final reset = changed.openToday()!;
      expect(reset.letters, isEmpty);
      expect(reset.revealedCells, isEmpty);
      expect(reset.elapsed, Duration.zero);
      expect(reset.wrongChecks, 0);
      await changed.flush;
      store.record = raw;
      final wrongId = await restore(
        store,
        generator: (date) =>
            DailyPuzzleGeneration.success(_puzzle(date, id: 'wrong-id')),
      );
      final failed = wrongId.openToday()!;
      expect(failed.generation.isSuccess, isFalse);
      expect(failed.letters, isEmpty);
      failed.complete();
      expect(failed.result, isNull);
    },
  );

  test('only valid letter and hint coordinates are applied', () async {
    final store = MemoryDailyProgressStore();
    final initial = await restore(store);
    initial.openToday();
    await initial.flush;
    final json = jsonDecode(store.record!) as Map<String, dynamic>;
    final attempt = json['attempt'] as Map<String, dynamic>;
    attempt['letters'] = {
      '1,1': 'C',
      '1,2': 'a',
      '1,3': 'LONG',
      '0,0': 'X',
      '9,9': 'X',
      '-1,2': 'Z',
      'broken': 'A',
    };
    attempt['revealedCells'] = ['1,2', '9,9', 'broken'];
    attempt['hintsUsed'] = 3;
    store.record = jsonEncode(json);
    final resumed = await restore(store);
    final current = resumed.openToday()!;
    expect(current.letters, {
      const GridPosition(1, 1): 'C',
      const GridPosition(1, 2): 'A',
    });
    expect(current.hintsUsed, 1);
    await resumed.flush;
    expect(DailyProgress.decode(store.record!).attempt!.hintsUsed, 1);
  });

  test('corrupt payload safely clears without generation', () async {
    for (final record in [
      'not-json',
      '{"schemaVersion":5,"results":{}}',
      '{"schemaVersion":1,"results":[]}',
      '{"schemaVersion":1,"results":{"2026-10-04":{}}}',
    ]) {
      final store = MemoryDailyProgressStore(record);
      final session = await restore(
        store,
        generator: (_) => throw StateError('Restore must stay lazy'),
      );
      expect(session.hasCurrentProgress, isFalse);
      expect(session.results, isEmpty);
      expect(store.record, isNull);
      expect(store.clears, 1);
    }
  });

  test('incompatible attempt is discarded while old results survive', () async {
    final store = MemoryDailyProgressStore();
    var now = day;
    final session = await restore(store, localNow: () => now);
    final first = session.openToday()!;
    first.updateProgress(_solution(first), {}, const Duration(seconds: 60), 0);
    first.complete();
    now = DateTime(2026, 10, 5);
    session.openToday()!.checkpointElapsed(const Duration(seconds: 15));
    await session.flush;
    for (final key in ['catalogueVersion', 'dailySeedVersion']) {
      final json = jsonDecode(store.record!) as Map<String, dynamic>;
      (json['attempt'] as Map<String, dynamic>)[key] = 99;
      final incompatible = MemoryDailyProgressStore(jsonEncode(json));
      final resumed = await restore(incompatible, localNow: () => now);
      expect(resumed.hasCurrentProgress, isFalse);
      expect(resumed.results.keys, ['2026-10-04']);
      expect(DailyProgress.decode(incompatible.record!).attempt, isNull);
    }
  });

  test('failed daily generation has no score or persisted attempt', () async {
    final store = MemoryDailyProgressStore();
    final session = await restore(
      store,
      generator: (_) => DailyPuzzleGeneration.failure('Fixture failure'),
    );
    final attempt = session.openToday()!;
    expect(attempt.generation.failureReason, 'Fixture failure');
    attempt.updateProgress({}, {}, const Duration(seconds: 10), 1);
    attempt.checkpointElapsed(const Duration(seconds: 20));
    attempt.complete();
    expect(attempt.result, isNull);
    expect(session.hasCurrentProgress, isFalse);
    expect(session.openToday(), isNot(same(attempt)));
    await session.flush;
    expect(store.record, isNull);
  });

  test('opening again retries a failed daily generation', () async {
    final store = MemoryDailyProgressStore();
    var calls = 0;
    final session = await restore(
      store,
      generator: (date) {
        calls++;
        return calls == 1
            ? DailyPuzzleGeneration.failure('Temporary failure')
            : DailyPuzzleGeneration.success(_puzzle(date));
      },
    );
    expect(session.openToday()!.generation.isSuccess, isFalse);
    expect(session.hasCurrentProgress, isFalse);
    final recovered = session.openToday()!;
    expect(recovered.generation.isSuccess, isTrue);
    expect(session.openToday(), same(recovered));
    expect(calls, 2);
    await session.flush;
    expect(session.hasCurrentProgress, isTrue);
  });

  test('queued writes retain the newest statistics snapshot', () async {
    final store = _DelayedStore();
    final session = await restore(store);
    final attempt = session.openToday()!;
    attempt.checkpointElapsed(const Duration(milliseconds: 500));
    attempt.updateProgress(
      {const GridPosition(1, 1): 'C'},
      {},
      const Duration(milliseconds: 1234),
      2,
    );
    await Future<void>.delayed(Duration.zero);
    expect(store.started, 1);
    store.releaseFirst.complete();
    await session.flush;
    final saved = DailyProgress.decode(store.record!).attempt!;
    expect(saved.elapsedMilliseconds, 1234);
    expect(saved.wrongChecks, 2);
    expect(saved.letters, {'1,1': 'C'});
    expect(store.writes, 3);
  });
}
