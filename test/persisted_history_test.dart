import 'dart:convert';

import 'package:arrowword/app/puzzle_progress_store.dart';
import 'package:arrowword/app/puzzle_session.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

class _Spy extends PuzzleSequenceGenerator {
  _Spy(this.results, {this.failAt})
    : super(prototypeCatalogue, prototypeSequenceConfig);
  final List<SequencePuzzleResult> results;
  final int? failAt;
  final List<int> calls = [];
  final List<List<PuzzleHistoryEntry>> received = [];
  @override
  SequencePuzzleResult generateNext({
    required int puzzleIndex,
    List<PuzzleHistoryEntry> history = const [],
  }) {
    calls.add(puzzleIndex);
    received.add(List.of(history));
    if (puzzleIndex == failAt) {
      return SequencePuzzleResult(
        puzzleIndex: puzzleIndex,
        seed: 0,
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
  setUpAll(
    () => results = PuzzleSequenceGenerator(
      prototypeCatalogue,
      prototypeSequenceConfig,
    ).generateRange(count: 3).puzzles,
  );
  String record(int index, {int schema = 3, int? completed}) {
    final r = results[index - 1];
    final p = r.puzzle!.answers.first.start;
    return PuzzleProgress(
      catalogVersion: 3,
      puzzleIndex: index,
      puzzleId: r.puzzle!.id,
      signature: r.generation!.metrics!.structuralSignature,
      letters: {'${p.row},${p.column}': 'A'},
      completedThrough: completed,
      schemaVersion: schema,
      history: [
        for (var i = 1; i < index; i++)
          ProgressHistoryEntry(
            puzzleIndex: i,
            wordIds: results[i - 1].toHistory().words.keys.toList(),
          ),
      ],
    ).encode();
  }

  Future<PuzzleSession> restore(
    MemoryPuzzleProgressStore store,
    _Spy spy, {
    int? dev,
  }) async {
    final s = await PuzzleSession.restore(
      store: store,
      generator: spy,
      developmentIndex: dev,
    );
    addTearDown(s.dispose);
    return s;
  }

  void solve(PuzzleSession s) {
    final letters = <GridPosition, String>{
      for (final a in s.current.puzzle!.answers)
        for (var i = 0; i < a.length; i++) a.positions[i]: a.solution[i],
    };
    s.updateLetters(letters);
    s.recognizeCompletion();
  }

  test(
    'schema 3 restores only current index with exact resolved prefix',
    () async {
      final spy = _Spy(results);
      final store = MemoryPuzzleProgressStore(record(3));
      final s = await restore(store, spy);
      expect(spy.calls, [3]);
      expect(s.current.puzzleIndex, 3);
      expect(s.completedThrough, 2);
      expect(s.letters.values, ['A']);
      expect(spy.received.single.map((h) => h.puzzleIndex), [1, 2]);
      for (var i = 0; i < 2; i++) {
        expect(spy.received.single[i].words, results[i].toHistory().words);
      }
    },
  );
  test('old schema 2 replays once, preserves progress and immediately saves schema 3', () async {
    final spy = _Spy(results);
    final store = MemoryPuzzleProgressStore(record(2, schema: 2, completed: 2));
    final migrated = await restore(store, spy);
    expect(spy.calls, [1, 2]);
    expect(migrated.completedThrough, 2);
    expect(migrated.letters.values, ['A']);
    final saved = PuzzleProgress.decode(store.record!);
    expect(saved.schemaVersion, 5);
    expect(saved.history.map((h) => h.puzzleIndex), [1]);
    expect(saved.history.single.wordIds, hasLength(10));
    expect(jsonDecode(store.record!)['history'].single.keys.toSet(), {
      'puzzleIndex',
      'wordIds',
    });
    final secondSpy = _Spy(results);
    await restore(store, secondSpy);
    expect(secondSpy.calls, [2]);
  });
  test(
    'invalid history and unknown/duplicate IDs fail before current generation',
    () async {
      for (var variant = 0; variant < 7; variant++) {
        final data = jsonDecode(record(3)) as Map<String, dynamic>;
        final history = data['history'] as List;
        switch (variant) {
          case 0:
            data.remove('history');
          case 1:
            history.removeLast();
          case 2:
            history.first['puzzleIndex'] = 2;
          case 3:
            history.first['wordIds'][0] = 'unknown';
          case 4:
            history.first['wordIds'][0] = history.first['wordIds'][1];
          case 5:
            history.first['wordIds'].removeLast();
          case 6:
            history.first['wordIds'][0] = 42;
        }
        final spy = _Spy(results);
        final store = MemoryPuzzleProgressStore(jsonEncode(data));
        final s = await restore(store, spy);
        expect(spy.calls, [1]);
        expect(s.current.puzzleIndex, 1);
        expect(s.completedThrough, 0);
        expect(store.record, isNull);
      }
    },
  );
  test(
    'solved current has prefix ending N-1 and restore performs no replay',
    () async {
      final store = MemoryPuzzleProgressStore(record(3));
      final s = await restore(store, _Spy(results));
      solve(s);
      await s.flush;
      final saved = PuzzleProgress.decode(store.record!);
      expect(saved.completedThrough, 3);
      expect(saved.history.map((h) => h.puzzleIndex), [1, 2]);
      final spy = _Spy(results);
      final restored = await restore(store, spy);
      expect(spy.calls, [3]);
      expect(restored.letters, s.letters);
      expect(restored.completedThrough, 3);
    },
  );
  test(
    'advancing appends current exactly once in compact stored history',
    () async {
      final store = MemoryPuzzleProgressStore(record(2));
      final spy = _Spy(results);
      final s = await restore(store, spy);
      solve(s);
      s.nextPuzzle();
      await s.flush;
      final saved = PuzzleProgress.decode(store.record!);
      expect(saved.puzzleIndex, 3);
      expect(saved.completedThrough, 2);
      expect(saved.letters, isEmpty);
      expect(saved.history.map((h) => h.puzzleIndex), [1, 2]);
      expect(
        saved.history.last.wordIds.toSet(),
        results[1].toHistory().words.keys.toSet(),
      );
      expect(spy.calls, [2, 3]);
      expect(spy.received.last.map((h) => h.puzzleIndex), [1, 2]);
    },
  );
  test('failed next preserves previous history and completed save', () async {
    final store = MemoryPuzzleProgressStore(record(2));
    final s = await restore(store, _Spy(results, failAt: 3));
    solve(s);
    await s.flush;
    final old = store.record;
    s.nextPuzzle();
    await s.flush;
    expect(s.current.isSuccess, isFalse);
    expect(store.record, old);
    expect(
      PuzzleProgress.decode(store.record!).history.map((h) => h.puzzleIndex),
      [1],
    );
  });
  test('development replay remains isolated from player history', () async {
    final store = MemoryPuzzleProgressStore(record(2));
    final old = store.record;
    final spy = _Spy(results);
    final s = await restore(store, spy, dev: 2);
    expect(spy.calls, [1, 2]);
    solve(s);
    s.nextPuzzle();
    await s.flush;
    expect(store.record, old);
    expect(store.writes, 0);
  });
}
