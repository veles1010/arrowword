import 'dart:convert';

import 'package:arrowword/app/app.dart';
import 'package:arrowword/app/puzzle_progress_store.dart';
import 'package:arrowword/app/puzzle_session.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

class _Fixtures extends PuzzleSequenceGenerator {
  _Fixtures(this.results, {this.fail = false})
    : super(prototypeCatalogue, prototypeSequenceConfig);
  final List<SequencePuzzleResult> results;
  final bool fail;
  @override
  SequencePuzzleResult generateNext({
    required int puzzleIndex,
    List<PuzzleHistoryEntry> history = const [],
  }) {
    if (fail && puzzleIndex == 2) {
      return SequencePuzzleResult(
        puzzleIndex: 2,
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
    ).generateRange(count: 2).puzzles,
  );
  Map<GridPosition, String> solution(PuzzleSession s) => {
    for (final answer in s.current.puzzle!.answers)
      for (var i = 0; i < answer.length; i++)
        answer.positions[i]: answer.solution[i],
  };
  Future<PuzzleSession> open(
    MemoryPuzzleProgressStore store, {
    int? dev,
    bool fail = false,
  }) async {
    final s = await PuzzleSession.restore(
      store: store,
      generator: _Fixtures(results, fail: fail),
      developmentIndex: dev,
    );
    addTearDown(s.dispose);
    return s;
  }

  String record(int index, {int? completed}) {
    final r = results[index - 1];
    final p = r.puzzle!.answers.first.start;
    return PuzzleProgress(
      catalogVersion: 3,
      puzzleIndex: index,
      puzzleId: r.puzzle!.id,
      signature: r.generation!.metrics!.structuralSignature,
      letters: {'${p.row},${p.column}': 'A'},
      completedThrough: completed,
      history: [
        for (var i = 1; i < index; i++)
          ProgressHistoryEntry(
            puzzleIndex: i,
            wordIds: results[i - 1].puzzle!.answers.map((a) => a.id).toList(),
          ),
      ],
    ).encode();
  }

  test('fresh and partial states do not mark completion, even correct letters need recognition', () async {
    final store = MemoryPuzzleProgressStore();
    final s = await open(store);
    expect(s.completedThrough, 0);
    final p = s.current.puzzle!.answers.first.start;
    s.updateLetters({p: 'A'});
    s.recognizeCompletion();
    expect(s.completedThrough, 0);
    s.updateLetters(solution(s));
    await s.flush;
    expect(s.completedThrough, 0);
    expect(PuzzleProgress.decode(store.record!).completedThrough, 0);
    s.recognizeCompletion();
    await s.flush;
    expect(s.completedThrough, 1);
    expect(PuzzleProgress.decode(store.record!).completedThrough, 1);
  });
  test('schema 1 migration infers N-1 and preserves valid letters', () async {
    for (final index in [1, 2]) {
      final data = jsonDecode(record(index)) as Map<String, dynamic>;
      data['schemaVersion'] = 1;
      data.remove('completedThrough');
      final store = MemoryPuzzleProgressStore(jsonEncode(data));
      final s = await open(store);
      await s.flush;
      expect(s.current.puzzleIndex, index);
      expect(s.completedThrough, index - 1);
      expect(s.letters.values, ['A']);
      expect(jsonDecode(store.record!)['schemaVersion'], 3);
      expect(PuzzleProgress.decode(store.record!).letters, data['letters']);
    }
    final old = jsonDecode(record(1)) as Map<String, dynamic>;
    old['schemaVersion'] = 1;
    old['puzzleIndex'] = 17;
    old.remove('completedThrough');
    expect(PuzzleProgress.decode(jsonEncode(old)).completedThrough, 16);
  });
  test('recognized solved state survives restart before Next and advances atomically', () async {
    final store = MemoryPuzzleProgressStore();
    final s = await open(store);
    final solved = solution(s);
    s.updateLetters(solved);
    s.recognizeCompletion();
    await s.flush;
    final restored = await open(store);
    expect(restored.current.puzzleIndex, 1);
    expect(restored.completedThrough, 1);
    expect(restored.letters, solved);
    restored.nextPuzzle();
    await restored.flush;
    final next = await open(store);
    expect(next.current.puzzleIndex, 2);
    expect(next.completedThrough, 1);
    expect(next.letters, isEmpty);
  });
  test(
    'resetting recognized puzzle does not erase durable completion',
    () async {
      final store = MemoryPuzzleProgressStore();
      final s = await open(store);
      s.updateLetters(solution(s));
      s.recognizeCompletion();
      s.updateLetters({});
      await s.flush;
      final restored = await open(store);
      expect(restored.completedThrough, 1);
      expect(restored.letters, isEmpty);
    },
  );
  test('impossible schema 2 progression resets safely', () async {
    for (final count in [-1, 0, 3, '1']) {
      final data = jsonDecode(record(2)) as Map<String, dynamic>;
      data['completedThrough'] = count;
      final store = MemoryPuzzleProgressStore(jsonEncode(data));
      final s = await open(store);
      expect(s.current.puzzleIndex, 1);
      expect(s.completedThrough, 0);
      expect(store.record, isNull);
    }
  });
  test(
    'development completion cannot alter normal completion history',
    () async {
      final store = MemoryPuzzleProgressStore(record(1, completed: 1));
      final original = store.record;
      final dev = await open(store, dev: 1);
      dev.updateLetters(solution(dev));
      dev.recognizeCompletion();
      dev.nextPuzzle();
      await dev.flush;
      expect(store.record, original);
      expect((await open(store)).completedThrough, 1);
    },
  );
  test('failed next generation preserves completed save and letters', () async {
    final store = MemoryPuzzleProgressStore();
    final s = await open(store, fail: true);
    s.updateLetters(solution(s));
    s.recognizeCompletion();
    await s.flush;
    final saved = store.record;
    s.nextPuzzle();
    await s.flush;
    expect(s.current.isSuccess, isFalse);
    expect(store.record, saved);
    final restored = await open(store);
    expect(restored.current.puzzleIndex, 1);
    expect(restored.completedThrough, 1);
    expect(restored.letters, isNotEmpty);
  });
  testWidgets('Home shows fresh and recognized contiguous completion count', (
    tester,
  ) async {
    final s = await open(MemoryPuzzleProgressStore());
    await tester.pumpWidget(ArrowwordApp(session: s));
    expect(find.text('Henüz tamamlanan bulmaca yok'), findsOneWidget);
    s.updateLetters(solution(s));
    s.recognizeCompletion();
    await tester.pump();
    expect(find.text('1 bulmaca tamamlandı'), findsOneWidget);
    s.nextPuzzle();
    await tester.pump();
    expect(find.text('Bulmaca 2'), findsOneWidget);
    expect(find.text('1 bulmaca tamamlandı'), findsOneWidget);
  });
}
