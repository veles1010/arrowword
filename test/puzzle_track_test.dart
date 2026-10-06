import 'dart:convert';

import 'package:arrowword/app/app.dart';
import 'package:arrowword/app/daily_progress_store.dart';
import 'package:arrowword/app/player_statistics.dart';
import 'package:arrowword/app/puzzle_progress_store.dart';
import 'package:arrowword/app/puzzle_replay_attempt.dart';
import 'package:arrowword/app/puzzle_session.dart';
import 'package:arrowword/app/puzzle_track.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_difficulty.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_score.dart';
import 'package:arrowword/features/puzzle/presentation/puzzle_screen.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

// Captured from clean 0638ea5 BEFORE the track refactor. Generation, catalogue,
// seed mixer and sequence configuration are unchanged, not used to derive expectations.
const _signatures = [
  'brother:BROTHER:1:2,5:1,5|exam:EXAM:1:5,3:4,3|face:FACE:0:7,2:7,1|farm:FARM:1:2,2:1,2|home:HOME:0:6,5:6,4|meat:MEAT:0:5,2:5,1|moon:MOON:1:6,7:5,7|rain:RAIN:0:3,5:3,4|room:ROOM:0:8,5:8,4|uncle:UNCLE:1:2,8:1,8',
  'aunt:AUNT:1:6,7:5,7|bird:BIRD:0:5,2:5,1|dirty:DIRTY:0:9,4:9,3|door:DOOR:0:3,2:3,1|four:FOUR:0:2,5:2,4|fridge:FRIDGE:1:2,5:1,5|goat:GOAT:0:6,5:6,4|knee:KNEE:0:7,2:7,1|onion:ONION:1:3,3:2,3|robot:ROBOT:1:2,8:1,8',
  'bear:BEAR:0:3,1:3,0|chess:CHESS:1:5,3:4,3|dolphin:DOLPHIN:0:1,2:1,1|dress:DRESS:1:1,2:0,2|large:LARGE:1:5,7:4,7|neck:NECK:1:1,8:0,8|pepper:PEPPER:0:7,2:7,1|school:SCHOOL:0:5,2:5,1|smile:SMILE:0:9,3:9,2|soap:SOAP:1:4,5:3,5',
];

class _Store extends MemoryPuzzleProgressStore {
  _Store([super.record]);
  int reads = 0, clears = 0;
  @override
  Future<String?> read() {
    reads++;
    return super.read();
  }

  @override
  Future<void> clear() {
    clears++;
    return super.clear();
  }
}

class _Spy extends PuzzleSequenceGenerator {
  _Spy(this.results) : super(prototypeCatalogue, prototypeSequenceConfig);
  final List<SequencePuzzleResult> results;
  final calls = <int>[];
  final prefixes = <List<PuzzleHistoryEntry>>[];
  @override
  SequencePuzzleResult generateNext({
    required int puzzleIndex,
    List<PuzzleHistoryEntry> history = const [],
  }) {
    calls.add(puzzleIndex);
    prefixes.add(List.of(history));
    return results[puzzleIndex - 1];
  }
}

void main() {
  late List<SequencePuzzleResult> results;
  setUpAll(() {
    final range = PuzzleTrackConfiguration.easy.createGenerator!()
        .generateRange(count: 3);
    expect(range.isSuccess, isTrue);
    results = range.puzzles;
  });

  String savedProgress() {
    final current = results[2];
    final answer = current.puzzle!.answers.first;
    final typed = answer.positions[0], hinted = answer.positions[1];
    return PuzzleProgress(
      catalogVersion: 3,
      puzzleIndex: 3,
      completedThrough: 2,
      puzzleId: current.puzzle!.id,
      signature: current.generation!.metrics!.structuralSignature,
      letters: {'${typed.row},${typed.column}': 'Z'},
      revealedCells: ['${hinted.row},${hinted.column}'],
      hintsUsed: 1,
      elapsedMilliseconds: 123456,
      wrongChecks: 3,
      completedScores: {
        for (var index = 1; index <= 2; index++)
          index: CompletedPuzzleScore.calculate(
            puzzleIndex: index,
            elapsedSeconds: 170,
            hintsUsed: 1,
            wrongChecks: 2,
          ),
      },
      history: [
        for (final previous in results.take(2))
          ProgressHistoryEntry(
            puzzleIndex: previous.puzzleIndex,
            wordIds: previous.toHistory().words.keys.toList()..sort(),
          ),
      ],
    ).encode();
  }

  Future<PuzzleSession> restore(_Store store, _Spy spy) async {
    final track = PuzzleTrack(
      configuration: PuzzleTrackConfiguration(
        difficulty: PuzzleDifficulty.easy,
        createGenerator: () => spy,
      ),
      store: store,
    );
    final session = await track.open();
    addTearDown(session.dispose);
    return session;
  }

  test(
    'progression IDs and Turkish labels are separate stable domain values',
    () {
      expect(PuzzleDifficulty.values.map((d) => d.id), [
        'easy',
        'medium',
        'hard',
      ]);
      expect(PuzzleDifficulty.values.map((d) => d.turkishLabel), [
        'Kolay',
        'Orta',
        'Zor',
      ]);
    },
  );

  test('legacy preference key is Easy; other score/history namespaces are disjoint', () {
    expect(
      SharedPreferencesPuzzleProgressStore().key,
      'arrowword.puzzle_progress',
    );
    expect(
      PuzzleDifficulty.values.map(SharedPreferencesPuzzleProgressStore.keyFor),
      [
        'arrowword.puzzle_progress',
        'arrowword.puzzle_progress.medium',
        'arrowword.puzzle_progress.hard',
      ],
    );
    expect(
      PuzzleDifficulty.values
          .map(SharedPreferencesPuzzleProgressStore.keyFor)
          .toSet(),
      hasLength(3),
    );
    expect(
      PuzzleDifficulty.values.map(SharedPreferencesPuzzleProgressStore.keyFor),
      isNot(contains(SharedPreferencesDailyProgressStore.key)),
    );
  });

  for (var index = 1; index <= 3; index++) {
    test(
      'Easy puzzle $index retains pre-refactor ID, seed, content and exact structure',
      () {
        final result = results[index - 1];
        expect(
          result.puzzle!.id,
          'generated-v3-${index.toString().padLeft(6, '0')}',
        );
        expect(result.seed, [3255270515, 3017514609, 4063561778][index - 1]);
        expect(
          result.generation!.metrics!.structuralSignature,
          _signatures[index - 1],
        );
        final words = {
          for (final part in _signatures[index - 1].split('|'))
            part.split(':')[0]: part.split(':')[1],
        };
        expect(result.toHistory().words, words);
      },
    );
  }

  test('existing seed lock at index 10 remains unchanged', () {
    expect(derivePuzzleSeed(prototypeBaseSeed, 10), 3356167200);
  });

  test('fresh Easy restore starts the same empty Puzzle 1', () async {
    final store = _Store(), spy = _Spy(results);
    final session = await restore(store, spy);
    expect(session.difficulty, PuzzleDifficulty.easy);
    expect(session.current.puzzle!.id, 'generated-v3-000001');
    expect(
      session.current.generation!.metrics!.structuralSignature,
      _signatures[0],
    );
    expect(session.completedThrough, 0);
    expect(session.letters, isEmpty);
    expect(session.revealedCells, isEmpty);
    expect(session.hintsUsed, 0);
    expect(session.wrongChecks, 0);
    expect(session.elapsed, Duration.zero);
    expect(session.completedScores, isEmpty);
    expect(store.writes, 0);
  });

  test(
    'historical Easy Puzzle 2 replay uses only its compact Puzzle 1 prefix',
    () async {
      final store = _Store(savedProgress()), spy = _Spy(results);
      final session = await restore(store, spy);
      final before = store.record;
      final replay = PuzzleReplayAttempt(session: session, puzzleIndex: 2);
      expect(replay.difficulty, PuzzleDifficulty.easy);
      expect(spy.calls, [3, 2]);
      expect(spy.prefixes.last.map((h) => h.puzzleIndex), [1]);
      expect(spy.prefixes.last.single.words, results[0].toHistory().words);
      expect(replay.generation.puzzle!.id, 'generated-v3-000002');
      expect(
        replay.generation.generation!.metrics!.structuralSignature,
        _signatures[1],
      );
      replay.updateProgress(
        {replay.generation.puzzle!.answers.first.start: 'A'},
        {},
        const Duration(seconds: 15),
        1,
      );
      await session.flush;
      expect(store.record, before);
      expect(store.writes, 0);
    },
  );

  test('schema 5 restores all legacy state as Easy without rewrite or prefix replay', () async {
    final raw = savedProgress();
    final store = _Store(raw), spy = _Spy(results);
    final session = await restore(store, spy);
    final saved = PuzzleProgress.decode(raw);
    expect(session.difficulty, PuzzleDifficulty.easy);
    expect(session.current.puzzleIndex, 3);
    expect(session.current.puzzle!.id, saved.puzzleId);
    expect(session.completedThrough, 2);
    final answer = session.current.puzzle!.answers.first;
    expect(session.letters[answer.positions[0]], 'Z');
    expect(session.revealedCells, {answer.positions[1]});
    expect(session.letters[answer.positions[1]], answer.solution[1]);
    expect(session.hintsUsed, 1);
    expect(session.wrongChecks, 3);
    expect(session.elapsed, const Duration(milliseconds: 123456));
    expect(
      session.completedScores.map((i, s) => MapEntry(i, s.toJson())),
      saved.completedScores.map((i, s) => MapEntry(i, s.toJson())),
    );
    expect(spy.calls, [3]);
    expect(spy.prefixes.single.map((h) => h.puzzleIndex), [1, 2]);
    for (var i = 0; i < 2; i++) {
      expect(spy.prefixes.single[i].words, results[i].toHistory().words);
      expect(session.history[i].words, results[i].toHistory().words);
    }
    await session.flush;
    expect(store.record, raw);
    expect(store.writes, 0);
    expect(store.clears, 0);
    expect(jsonDecode(store.record!)['schemaVersion'], 5);
    expect(jsonDecode(store.record!).containsKey('difficulty'), isFalse);
  });

  test('Easy replay uses its original compact prefix and updates only Easy best score', () async {
    final store = _Store(savedProgress()), spy = _Spy(results);
    final session = await restore(store, spy);
    final normalLetters = Map.of(session.letters),
        hints = Set.of(session.revealedCells);
    final history = session.history.map((h) => Map.of(h.words)).toList();
    final medium = _Store('corrupt future medium'),
        hard = _Store('corrupt future hard');
    final replay = PuzzleReplayAttempt(session: session, puzzleIndex: 1);
    expect(replay.difficulty, PuzzleDifficulty.easy);
    expect(spy.calls, [3, 1]);
    expect(spy.prefixes.last, isEmpty);
    expect(
      replay.generation.generation!.metrics!.structuralSignature,
      _signatures[0],
    );
    expect(replay.letters, isEmpty);
    expect(replay.hintsUsed, 0);
    expect(replay.elapsed, Duration.zero);
    expect(replay.wrongChecks, 0);
    replay.updateProgress(
      {
        for (final answer in replay.generation.puzzle!.answers)
          for (var i = 0; i < answer.length; i++)
            answer.positions[i]: answer.solution[i],
      },
      {},
      const Duration(seconds: 20),
      0,
    );
    replay.complete();
    expect(session.completedScores[1]!.score, 1400);
    final best = session.completedScores[1];
    replay.complete();
    expect(session.completedScores[1], same(best));
    expect(session.current.puzzleIndex, 3);
    expect(session.completedThrough, 2);
    expect(session.letters, normalLetters);
    expect(session.revealedCells, hints);
    expect(session.elapsed, const Duration(milliseconds: 123456));
    expect(session.wrongChecks, 3);
    expect(session.history.map((h) => h.words), history);
    await session.flush;
    expect(
      PuzzleProgress.decode(store.record!).completedScores[1]!.toJson(),
      best!.toJson(),
    );
    expect(medium.record, 'corrupt future medium');
    expect(hard.record, 'corrupt future hard');
  });

  for (final configuration in [
    PuzzleTrackConfiguration.medium,
    PuzzleTrackConfiguration.hard,
  ]) {
    test(
      '${configuration.difficulty.id} is dormant/fresh, not a fake Puzzle 1',
      () async {
        final defaultTrack = PuzzleTrack(configuration: configuration);
        expect(defaultTrack.isAvailable, isFalse);
        await expectLater(defaultTrack.open(), throwsUnsupportedError);
        final store = _Store();
        final track = PuzzleTrack(configuration: configuration, store: store);
        expect(track.isAvailable, isFalse);
        expect(track.store.difficulty, configuration.difficulty);
        await expectLater(track.open(), throwsUnsupportedError);
        expect(store.record, isNull);
        expect(store.reads, 0);
        expect(store.writes, 0);
        expect(store.clears, 0);
      },
    );
    test(
      'corrupt dormant ${configuration.difficulty.id} cannot reset Easy or Daily',
      () async {
        final easy = _Store(savedProgress());
        final future = _Store('not-json');
        final daily = MemoryDailyProgressStore('daily history bytes');
        final track = PuzzleTrack(configuration: configuration, store: future);
        await expectLater(track.open(), throwsUnsupportedError);
        final session = await restore(easy, _Spy(results));
        expect(session.current.puzzleIndex, 3);
        expect(easy.clears, 0);
        expect(future.record, 'not-json');
        expect(future.reads, 0);
        expect(daily.record, 'daily history bytes');
      },
    );
    test(
      '${configuration.difficulty.id} never falls back to the Easy generator',
      () {
        expect(
          () => PuzzleSession(difficulty: configuration.difficulty),
          throwsArgumentError,
        );
      },
    );
  }

  test('namespace mismatch is rejected before recovery can clear valid progression', () async {
    final underlying = _Store(savedProgress());
    final medium = PuzzleTrackProgressStore(
      difficulty: PuzzleDifficulty.medium,
      store: underlying,
    );
    final spy = _Spy(results);
    await expectLater(
      PuzzleSession.restore(store: medium, generator: spy),
      throwsArgumentError,
    );
    expect(underlying.reads, 0);
    expect(underlying.clears, 0);
    expect(spy.calls, isEmpty);
    expect(
      () => PuzzleTrack(
        configuration: PuzzleTrackConfiguration.hard,
        store: SharedPreferencesPuzzleProgressStore(),
      ),
      throwsArgumentError,
    );
  });

  test(
    'track stores isolate same-index score/history writes and clears',
    () async {
      // Opaque test payloads exercise namespaces, not imaginary Medium/Hard content.
      final easy = _Store(savedProgress()), medium = _Store(), hard = _Store();
      final stores = [
        PuzzleTrack(
          configuration: PuzzleTrackConfiguration.easy,
          store: easy,
        ).store,
        PuzzleTrack(
          configuration: PuzzleTrackConfiguration.medium,
          store: medium,
        ).store,
        PuzzleTrack(
          configuration: PuzzleTrackConfiguration.hard,
          store: hard,
        ).store,
      ];
      final normal = easy.record;
      await stores[1].write(
        jsonEncode({
          'completedScores': {'1': 700},
          'history': [],
        }),
      );
      await stores[2].write(
        jsonEncode({
          'completedScores': {'1': 900},
          'history': [],
        }),
      );
      expect(
        jsonDecode((await stores[1].read())!)['completedScores']['1'],
        700,
      );
      expect(
        jsonDecode((await stores[2].read())!)['completedScores']['1'],
        900,
      );
      expect(await stores[0].read(), normal);
      await stores[1].clear();
      expect(medium.record, isNull);
      expect(hard.record, isNotNull);
      expect(easy.record, normal);
      expect(
        PuzzleProgress.decode(easy.record!).history.map((h) => h.puzzleIndex),
        [1, 2],
      );
    },
  );

  test('Easy track lazily opens once without repeated generation', () async {
    final spy = _Spy(results), store = _Store(savedProgress());
    final track = PuzzleTrack(
      configuration: PuzzleTrackConfiguration(
        difficulty: PuzzleDifficulty.easy,
        createGenerator: () => spy,
      ),
      store: store,
    );
    expect(spy.calls, isEmpty);
    expect(store.reads, 0);
    final first = track.open(), second = track.open();
    expect(second, same(first));
    final session = await first;
    addTearDown(session.dispose);
    expect(await second, same(session));
    expect(spy.calls, [3]);
  });

  test(
    'development override remains Easy-only and never changes player save',
    () async {
      final store = _Store(savedProgress()), spy = _Spy(results);
      final original = store.record;
      final track = PuzzleTrack(
        configuration: PuzzleTrackConfiguration(
          difficulty: PuzzleDifficulty.easy,
          createGenerator: () => spy,
        ),
        store: store,
      );
      final session = await track.open(developmentIndex: 2);
      addTearDown(session.dispose);
      expect(session.difficulty, PuzzleDifficulty.easy);
      expect(session.current.puzzle!.id, 'generated-v3-000002');
      expect(
        session.current.generation!.metrics!.structuralSignature,
        _signatures[1],
      );
      session.updateAttemptProgress(
        {session.current.puzzle!.answers.first.start: 'Z'},
        {},
        const Duration(seconds: 30),
        2,
      );
      await session.flush;
      expect(store.reads, 0);
      expect(store.writes, 0);
      expect(store.record, original);
      await expectLater(
        PuzzleSession.restore(
          store: PuzzleTrackProgressStore(
            difficulty: PuzzleDifficulty.medium,
            store: _Store(),
          ),
          difficulty: PuzzleDifficulty.medium,
          generator: _Spy(results),
          developmentIndex: 2,
        ),
        throwsArgumentError,
      );
    },
  );

  testWidgets('Home/startup/statistics still use Easy without difficulty UI', (
    tester,
  ) async {
    final session = await restore(_Store(savedProgress()), _Spy(results));
    final statistics = PlayerStatistics.fromScores(
      completedThrough: session.completedThrough,
      scores: session.completedScores.values,
    );
    expect(statistics.scoredPuzzleCount, 2);
    await tester.pumpWidget(ArrowwordApp(session: session));
    expect(find.text('Bulmaca 3'), findsOneWidget);
    expect(find.text('Devam Et'), findsOneWidget);
    for (final label in ['Kolay', 'Orta', 'Zor']) {
      expect(find.text(label), findsNothing);
    }
    await tester.tap(find.text('Devam Et'));
    await tester.pumpAndSettle();
    final screen = tester.widget<PuzzleScreen>(find.byType(PuzzleScreen));
    expect(screen.puzzle.id, 'generated-v3-000003');
    expect(screen.initialLetters, session.letters);
    expect(screen.initialRevealedCells, session.revealedCells);
    expect(screen.initialWrongChecks, 3);
    expect(screen.initialElapsed, const Duration(milliseconds: 123456));
    expect(tester.takeException(), isNull);
  });
}
