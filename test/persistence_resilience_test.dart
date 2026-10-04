import 'dart:convert';

import 'package:arrowword/app/daily_progress_store.dart';
import 'package:arrowword/app/daily_session.dart';
import 'package:arrowword/app/progress_json.dart';
import 'package:arrowword/app/puzzle_progress_store.dart';
import 'package:arrowword/app/puzzle_session.dart';
import 'package:arrowword/features/puzzle/daily/daily_puzzle.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_score.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_metrics.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

class _Generator extends PuzzleSequenceGenerator {
  _Generator(this.fixture) : super(prototypeCatalogue, prototypeSequenceConfig);
  final SequencePuzzleResult fixture;
  final calls = <int>[];
  final prefixes = <int>[];
  @override
  SequencePuzzleResult generateNext({
    required int puzzleIndex,
    List<PuzzleHistoryEntry> history = const [],
  }) {
    calls.add(puzzleIndex);
    prefixes.add(history.length);
    return SequencePuzzleResult(
      puzzleIndex: puzzleIndex,
      seed: fixture.seed,
      catalogVersion: 3,
      pool: fixture.pool,
      generation: fixture.generation,
      puzzle: Puzzle(
        id: 'fixture-$puzzleIndex',
        label: 'Fixture',
        rowCount: 10,
        columnCount: 10,
        answers: fixture.puzzle!.answers,
      ),
    );
  }
}

CompletedPuzzleScore _score(int index) => CompletedPuzzleScore.calculate(
  puzzleIndex: index,
  elapsedSeconds: 100,
  hintsUsed: 0,
  wrongChecks: 0,
);
DailyPuzzleScore _dailyScore(String date) => DailyPuzzleScore.calculate(
  dateKey: date,
  dailyPuzzleId: dailyPuzzleId(date),
  elapsedSeconds: 140,
  hintsUsed: 1,
  wrongChecks: 2,
);

void main() {
  late SequencePuzzleResult fixture;
  setUpAll(() => fixture = generatePrototypePuzzle());
  Map<String, dynamic> normalData() {
    final a = fixture.puzzle!.answers.first;
    return jsonDecode(
      PuzzleProgress(
        catalogVersion: 3,
        puzzleIndex: 3,
        puzzleId: 'fixture-3',
        signature: fixture.generation!.metrics!.structuralSignature,
        completedThrough: 2,
        letters: {'${a.positions[1].row},${a.positions[1].column}': 'Z'},
        revealedCells: ['${a.start.row},${a.start.column}'],
        hintsUsed: 1,
        elapsedMilliseconds: 12345,
        wrongChecks: 2,
        completedScores: {1: _score(1), 2: _score(2)},
        history: [
          for (var i = 1; i <= 2; i++)
            ProgressHistoryEntry(
              puzzleIndex: i,
              wordIds: fixture.puzzle!.answers.map((a) => a.id).toList(),
            ),
        ],
      ).encode(),
    ) as Map<String, dynamic>;
  }

  Puzzle dailyPuzzle(String date) => Puzzle(
    id: dailyPuzzleId(date),
    label: 'Daily',
    rowCount: 10,
    columnCount: 10,
    answers: fixture.puzzle!.answers,
  );
  Map<String, dynamic> dailyData() {
    final puzzle = dailyPuzzle('2026-10-06');
    final p = puzzle.answers.first.start;
    return jsonDecode(
      DailyProgress(
        attempt: DailyProgressAttempt(
          dateKey: '2026-10-06',
          puzzleId: puzzle.id,
          signature: puzzleStructuralSignature(puzzle),
          letters: {'${p.row},${p.column}': 'Z'},
          revealedCells: [],
          hintsUsed: 0,
          elapsedMilliseconds: 4321,
          wrongChecks: 1,
        ),
        results: {
          for (final day in ['2026-10-04', '2026-10-05']) day: _dailyScore(day),
        },
      ).encode(),
    ) as Map<String, dynamic>;
  }

  test(
    'duplicate scanner distinguishes escaped keys, arrays and string values',
    () {
      final decoded = ProgressJson(
        r'{"results":{"day":{"score":1,"sc\u006fre":2}},"history":[{"id":"{fake}"}],"text":"a:\"b"}',
      );
      expect(decoded.duplicates, [
        ['results', 'day', 'score'],
      ]);
      expect(ProgressJson('{"a":[{},1,"value",{"b":2}]}').duplicates, isEmpty);
      expect(() => ProgressJson('not json'), throwsFormatException);
    },
  );

  test(
    'bad optional normal score is dropped and healthy schema5 is rewritten',
    () async {
      final data = normalData();
      (data['completedScores'] as Map)['2']['score'] = -1;
      final store = MemoryPuzzleProgressStore(jsonEncode(data));
      final generator = _Generator(fixture);
      final session = await PuzzleSession.restore(
        store: store,
        generator: generator,
      );
      addTearDown(session.dispose);
      expect(generator.calls, [3]);
      expect(generator.prefixes, [2]);
      expect(session.current.puzzleIndex, 3);
      expect(session.completedThrough, 2);
      expect(session.elapsed.inMilliseconds, 12345);
      expect(session.wrongChecks, 2);
      expect(session.hintsUsed, 1);
      expect(session.letters.length, 2);
      expect(session.completedScores.keys, [1]);
      final cleaned = PuzzleProgress.decode(store.record!);
      expect(cleaned.schemaVersion, 5);
      expect(cleaned.needsRewrite, isFalse);
      expect(cleaned.history.length, 2);
      expect(store.writes, 1);
    },
  );

  for (final field in [
    'score',
    'elapsedSeconds',
    'hintsUsed',
    'wrongChecks',
    'scoringVersion',
    'puzzleIndex',
  ]) {
    test('normal invalid $field cannot destroy valid score/progression', () {
      final data = normalData();
      (data['completedScores'] as Map)['2'][field] = -1;
      final saved = PuzzleProgress.decode(jsonEncode(data));
      expect(saved.completedScores.keys, [1]);
      expect(saved.puzzleIndex, 3);
      expect(saved.completedThrough, 2);
      expect(saved.needsRewrite, isTrue);
    });
  }

  test('missing or malformed optional score map preserves progression', () {
    for (final value in [null, [], 'wrong', 3]) {
      final data = normalData()..['completedScores'] = value;
      final saved = PuzzleProgress.decode(jsonEncode(data));
      expect(saved.completedScores, isEmpty);
      expect(saved.puzzleIndex, 3);
      expect(saved.history.length, 2);
    }
    final data = normalData();
    (data['completedScores'] as Map)['02'] = _score(2).toJson();
    (data['completedScores'] as Map)['99'] = _score(99).toJson();
    expect(PuzzleProgress.decode(jsonEncode(data)).completedScores.keys, [
      1,
      2,
    ]);
  });

  test('ambiguous duplicate normal score is dropped rather than last-wins', () {
    final data = normalData()..remove('completedScores');
    final prefix = jsonEncode(data);
    final record =
        '${prefix.substring(0, prefix.length - 1)},"completedScores":{'
        '"1":${jsonEncode(_score(1).toJson())},"\\u0031":${jsonEncode(_score(1).toJson())},'
        '"2":${jsonEncode(_score(2).toJson())}}}';
    expect(PuzzleProgress.decode(record).completedScores.keys, [2]);
    expect(
      () => PuzzleProgress.decode('{"puzzleIndex":1,"puzzleIndex":3}'),
      throwsFormatException,
    );
  });

  test(
    'invalid normal core fields fail safely; sequence IDs remain strict',
    () async {
      final mutations = <void Function(Map<String, dynamic>)>[
        (d) => d.remove('puzzleId'),
        (d) => d['schemaVersion'] = 5.0,
        (d) => d['schemaVersion'] = 6,
        (d) => d['puzzleIndex'] = -1,
        (d) => d['puzzleIndex'] = '3',
        (d) => d['completedThrough'] = 0,
        (d) => d['completedThrough'] = 4,
        (d) => d['elapsedMilliseconds'] = -1,
        (d) => d['elapsedMilliseconds'] = 0x7fffffffffffffff,
        (d) => d['wrongChecks'] = -1,
        (d) => d['letters'] = [],
        (d) => (d['history'] as List)[0]['wordIds'][0] = 'unknown',
        (d) => (d['history'] as List)[0]['wordIds'][0] =
            (d['history'] as List)[0]['wordIds'][1],
      ];
      for (final mutate in mutations) {
        final data = normalData();
        mutate(data);
        final store = MemoryPuzzleProgressStore(jsonEncode(data));
        final generator = _Generator(fixture);
        final session = await PuzzleSession.restore(
          store: store,
          generator: generator,
        );
        addTearDown(session.dispose);
        expect(session.current.puzzleIndex, 1);
        expect(session.letters, isEmpty);
        expect(generator.calls, [1]);
        expect(store.record, isNull);
      }
    },
  );

  test('normal invalid coordinates are ignored without discarding valid letters/hints', () async {
    final data = normalData();
    (data['letters'] as Map).addAll(<String, dynamic>{
      '-1,0': 'A',
      '99,99': 'B',
      '0,0': 'C',
      'oops': 'D',
      '1,1': 'emoji',
    });
    final session = await PuzzleSession.restore(
      store: MemoryPuzzleProgressStore(jsonEncode(data)),
      generator: _Generator(fixture),
    );
    addTearDown(session.dispose);
    expect(session.current.puzzleIndex, 3);
    expect(session.letters.length, 2);
    expect(session.hintsUsed, 1);
  });

  for (final field in [
    'score',
    'elapsedSeconds',
    'hintsUsed',
    'wrongChecks',
    'scoringVersion',
    'dailySeedVersion',
    'dateKey',
    'dailyPuzzleId',
  ]) {
    test(
      'bad Daily result $field preserves other dates and active attempt',
      () async {
        final data = dailyData();
        (data['results'] as Map)['2026-10-05'][field] =
            field == 'dateKey' || field == 'dailyPuzzleId' ? 'bad' : -1;
        final store = MemoryDailyProgressStore(jsonEncode(data));
        var calls = 0;
        final session = await DailySession.restore(
          store: store,
          localNow: () => DateTime(2026, 10, 6),
          generator: (date) {
            calls++;
            return DailyPuzzleGeneration.success(dailyPuzzle(date));
          },
        );
        addTearDown(session.dispose);
        expect(calls, 0);
        expect(session.results.keys, ['2026-10-04']);
        expect(session.hasCurrentProgress, isTrue);
        final attempt = session.openToday()!;
        expect(attempt.elapsed.inMilliseconds, 4321);
        expect(attempt.wrongChecks, 1);
        expect(attempt.letters.length, 1);
        await session.flush;
        expect(DailyProgress.decode(store.record!).needsRewrite, isFalse);
      },
    );
  }

  test('overflowing Daily duration drops only the attempt', () {
    final data = dailyData();
    (data['attempt'] as Map)['elapsedMilliseconds'] = 0x7fffffffffffffff;
    final saved = DailyProgress.decode(jsonEncode(data));
    expect(saved.attempt, isNull);
    expect(saved.results.length, 2);
    expect(saved.needsRewrite, isTrue);
  });

  test('bad Daily attempt does not erase healthy historical results', () async {
    for (final field in [
      'dateKey',
      'elapsedMilliseconds',
      'revealedCells',
      'puzzleId',
      'dailySeedVersion',
    ]) {
      final data = dailyData();
      (data['attempt'] as Map)[field] =
          field == 'dateKey' || field == 'puzzleId' ? 'wrong' : -1;
      final store = MemoryDailyProgressStore(jsonEncode(data));
      final session = await DailySession.restore(
        store: store,
        localNow: () => DateTime(2026, 10, 6),
      );
      addTearDown(session.dispose);
      expect(session.results.keys, ['2026-10-04', '2026-10-05']);
      expect(session.hasCurrentProgress, isFalse);
      expect(DailyProgress.decode(store.record!).attempt, isNull);
    }
  });

  test('duplicate Daily dates and aliases never overwrite a valid immutable result', () {
    final good = jsonEncode(_dailyScore('2026-10-04').toJson());
    final ambiguous = jsonEncode(_dailyScore('2026-10-05').toJson());
    final saved = DailyProgress.decode(
      '{"schemaVersion":1,"attempt":null,"results":{'
      '"2026-10-04":$good,"2026-10-05":$ambiguous,"2026-10-05":$ambiguous,"alias":$good}}',
    );
    expect(saved.results.keys, ['2026-10-04']);
    expect(saved.needsRewrite, isTrue);
    expect(
      saved.results['2026-10-04']!.toJson(),
      _dailyScore('2026-10-04').toJson(),
    );
  });
}
