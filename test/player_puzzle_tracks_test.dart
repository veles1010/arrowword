import 'dart:async';

import 'package:arrowword/app/app.dart';
import 'package:arrowword/app/app_shell.dart';
import 'package:arrowword/app/daily_progress_store.dart';
import 'package:arrowword/app/daily_session.dart';
import 'package:arrowword/app/player_puzzle_tracks.dart';
import 'package:arrowword/app/player_statistics.dart';
import 'package:arrowword/app/puzzle_difficulty_selector.dart';
import 'package:arrowword/app/puzzle_progress_store.dart';
import 'package:arrowword/app/puzzle_session.dart';
import 'package:arrowword/app/puzzle_track.dart';
import 'package:arrowword/app/puzzle_replay_attempt.dart';
import 'package:arrowword/app/puzzle_replay_screen.dart';
import 'package:arrowword/app/statistics_screen.dart';
import 'package:arrowword/features/puzzle/ads/rewarded_hint_ad_service.dart';
import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/daily/daily_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_difficulty.dart';
import 'package:arrowword/features/puzzle/presentation/puzzle_screen.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Generator extends PuzzleSequenceGenerator {
  _Generator(super.catalogue, super.config, this.fixtures);
  final List<SequencePuzzleResult> fixtures;
  final List<int> calls = [];
  final List<List<PuzzleHistoryEntry>> prefixes = [];
  bool fail = false;
  @override
  SequencePuzzleResult generateNext({
    required int puzzleIndex,
    List<PuzzleHistoryEntry> history = const [],
  }) {
    calls.add(puzzleIndex);
    prefixes.add(history.toList());
    if (fail) {
      return SequencePuzzleResult(
        puzzleIndex: puzzleIndex,
        seed: derivePuzzleSeed(config.baseSeed, puzzleIndex),
        catalogVersion: catalogue.version,
        pool: fixtures.first.pool,
        failureReason: 'Injected bounded generation failure',
      );
    }
    return fixtures[puzzleIndex - 1];
  }
}

class _Store extends MemoryPuzzleProgressStore {
  _Store([super.record]);
  int reads = 0, clears = 0;
  Completer<void>? readGate;
  @override
  Future<String?> read() async {
    reads++;
    if (readGate != null) await readGate!.future;
    return super.read();
  }

  @override
  Future<void> clear() async {
    clears++;
    await super.clear();
  }
}

class _Harness {
  _Harness(
    this.fixtures, {
    String? last,
    Map<PuzzleDifficulty, String> saved = const {},
  }) : last = MemoryLastPuzzleDifficultyStore(last) {
    for (final d in PuzzleDifficulty.values) {
      final g = PuzzleTrackConfiguration.forDifficulty(d).createGenerator!();
      generators[d] = _Generator(g.catalogue, g.config, fixtures[d]!);
      stores[d] = _Store(saved[d]);
      providerCalls[d] = 0;
    }
  }
  final Map<PuzzleDifficulty, List<SequencePuzzleResult>> fixtures;
  final MemoryLastPuzzleDifficultyStore last;
  final stores = <PuzzleDifficulty, _Store>{};
  final generators = <PuzzleDifficulty, _Generator>{};
  final providerCalls = <PuzzleDifficulty, int>{};
  late PlayerPuzzleTracks library;
  Future<void> restore() async {
    library = await PlayerPuzzleTracks.restore(
      lastStore: last,
      tracks: {
        for (final d in PuzzleDifficulty.values)
          d: PuzzleTrack(
            configuration: PuzzleTrackConfiguration(
              difficulty: d,
              createGenerator: () {
                providerCalls[d] = providerCalls[d]! + 1;
                return generators[d]!;
              },
            ),
            store: stores[d],
          ),
      },
    );
  }
}

Map<GridPosition, String> _solution(Puzzle puzzle) => {
  for (final a in puzzle.answers)
    for (var i = 0; i < a.length; i++) a.positions[i]: a.solution[i],
};
void _complete(PuzzleSession session) {
  session.updateAttemptProgress(
    _solution(session.current.puzzle!),
    {},
    const Duration(seconds: 80),
    1,
  );
  session.recognizeCompletion();
}

void main() {
  final fixtures = <PuzzleDifficulty, List<SequencePuzzleResult>>{};
  setUpAll(() {
    for (final d in PuzzleDifficulty.values) {
      fixtures[d] = PuzzleTrackConfiguration.forDifficulty(d).createGenerator!()
          .generateRange(count: 2)
          .puzzles;
      expect(fixtures[d], hasLength(2));
    }
  });
  Future<_Harness> harness({
    String? last,
    Map<PuzzleDifficulty, String> saved = const {},
  }) async {
    final h = _Harness(fixtures, last: last, saved: saved);
    await h.restore();
    addTearDown(h.library.dispose);
    return h;
  }

  for (final value in [null, '', 'garbage', 'Kolay']) {
    test(
      'legacy/invalid last difficulty $value defaults Easy without rewriting progression',
      () async {
        final h = await harness(last: value);
        expect(h.library.lastPlayed, PuzzleDifficulty.easy);
        expect(h.last.writes, 0);
        expect(h.providerCalls.values, everyElement(0));
        expect(h.stores.values.map((s) => s.writes), everyElement(0));
      },
    );
  }
  for (final d in PuzzleDifficulty.values) {
    test(
      '${d.id} current opens lazily and becomes last played; sessions are cached',
      () async {
        final h = await harness();
        final session = await h.library.open(d, markPlayed: true);
        await h.library.flush;
        expect(session.difficulty, d);
        expect(session.current.puzzleIndex, 1);
        expect(session.current.puzzle!.id, fixtures[d]!.first.puzzle!.id);
        expect(h.library.lastPlayed, d);
        expect(h.last.value, d.id);
        expect(identical(await h.library.open(d), session), isTrue);
        expect(h.generators[d]!.calls, [1]);
        for (final other in PuzzleDifficulty.values.where((v) => v != d)) {
          expect(h.providerCalls[other], 0);
          expect(h.stores[other]!.writes, 0);
        }
      },
    );
    test(
      '${d.id} letters, hints, elapsed and checks survive switching and restart',
      () async {
        final h = await harness();
        final session = await h.library.open(d, markPlayed: true);
        final positions = _solution(session.current.puzzle!).keys.toList();
        session.updateAttemptProgress(
          {positions[1]: 'Z'},
          {positions[0]},
          const Duration(seconds: 47),
          2,
        );
        await session.flush;
        final saved = h.stores[d]!.record!;
        for (final other in PuzzleDifficulty.values.where((v) => v != d)) {
          await h.library.open(other, markPlayed: true);
        }
        expect(identical(await h.library.open(d), session), isTrue);
        final restarted = await harness(last: d.id, saved: {d: saved});
        expect(restarted.providerCalls.values, everyElement(0));
        final restored = await restarted.library.open(d);
        expect(restored.letters, session.letters);
        expect(restored.revealedCells, {positions[0]});
        expect(restored.hintsUsed, 1);
        expect(restored.elapsed.inSeconds, 47);
        expect(restored.wrongChecks, 2);
        expect(restored.current.puzzle!.id, session.current.puzzle!.id);
        expect(restarted.stores[d]!.record, saved);
        expect(restarted.stores[d]!.writes, 0);
      },
    );
    test(
      '${d.id} completion/Next/score/history update only their owning track',
      () async {
        final h = await harness();
        final session = await h.library.open(d);
        _complete(session);
        await session.flush;
        expect(h.library.summary(d).completedThrough, 1);
        expect(h.library.summary(d).scores[1]!.score, 1375);
        session.nextPuzzle();
        await session.flush;
        expect(session.difficulty, d);
        expect(session.current.puzzleIndex, 2);
        expect(session.completedThrough, 1);
        expect(session.letters, isEmpty);
        expect(session.hintsUsed, 0);
        expect(session.elapsed, Duration.zero);
        expect(session.wrongChecks, 0);
        expect(session.history.map((p) => p.puzzleIndex), [1, 2]);
        expect(
          h.generators[d]!.prefixes.last.single.words,
          fixtures[d]!.first.toHistory().words,
        );
        final saved = PuzzleProgress.decode(h.stores[d]!.record!);
        expect(saved.schemaVersion, 5);
        expect(saved.history, hasLength(1));
        for (final other in PuzzleDifficulty.values.where((v) => v != d)) {
          expect(h.library.summary(other).completedThrough, 0);
          expect(h.library.summary(other).scores, isEmpty);
          expect(h.stores[other]!.record, isNull);
        }
      },
    );
    test(
      '${d.id} replay is exact, does not change last played or current attempt, updates only best',
      () async {
        final h = await harness(last: 'easy');
        final session = await h.library.open(d);
        _complete(session);
        session.nextPuzzle();
        final cell = session.current.puzzle!.answers.first.start;
        session.updateAttemptProgress(
          {cell: 'Z'},
          {cell},
          const Duration(seconds: 59),
          3,
        );
        await session.flush;
        final oldLetters = session.letters,
            oldHistory = session.history.toList();
        final replay = PuzzleReplayAttempt(session: session, puzzleIndex: 1);
        expect(replay.generation.puzzle!.id, fixtures[d]!.first.puzzle!.id);
        expect(
          replay.generation.generation!.metrics!.structuralSignature,
          fixtures[d]!.first.generation!.metrics!.structuralSignature,
        );
        expect(h.generators[d]!.calls, [1, 2, 1]);
        expect(h.generators[d]!.prefixes.last, isEmpty);
        replay.updateProgress(
          _solution(replay.generation.puzzle!),
          {},
          const Duration(seconds: 70),
          0,
        );
        replay.complete();
        await session.flush;
        expect(session.completedScores[1]!.score, 1400);
        expect(session.current.puzzleIndex, 2);
        expect(session.completedThrough, 1);
        expect(session.letters, oldLetters);
        expect(session.revealedCells, {cell});
        expect(session.elapsed.inSeconds, 59);
        expect(session.wrongChecks, 3);
        expect(session.history, oldHistory);
        expect(h.library.lastPlayed, PuzzleDifficulty.easy);
        expect(h.last.writes, 0);
        for (final other in PuzzleDifficulty.values.where((v) => v != d)) {
          expect(h.library.summary(other).scores, isEmpty);
        }
      },
    );
  }

  test('metadata-only restore preserves schema-5 Easy letters, score, history and exact bytes', () async {
    final seed = await harness();
    final easy = await seed.library.open(PuzzleDifficulty.easy);
    _complete(easy);
    easy.nextPuzzle();
    final cell = easy.current.puzzle!.answers.first.start;
    easy.updateAttemptProgress(
      {cell: 'Z'},
      {cell},
      const Duration(seconds: 90),
      4,
    );
    await easy.flush;
    final bytes = seed.stores[PuzzleDifficulty.easy]!.record!;
    final h = await harness(saved: {PuzzleDifficulty.easy: bytes});
    expect(h.library.summary(PuzzleDifficulty.easy).index, 2);
    expect(h.library.summary(PuzzleDifficulty.easy).completedThrough, 1);
    expect(h.library.summary(PuzzleDifficulty.easy).scores[1]!.score, 1375);
    expect(h.providerCalls.values, everyElement(0));
    final restored = await h.library.open(PuzzleDifficulty.easy);
    expect(restored.letters, easy.letters);
    expect(restored.revealedCells, easy.revealedCells);
    expect(restored.elapsed, easy.elapsed);
    expect(restored.wrongChecks, 4);
    expect(h.stores[PuzzleDifficulty.easy]!.record, bytes);
    expect(h.stores[PuzzleDifficulty.easy]!.writes, 0);
    expect(h.generators[PuzzleDifficulty.easy]!.calls, [2]);
  });

  test(
    'bounded restore failure never clears a valid track save and can retry',
    () async {
      final seed = await harness();
      final session = await seed.library.open(PuzzleDifficulty.medium);
      session.updateLetters({session.current.puzzle!.answers.first.start: 'Z'});
      await session.flush;
      final bytes = seed.stores[PuzzleDifficulty.medium]!.record!;
      final h = await harness(saved: {PuzzleDifficulty.medium: bytes});
      h.generators[PuzzleDifficulty.medium]!.fail = true;
      final failed = await h.library.open(
        PuzzleDifficulty.medium,
        markPlayed: true,
      );
      expect(failed.current.isSuccess, isFalse);
      failed.dispose();
      expect(h.stores[PuzzleDifficulty.medium]!.record, bytes);
      expect(h.stores[PuzzleDifficulty.medium]!.clears, 0);
      expect(h.last.writes, 0);
      h.generators[PuzzleDifficulty.medium]!.fail = false;
      final retry = await h.library.open(
        PuzzleDifficulty.medium,
        markPlayed: true,
      );
      expect(retry.current.isSuccess, isTrue);
      expect(retry.letters, session.letters);
    },
  );

  test(
    'statistics are derived separately and never blend track scores',
    () async {
      final h = await harness();
      final medium = await h.library.open(PuzzleDifficulty.medium);
      _complete(medium);
      for (final d in PuzzleDifficulty.values) {
        final summary = h.library.summary(d);
        final stats = PlayerStatistics.fromScores(
          completedThrough: summary.completedThrough,
          scores: summary.scores.values,
        );
        expect(stats.totalScore, d == PuzzleDifficulty.medium ? 1375 : 0);
        expect(stats.scoredPuzzleCount, d == PuzzleDifficulty.medium ? 1 : 0);
      }
    },
  );

  test(
    'simultaneous opens share one provider/current reconstruction',
    () async {
      final h = await harness();
      final gate = Completer<void>();
      h.stores[PuzzleDifficulty.hard]!.readGate = gate;
      final a = h.library.open(PuzzleDifficulty.hard);
      final b = h.library.open(PuzzleDifficulty.hard);
      expect(h.providerCalls[PuzzleDifficulty.hard], 1);
      gate.complete();
      expect(identical(await a, await b), isTrue);
      expect(h.generators[PuzzleDifficulty.hard]!.calls, [1]);
    },
  );

  test('Daily completion and its statistics cannot touch player track stores or last played', () async {
    final h = await harness(last: 'hard');
    final store = MemoryDailyProgressStore();
    final daily = await DailySession.restore(
      store: store,
      localNow: () => DateTime(2026, 10, 6),
      generator: (date) => DailyPuzzleGeneration.success(
        Puzzle(
          id: dailyPuzzleId(date),
          label: 'Günün Bulmacası',
          rowCount: 10,
          columnCount: 10,
          answers: fixtures[PuzzleDifficulty.easy]!.first.puzzle!.answers,
        ),
      ),
    );
    addTearDown(daily.dispose);
    final attempt = daily.openToday()!;
    attempt.updateProgress(
      _solution(attempt.generation.puzzle!),
      {},
      const Duration(seconds: 60),
      0,
    );
    attempt.complete();
    await daily.flush;
    expect(daily.statistics.totalCompletedDaily, 1);
    expect(daily.todayResult!.score, 1400);
    expect(h.library.lastPlayed, PuzzleDifficulty.hard);
    expect(h.last.writes, 0);
    expect(h.providerCalls.values, everyElement(0));
    expect(h.stores.values.map((s) => s.writes), everyElement(0));
    expect(h.library.summary(PuzzleDifficulty.hard).scores, isEmpty);
  });

  Future<_Harness> mount(
    WidgetTester tester, {
    String? last,
    bool dark = false,
  }) async {
    final h = (await tester.runAsync(() => harness(last: last)))!;
    await tester.pumpWidget(
      ArrowwordApp(
        tracks: h.library,
        rewardedAdFactory: () => FakeRewardedHintAdService(),
      ),
    );
    await tester.pumpAndSettle();
    return h;
  }

  Future<void> select(WidgetTester tester, PuzzleDifficulty difficulty) async {
    await tester.tap(
      find
          .descendant(
            of: find.byType(PuzzleDifficultySelector).hitTestable(),
            matching: find.text(difficulty.turkishLabel),
          )
          .first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> exit(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  testWidgets(
    'development direct-open cannot update last played or activate player providers',
    (tester) async {
      final h = (await tester.runAsync(() => harness(last: 'medium')))!;
      final dev = PuzzleSession(
        generator: h.generators[PuzzleDifficulty.hard],
        difficulty: PuzzleDifficulty.hard,
      );
      addTearDown(dev.dispose);
      await tester.pumpWidget(
        ArrowwordApp(
          session: dev,
          tracks: h.library,
          developmentOverride: true,
          rewardedAdFactory: () => FakeRewardedHintAdService(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Zor · Bulmaca 1'), findsOneWidget);
      expect(find.text('Geliştirme · İlerleme kaydedilmez'), findsOneWidget);
      expect(h.last.value, 'medium');
      expect(h.last.writes, 0);
      expect(h.providerCalls.values, everyElement(0));
      expect(h.stores.values.map((s) => s.writes), everyElement(0));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'no-defines production Home is Easy and no hidden track generates',
    (tester) async {
      final h = await mount(tester);
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.text('Kolay · Bulmaca 1'), findsOneWidget);
      expect(find.text('Başla').hitTestable(), findsOneWidget);
      expect(find.textContaining('Geliştirme'), findsNothing);
      expect(h.providerCalls.values, everyElement(0));
      await tester.tap(find.text('Zorluk Seç'));
      await tester.pumpAndSettle();
      for (final d in PuzzleDifficulty.values) {
        await select(tester, d);
      }
      expect(h.providerCalls.values, everyElement(0));
      expect(h.last.writes, 0);
      expect(
        tester
            .widget<InkWell>(
              find.byKey(const ValueKey('puzzle-tile-2')).hitTestable(),
            )
            .onTap,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final d in [PuzzleDifficulty.medium, PuzzleDifficulty.hard]) {
    testWidgets(
      '${d.id} saved Home index resumes via compact history without prefix replay',
      (tester) async {
        final h = (await tester.runAsync(() async {
          final seed = await harness();
          final session = await seed.library.open(d);
          _complete(session);
          session.nextPuzzle();
          session.updateLetters({
            session.current.puzzle!.answers.first.start: 'Z',
          });
          await session.flush;
          return harness(last: d.id, saved: {d: seed.stores[d]!.record!});
        }))!;
        await tester.pumpWidget(
          ArrowwordApp(
            tracks: h.library,
            rewardedAdFactory: () => FakeRewardedHintAdService(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('${d.turkishLabel} · Bulmaca 2'), findsOneWidget);
        expect(h.providerCalls.values, everyElement(0));
        await tester.tap(find.text('Devam Et').hitTestable());
        await tester.pumpAndSettle();
        expect(find.text('${d.turkishLabel} · Bulmaca 2'), findsOneWidget);
        expect(h.generators[d]!.calls, [2]);
        expect(
          tester.widget<PuzzleScreen>(find.byType(PuzzleScreen)).initialLetters,
          isNotEmpty,
        );
        await exit(tester);
        await tester.pumpWidget(const SizedBox());
      },
    );
    testWidgets(
      '${d.id} current tile opens its track, Next stays there, Back refreshes Home',
      (tester) async {
        final h = await mount(tester);
        await tester.tap(find.text('Zorluk Seç'));
        await tester.pumpAndSettle();
        await select(tester, d);
        await tester.tap(
          find.byKey(const ValueKey('puzzle-tile-1')).hitTestable(),
        );
        await tester.pumpAndSettle();
        expect(find.text('${d.turkishLabel} · Bulmaca 1'), findsOneWidget);
        expect(find.textContaining('Geliştirme'), findsNothing);
        final session = await tester.runAsync(() => h.library.open(d));
        for (final entry in _solution(session!.current.puzzle!).entries) {
          await tester.tap(
            find.byKey(ValueKey('cell-${entry.key.row}-${entry.key.column}')),
          );
          await tester.enterText(find.byType(TextField), entry.value);
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(find.text('Sonraki Bulmaca'), findsOneWidget);
        await tester.tap(find.text('Sonraki Bulmaca'));
        await tester.pumpAndSettle();
        expect(find.text('${d.turkishLabel} · Bulmaca 2'), findsOneWidget);
        await exit(tester);
        expect(find.byType(PuzzleScreen), findsNothing);
        expect(
          find.byKey(const ValueKey('puzzle-score-1')).hitTestable(),
          findsOneWidget,
        );
        await exit(tester); // non-Home shell returns Home
        expect(find.text('${d.turkishLabel} · Bulmaca 2'), findsOneWidget);
        expect(h.library.summary(PuzzleDifficulty.easy).index, 1);
        await tester.runAsync(() => h.library.flush);
        expect(h.last.value, d.id);
        await tester.pumpWidget(const SizedBox());
      },
    );
    testWidgets(
      '${d.id} last-played Home renders metadata and resumes only its track',
      (tester) async {
        final h = await mount(tester, last: d.id);
        expect(find.text('${d.turkishLabel} · Bulmaca 1'), findsOneWidget);
        expect(h.providerCalls.values, everyElement(0));
        await tester.tap(find.text('Başla').hitTestable());
        await tester.pumpAndSettle();
        expect(find.text('${d.turkishLabel} · Bulmaca 1'), findsOneWidget);
        expect(h.providerCalls[d], 1);
        expect(h.providerCalls[PuzzleDifficulty.easy], 0);
        await exit(tester);
        await tester.pumpWidget(const SizedBox());
      },
    );
    testWidgets(
      '${d.id} replay opens above progression and leaves last-played preference unchanged',
      (tester) async {
        final h = await mount(tester);
        final session = await tester.runAsync(() => h.library.open(d));
        _complete(session!);
        session.nextPuzzle();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Zorluk Seç'));
        await tester.pumpAndSettle();
        await select(tester, d);
        await tester.tap(
          find.byKey(const ValueKey('puzzle-tile-1')).hitTestable(),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PuzzleReplayScreen), findsOneWidget);
        expect(find.text('${d.turkishLabel} · Bulmaca 1'), findsOneWidget);
        expect(find.text('Tekrar Oyna'), findsOneWidget);
        expect(h.last.writes, 0);
        await exit(tester);
        expect(find.byType(PuzzleReplayScreen), findsNothing);
        expect(h.library.summary(d).index, 2);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'statistics selector shows only selected track and does not generate fresh tracks',
    (tester) async {
      final h = (await tester.runAsync(() => harness()))!;
      final medium = await tester.runAsync(
        () => h.library.open(PuzzleDifficulty.medium),
      );
      _complete(medium!);
      await tester.pumpWidget(
        MaterialApp(home: StatisticsScreen(tracks: h.library)),
      );
      await tester.pumpAndSettle();
      Future<void> expectTotal(String value) async {
        final card = find.byKey(const ValueKey('statistics-total'));
        expect(
          find.descendant(of: card, matching: find.text(value)),
          findsOneWidget,
        );
      }

      await expectTotal('0');
      await select(tester, PuzzleDifficulty.medium);
      await expectTotal('1375');
      await select(tester, PuzzleDifficulty.hard);
      await expectTotal('0');
      expect(h.providerCalls[PuzzleDifficulty.hard], 0);
      expect(h.providerCalls[PuzzleDifficulty.easy], 0);
      expect(h.last.writes, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'lazy open paints loading, reports failure safely, and retries only requested track',
    (tester) async {
      final h = await mount(tester, last: 'medium');
      final gate = Completer<void>();
      h.stores[PuzzleDifficulty.medium]!.readGate = gate;
      h.generators[PuzzleDifficulty.medium]!.fail = true;
      await tester.tap(find.text('Başla').hitTestable());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Bulmaca hazırlanıyor…'), findsOneWidget);
      expect(h.generators.values.expand((g) => g.calls), isEmpty);
      expect(h.last.writes, 0);
      gate.complete();
      await tester.pumpAndSettle();
      expect(
        find.text('Bulmaca şu anda hazırlanamadı. Tekrar deneyin.'),
        findsOneWidget,
      );
      expect(h.last.writes, 0);
      expect(h.stores[PuzzleDifficulty.medium]!.clears, 0);
      h.generators[PuzzleDifficulty.medium]!.fail = false;
      await tester.tap(find.text('Tekrar Dene'));
      await tester.pumpAndSettle();
      expect(find.text('Orta · Bulmaca 1'), findsOneWidget);
      expect(h.providerCalls[PuzzleDifficulty.easy], 0);
      expect(h.providerCalls[PuzzleDifficulty.hard], 0);
      await exit(tester);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('cancelled loading route never changes last played', (
    tester,
  ) async {
    final h = await mount(tester, last: 'medium');
    final gate = Completer<void>();
    h.stores[PuzzleDifficulty.medium]!.readGate = gate;
    await tester.tap(find.text('Başla').hitTestable());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Bulmaca hazırlanıyor…'), findsOneWidget);
    await exit(tester);
    gate.complete();
    await tester.pumpAndSettle();
    expect(h.last.writes, 0);
    expect(find.byType(PuzzleScreen), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  for (final dark in [false, true]) {
    testWidgets(
      'difficulty selector is accessible and compact at 1.5 scale, dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var selected = PuzzleDifficulty.easy;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              useMaterial3: true,
              brightness: dark ? Brightness.dark : Brightness.light,
            ),
            home: Scaffold(
              body: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: StatefulBuilder(
                    builder: (context, setState) => PuzzleDifficultySelector(
                      selected: selected,
                      onChanged: (d) => setState(() => selected = d),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final semantics = tester.ensureSemantics();
        await tester.tap(find.text('Zor'));
        await tester.pumpAndSettle();
        expect(selected, PuzzleDifficulty.hard);
        expect(
          tester
              .getSemantics(find.text('Zor'))
              .getSemanticsData()
              .flagsCollection
              .isSelected
              .toBoolOrNull(),
          isTrue,
        );
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }
}
