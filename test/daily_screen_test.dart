import 'support/localized_back.dart';

import 'dart:async';

import 'package:arrowword/app/app.dart';
import 'package:arrowword/app/daily_progress_store.dart';
import 'package:arrowword/app/daily_puzzle_screen.dart';
import 'package:arrowword/app/daily_session.dart';
import 'package:arrowword/app/puzzle_progress_store.dart';
import 'package:arrowword/app/puzzle_session.dart';
import 'package:arrowword/app/statistics_screen.dart';
import 'package:arrowword/features/puzzle/ads/rewarded_hint_ad_service.dart';
import 'package:arrowword/features/puzzle/daily/daily_puzzle.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_score.dart';
import 'package:arrowword/features/puzzle/presentation/puzzle_screen.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _NormalFixtures extends PuzzleSequenceGenerator {
  _NormalFixtures(this.fixture)
    : super(prototypeCatalogue, prototypeSequenceConfig);
  final SequencePuzzleResult fixture;
  @override
  SequencePuzzleResult generateNext({
    required int puzzleIndex,
    List<PuzzleHistoryEntry> history = const [],
  }) => SequencePuzzleResult(
    puzzleIndex: puzzleIndex,
    seed: fixture.seed,
    catalogVersion: fixture.catalogVersion,
    pool: fixture.pool,
    generation: fixture.generation,
    puzzle: Puzzle(
      id: 'normal-$puzzleIndex',
      label: fixture.puzzle!.label,
      rowCount: 10,
      columnCount: 10,
      answers: fixture.puzzle!.answers,
    ),
  );
}

class _PendingAd extends FakeRewardedHintAdService {
  final reward = Completer<HintAdResult>();
  @override
  Future<HintAdResult> show() {
    shows++;
    return reward.future;
  }
}

Map<GridPosition, String> _solution(Puzzle puzzle) => {
  for (final a in puzzle.answers)
    for (var i = 0; i < a.length; i++) a.positions[i]: a.solution[i],
};

Future<void> _enter(WidgetTester tester, GridPosition p, String letter) async {
  await tester.tap(find.byKey(ValueKey('cell-${p.row}-${p.column}')));
  await tester.enterText(find.byType(TextField), letter);
  await tester.pump();
}

void main() {
  late SequencePuzzleResult fixture;
  setUpAll(() => fixture = generatePrototypePuzzle());
  DailyPuzzleGeneration generate(String date) => DailyPuzzleGeneration.success(
    Puzzle(
      id: dailyPuzzleId(date),
      label: 'Günlük Bulmaca',
      rowCount: 10,
      columnCount: 10,
      answers: fixture.puzzle!.answers,
    ),
  );
  PuzzleSession normal({PuzzleProgressStore? store}) {
    final s = PuzzleSession(
      generator: _NormalFixtures(fixture),
      startIndex: 2,
      store: store,
    );
    addTearDown(s.dispose);
    return s;
  }

  Future<DailySession> daily({
    DailyProgressStore? store,
    DateTime Function()? now,
    DailyPuzzleGeneration Function(String)? generator,
  }) async {
    final s = await DailySession.restore(
      store: store ?? MemoryDailyProgressStore(),
      localNow: now ?? () => DateTime(2026, 10, 4),
      generator: generator ?? generate,
    );
    addTearDown(s.dispose);
    return s;
  }

  testWidgets('Daily statistics stay separate from normal best scores', (
    tester,
  ) async {
    final d = await daily(
      store: MemoryDailyProgressStore(
        DailyProgress(
          results: {
            '2026-10-03': DailyPuzzleScore.calculate(
              dateKey: '2026-10-03',
              dailyPuzzleId: dailyPuzzleId('2026-10-03'),
              elapsedSeconds: 80,
              hintsUsed: 0,
              wrongChecks: 0,
            ),
          },
        ).encode(),
      ),
    );
    final n = normal();
    await tester.pumpWidget(
      MaterialApp(
        home: StatisticsScreen(session: n, dailySession: d),
      ),
    );
    final scroll = find.byType(SingleChildScrollView);
    await tester.drag(scroll, const Offset(0, -1500));
    await tester.pumpAndSettle();
    expect(find.text('Günlük tamamlanan'), findsOneWidget);
    expect(find.text('Güncel seri'), findsOneWidget);
    expect(d.statistics.currentStreak, 1);
    expect(d.statistics.totalCompletedDaily, 1);
    n.recordReplayScore(
      CompletedPuzzleScore.calculate(
        puzzleIndex: 1,
        elapsedSeconds: 60,
        hintsUsed: 0,
        wrongChecks: 0,
      ),
    );
    await tester.pump();
    expect(d.statistics.currentStreak, 1);
    expect(d.statistics.totalCompletedDaily, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unfinished Daily exposes no sharing or history replay', (
    tester,
  ) async {
    final d = await daily();
    await tester.pumpWidget(MaterialApp(home: DailyPuzzleScreen(session: d)));
    await tester.pumpAndSettle();
    expect(find.text('Paylaş'), findsNothing);
    expect(find.byType(PuzzleScreen), findsOneWidget);
  });

  Future<void> open(
    WidgetTester tester,
    DailySession s, {
    RewardedHintAdService? ad,
    Duration Function()? now,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [puzzleRouteObserver],
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => DailyPuzzleScreen(
                    session: s,
                    rewardedAdFactory: ad == null ? null : () => ad,
                    monotonicNow: now ?? () => Duration.zero,
                  ),
                ),
              ),
              child: const Text('Open Daily'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Daily'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Home Daily metadata is lazy; navigation and statistics return Home',
    (tester) async {
      var calls = 0;
      final d = await daily(
        generator: (date) {
          calls++;
          return generate(date);
        },
      );
      final n = normal();
      await tester.pumpWidget(ArrowwordApp(session: n, dailySession: d));
      expect(calls, 0);
      n.recordReplayScore(
        CompletedPuzzleScore.calculate(
          puzzleIndex: 1,
          elapsedSeconds: 100,
          hintsUsed: 0,
          wrongChecks: 0,
        ),
      );
      await tester.pump();
      expect(calls, 0);
      expect(find.text('Günün Bulmacası'), findsOneWidget);
      expect(find.text('Oyna'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('daily-action')));
      await tester.pumpAndSettle();
      expect(find.byType(PuzzleScreen), findsOneWidget);
      expect(calls, 1);
      n.recordReplayScore(
        CompletedPuzzleScore.calculate(
          puzzleIndex: 1,
          elapsedSeconds: 90,
          hintsUsed: 0,
          wrongChecks: 0,
        ),
      );
      await tester.pump();
      expect(calls, 1);
      await localizedPageBack(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('İstatistikler'));
      await tester.pumpAndSettle();
      expect(find.byType(StatisticsScreen), findsOneWidget);
      // Top-level tabs have no Back arrow; system Back returns Home.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Arrowword'), findsOneWidget);
      expect(n.current.puzzleIndex, 2);
    },
  );

  testWidgets(
    'Daily reward, check and timer resume; normal and replay scores stay untouched',
    (tester) async {
      final normalStore = MemoryPuzzleProgressStore();
      final n = normal(store: normalStore);
      final normalCell = n.current.puzzle!.answers.first.start;
      n.updateAttemptProgress(
        {normalCell: 'Z'},
        {normalCell},
        const Duration(seconds: 55),
        3,
      );
      n.recordReplayScore(
        CompletedPuzzleScore.calculate(
          puzzleIndex: 1,
          elapsedSeconds: 400,
          hintsUsed: 2,
          wrongChecks: 3,
        ),
      );
      await n.flush;
      final normalRecord = normalStore.record;
      final dailyStore = MemoryDailyProgressStore();
      final d = await daily(store: dailyStore);
      var time = Duration.zero;
      final ad = _PendingAd();
      await open(tester, d, ad: ad, now: () => time);
      final puzzle = tester
          .widget<PuzzleScreen>(find.byType(PuzzleScreen))
          .puzzle;
      final hint = puzzle.answers.first.start;
      final typed = _solution(puzzle).keys.firstWhere((p) => p != hint);
      time += const Duration(seconds: 20);
      await _enter(tester, typed, _solution(puzzle)[typed] == 'Z' ? 'X' : 'Z');
      await tester.tap(find.text('Kontrol Et'));
      await tester.pump();
      await tester.tap(find.byKey(ValueKey('cell-${hint.row}-${hint.column}')));
      await tester.pump();
      await tester.tap(find.text('Reklamla Harf Aç'));
      await tester.pump();
      time += const Duration(hours: 1);
      ad.reward.complete(HintAdResult.earned);
      await tester.pumpAndSettle();
      time += const Duration(seconds: 10);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      time += const Duration(hours: 2);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      time += const Duration(seconds: 5);
      await localizedPageBack(tester);
      await tester.pumpAndSettle();
      await d.flush;
      await n.flush;
      expect(normalStore.record, normalRecord);
      expect(n.current.puzzleIndex, 2);
      expect(n.completedThrough, 1);
      var generations = 0;
      final restored = await daily(
        store: dailyStore,
        generator: (date) {
          generations++;
          return generate(date);
        },
      );
      expect(generations, 0);
      await tester.pumpWidget(ArrowwordApp(session: n, dailySession: restored));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('daily-action')),
          matching: find.text('Devam Et'),
        ),
        findsOneWidget,
      );
      expect(generations, 0);
      await open(tester, restored);
      final screen = tester.widget<PuzzleScreen>(find.byType(PuzzleScreen));
      expect(screen.initialRevealedCells, {hint});
      expect(screen.initialWrongChecks, 1);
      expect(screen.initialElapsed, const Duration(seconds: 35));
      expect(screen.initialLetters[typed], isNotNull);
      await tester.enterText(find.byType(TextField), 'Z');
      await tester.tap(find.text('Temizle'));
      await tester.pump();
      expect(restored.openToday()!.revealedCells, {hint});
      expect(restored.openToday()!.letters, {hint: _solution(puzzle)[hint]!});
    },
  );

  testWidgets(
    'Daily completion is immutable, reopening result never starts a second attempt',
    (tester) async {
      var date = DateTime(2026, 10, 4);
      var calls = 0;
      final store = MemoryDailyProgressStore();
      final d = await daily(
        store: store,
        now: () => date,
        generator: (key) {
          calls++;
          return generate(key);
        },
      );
      final n = normal();
      await tester.pumpWidget(ArrowwordApp(session: n, dailySession: d));
      await tester.tap(find.byKey(const ValueKey('daily-action')));
      await tester.pumpAndSettle();
      final puzzle = tester
          .widget<PuzzleScreen>(find.byType(PuzzleScreen))
          .puzzle;
      for (final e in _solution(puzzle).entries) {
        await _enter(tester, e.key, e.value);
      }
      await tester.pumpAndSettle();
      expect(find.text('Günün bulmacası tamamlandı!'), findsOneWidget);
      expect(find.text('Sonraki Bulmaca'), findsNothing);
      expect(find.text('Ana Sayfaya Dön'), findsOneWidget);
      final score = d.todayResult!;
      await tester.tap(find.text('Ana Sayfaya Dön'));
      await tester.pumpAndSettle();
      expect(
        find.text('Bugün tamamlandı · ${score.score} puan'),
        findsOneWidget,
      );
      expect(find.text('Sonucu Gör'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('daily-action')));
      await tester.pumpAndSettle();
      expect(find.byType(DailyResultScreen), findsOneWidget);
      expect(find.byType(PuzzleScreen), findsNothing);
      expect(calls, 1);
      await localizedPageBack(tester);
      await tester.pumpAndSettle();
      await d.flush;
      final restored = await daily(store: store, now: () => date);
      await tester.pumpWidget(ArrowwordApp(session: n, dailySession: restored));
      expect(restored.todayResult!.toJson(), score.toJson());
      expect(n.completedScores, isEmpty);
      expect(n.completedThrough, 1);
      expect(n.current.puzzleIndex, 2);
      date = DateTime(2026, 10, 5);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('Oyna'), findsOneWidget);
      expect(restored.results.keys, ['2026-10-04']);
      await tester.tap(find.byKey(const ValueKey('daily-action')));
      await tester.pumpAndSettle();
      final next = tester.widget<PuzzleScreen>(find.byType(PuzzleScreen));
      expect(next.puzzle.id, dailyPuzzleId('2026-10-05'));
      expect(next.initialLetters, isEmpty);
    },
  );

  testWidgets('compact Home and Daily with keyboard have no overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final d = await daily();
    await tester.pumpWidget(ArrowwordApp(session: normal(), dailySession: d));
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const ValueKey('daily-action')));
    await tester.tap(find.byKey(const ValueKey('daily-action')));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Kontrol Et'), findsOneWidget);
  });

  testWidgets(
    'system back after Daily completion returns Home and locks result',
    (tester) async {
      final store = MemoryDailyProgressStore();
      final d = await daily(store: store);
      final n = normal();
      await tester.pumpWidget(ArrowwordApp(session: n, dailySession: d));
      await tester.tap(find.byKey(const ValueKey('daily-action')));
      await tester.pumpAndSettle();
      final puzzle = tester
          .widget<PuzzleScreen>(find.byType(PuzzleScreen))
          .puzzle;
      for (final entry in _solution(puzzle).entries) {
        await _enter(tester, entry.key, entry.value);
      }
      await tester.pumpAndSettle();
      expect(find.text('Günün bulmacası tamamlandı!'), findsOneWidget);
      final result = d.todayResult!;
      await d.flush;
      final record = store.record;
      final writes = store.writes;

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Arrowword'), findsOneWidget);
      expect(find.byType(PuzzleScreen), findsNothing);
      expect(find.byType(DailyPuzzleScreen), findsNothing);
      expect(find.text('Sonucu Gör'), findsOneWidget);
      expect(d.todayResult, same(result));
      expect(n.current.puzzleIndex, 2);
      expect(n.completedScores, isEmpty);
      await d.flush;
      expect(store.record, record);
      expect(store.writes, writes);

      await tester.tap(find.byKey(const ValueKey('daily-action')));
      await tester.pumpAndSettle();
      expect(find.byType(DailyResultScreen), findsOneWidget);
      expect(find.byType(PuzzleScreen), findsNothing);
      expect(d.todayResult, same(result));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Daily generation failure is safe and does not change progression',
    (tester) async {
      final n = normal();
      final current = n.current;
      final d = await daily(
        generator: (_) =>
            DailyPuzzleGeneration.failure('INTERNAL_SEARCH_BUDGET_FAILURE'),
      );
      await tester.pumpWidget(ArrowwordApp(session: n, dailySession: d));
      await tester.tap(find.byKey(const ValueKey('daily-action')));
      await tester.pumpAndSettle();
      expect(
        find.text('Günün bulmacası oluşturulamadı. Lütfen tekrar deneyin.'),
        findsOneWidget,
      );
      expect(find.textContaining('INTERNAL_SEARCH'), findsNothing);
      expect(find.byType(PuzzleScreen), findsNothing);
      expect(n.current, same(current));
      expect(tester.takeException(), isNull);
    },
  );

  for (final route in ['Devam Et', 'Bulmacalar', 'İstatistikler']) {
    testWidgets(
      'returning from $route refreshes the local Daily date without generation',
      (tester) async {
        var date = DateTime(2026, 10, 4, 23, 59);
        var calls = 0;
        final d = await daily(
          now: () => date,
          generator: (key) {
            calls++;
            return generate(key);
          },
        );
        final previous = d.openToday()!;
        previous.updateProgress(
          _solution(previous.generation.puzzle!),
          {},
          Duration.zero,
          0,
        );
        previous.complete();
        await tester.pumpWidget(
          ArrowwordApp(session: normal(), dailySession: d),
        );
        expect(find.text('Sonucu Gör'), findsOneWidget);
        await tester.tap(find.text(route));
        await tester.pumpAndSettle();
        date = DateTime(2026, 10, 5);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(d.dateKey, '2026-10-05');
        expect(find.text('Oyna'), findsOneWidget);
        expect(d.results.keys, ['2026-10-04']);
        expect(calls, 1);
      },
    );
  }

  for (final reward in [HintAdResult.earned, HintAdResult.dismissed]) {
    testWidgets(
      'Daily ad $reward across midnight/background keeps its original date and timer',
      (tester) async {
        var date = DateTime(2026, 10, 4, 23, 59);
        var time = Duration.zero;
        final d = await daily(now: () => date);
        final ad = _PendingAd();
        await open(tester, d, ad: ad, now: () => time);
        final original = d.openToday()!;
        time = const Duration(seconds: 10);
        await tester.tap(find.text('Reklamla Harf Aç'));
        await tester.pump();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        date = DateTime(2026, 10, 5);
        d.refreshDate();
        time += const Duration(hours: 1);
        ad.reward.complete(reward);
        await tester.pumpAndSettle();
        time += const Duration(hours: 2);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        time += const Duration(seconds: 5);
        final screen = tester.widget<PuzzleScreen>(find.byType(PuzzleScreen));
        expect(screen.subtitle, '2026-10-04');
        expect(screen.puzzle.id, dailyPuzzleId('2026-10-04'));
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(original.elapsed, const Duration(seconds: 15));
        expect(original.hintsUsed, reward == HintAdResult.earned ? 1 : 0);
        // Opening today's new attempt cannot inherit yesterday's hint or time.
        final today = d.openToday()!;
        expect(today.dateKey, '2026-10-05');
        expect(today.letters, isEmpty);
        expect(today.elapsed, Duration.zero);
        expect(today.hintsUsed, 0);
        expect(ad.shows, 1);
        await d.flush;
      },
    );
  }

  testWidgets(
    '360x640 Home/progression/statistics and three play routes fit 1.5x text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final n = normal();
      final d = await daily();
      await tester.pumpWidget(ArrowwordApp(session: n, dailySession: d));
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('İstatistikler'));
      await tester.tap(find.text('İstatistikler'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('statistics-error-free')),
        200,
      );
      expect(tester.takeException(), isNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Bulmacalar'));
      await tester.tap(find.text('Bulmacalar'));
      await tester.pumpAndSettle();
      for (final index in [1, 2]) {
        await tester.tap(find.byKey(ValueKey('puzzle-tile-$index')));
        await tester.pumpAndSettle();
        tester.view.viewInsets = const FakeViewPadding(bottom: 220);
        await tester.pump();
        expect(find.text('Kontrol Et'), findsOneWidget);
        expect(tester.takeException(), isNull);
        tester.view.resetViewInsets();
        await localizedPageBack(tester);
        await tester.pumpAndSettle();
      }
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('daily-action')));
      await tester.tap(find.byKey(const ValueKey('daily-action')));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      await localizedPageBack(tester);
      await tester.pumpAndSettle();
      final attempt = d.openToday()!;
      attempt.updateProgress(
        _solution(attempt.generation.puzzle!),
        {},
        Duration.zero,
        0,
      );
      attempt.complete();
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('daily-action')));
      await tester.tap(find.byKey(const ValueKey('daily-action')));
      await tester.pumpAndSettle();
      expect(find.byType(DailyResultScreen), findsOneWidget);
      await tester.ensureVisible(find.text('Ana Sayfaya Dön'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('development override bypasses Home and both player saves', (
    tester,
  ) async {
    final playerStore = MemoryPuzzleProgressStore('normal player record');
    final n = await PuzzleSession.restore(
      store: playerStore,
      generator: _NormalFixtures(fixture),
      developmentIndex: 2,
    );
    addTearDown(n.dispose);
    final dailyStore = MemoryDailyProgressStore(DailyProgress().encode());
    final savedDaily = dailyStore.record;
    var calls = 0;
    final d = await daily(
      store: dailyStore,
      generator: (date) {
        calls++;
        return generate(date);
      },
    );
    await tester.pumpWidget(
      ArrowwordApp(session: n, dailySession: d, openPuzzleDirectly: true),
    );
    expect(find.text('Günün Bulmacası'), findsNothing);
    expect(find.text('İstatistikler'), findsNothing);
    final p = n.current.puzzle!.answers.first.start;
    await _enter(tester, p, 'Z');
    await n.flush;
    await d.flush;
    expect(calls, 0);
    expect(playerStore.record, 'normal player record');
    expect(playerStore.writes, 0);
    expect(dailyStore.record, savedDaily);
    expect(dailyStore.writes, 0);
  });
}
