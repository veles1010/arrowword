import 'dart:async';

import 'package:arrowword/app/app.dart';
import 'package:arrowword/app/puzzle_progress_store.dart';
import 'package:arrowword/app/puzzle_progression_screen.dart';
import 'package:arrowword/app/puzzle_replay_screen.dart';
import 'package:arrowword/app/puzzle_session.dart';
import 'package:arrowword/features/puzzle/ads/rewarded_hint_ad_service.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_score.dart';
import 'package:arrowword/features/puzzle/presentation/puzzle_screen.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Fixtures extends PuzzleSequenceGenerator {
  _Fixtures(this.fixture) : super(prototypeCatalogue, prototypeSequenceConfig);
  final SequencePuzzleResult fixture;
  bool failReplay = false;

  @override
  SequencePuzzleResult generateNext({
    required int puzzleIndex,
    List<PuzzleHistoryEntry> history = const [],
  }) {
    if (failReplay) throw StateError('Replay generation failed');
    return SequencePuzzleResult(
      puzzleIndex: puzzleIndex,
      seed: fixture.seed,
      catalogVersion: fixture.catalogVersion,
      pool: fixture.pool,
      puzzle: Puzzle(
        id: 'replay-fixture-$puzzleIndex',
        label: fixture.puzzle!.label,
        rowCount: fixture.puzzle!.rowCount,
        columnCount: fixture.puzzle!.columnCount,
        answers: fixture.puzzle!.answers,
      ),
      generation: fixture.generation,
    );
  }
}

class _PendingAd extends FakeRewardedHintAdService {
  final reward = Completer<HintAdResult>();
  @override
  Future<HintAdResult> show() => reward.future;
}

Map<GridPosition, String> _solution(Puzzle puzzle) => {
  for (final answer in puzzle.answers)
    for (var i = 0; i < answer.length; i++)
      answer.positions[i]: answer.solution[i],
};

Future<void> _enter(
  WidgetTester tester,
  GridPosition position,
  String letter,
) async {
  await tester.tap(
    find.byKey(ValueKey('cell-${position.row}-${position.column}')),
  );
  await tester.enterText(find.byType(TextField), letter);
  await tester.pump();
}

Future<void> _solve(
  WidgetTester tester,
  Puzzle puzzle, {
  GridPosition? skip,
}) async {
  for (final entry in _solution(puzzle).entries) {
    if (entry.key != skip) await _enter(tester, entry.key, entry.value);
  }
  await tester.pumpAndSettle();
}

void main() {
  late SequencePuzzleResult fixture;
  setUpAll(() {
    fixture = PuzzleSequenceGenerator(
      prototypeCatalogue,
      prototypeSequenceConfig,
    ).generateNext(puzzleIndex: 1);
    expect(fixture.isSuccess, isTrue);
  });

  PuzzleSession sessionAt({PuzzleProgressStore? store, _Fixtures? generator}) {
    final session = PuzzleSession(
      generator: generator ?? _Fixtures(fixture),
      startIndex: 2,
      store: store,
    );
    addTearDown(session.dispose);
    return session;
  }

  Future<void> open(
    WidgetTester tester,
    PuzzleSession session, {
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
                  builder: (_) => PuzzleReplayScreen(
                    session: session,
                    puzzleIndex: 1,
                    rewardedAdFactory: ad == null ? null : () => ad,
                    monotonicNow: now ?? () => Duration.zero,
                  ),
                ),
              ),
              child: const Text('Open replay'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open replay'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'replay starts empty and typing, checking and clearing stay isolated',
    (tester) async {
      final session = sessionAt();
      final position = session.current.puzzle!.answers.first.start;
      session.updateAttemptProgress(
        {position: 'Z'},
        {position},
        const Duration(seconds: 77),
        4,
      );
      final normalLetters = session.letters;
      await open(tester, session);
      final screen = tester.widget<PuzzleScreen>(find.byType(PuzzleScreen));
      expect(screen.initialLetters, isEmpty);
      expect(screen.initialRevealedCells, isEmpty);
      expect(screen.initialWrongChecks, 0);
      expect(screen.initialElapsed, Duration.zero);
      expect(find.text('Bulmaca 1 · Tekrar Oyna'), findsOneWidget);
      final expected = _solution(screen.puzzle)[position]!;
      await _enter(tester, position, expected == 'Z' ? 'X' : 'Z');
      await tester.tap(find.text('Kontrol Et'));
      await tester.pump();
      await tester.tap(find.text('Temizle'));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(ValueKey('cell-${position.row}-${position.column}')),
          matching: find.text(''),
        ),
        findsOneWidget,
      );
      await _solve(tester, screen.puzzle);
      expect(
        find.text(
          'Bu deneme: 1375\nEn iyi: 1375\nSüre: 00:00\nİpucu: 0\nHatalı kontrol: 1',
        ),
        findsOneWidget,
      );
      expect(find.text('Yeni rekor!'), findsOneWidget);
      expect(find.text('Sonraki Bulmaca'), findsNothing);
      expect(session.current.puzzleIndex, 2);
      expect(session.letters, normalLetters);
      expect(session.hintsUsed, 1);
      expect(session.elapsed, const Duration(seconds: 77));
      expect(session.wrongChecks, 4);
      await tester.tap(find.text('Bulmacalara Dön'));
      await tester.pumpAndSettle();
      expect(find.text('Open replay'), findsOneWidget);
    },
  );

  testWidgets(
    'earned final hint completes replay and excludes ad and inactive time',
    (tester) async {
      final session = sessionAt();
      var now = Duration.zero;
      final ad = _PendingAd();
      await open(tester, session, ad: ad, now: () => now);
      final puzzle = tester
          .widget<PuzzleScreen>(find.byType(PuzzleScreen))
          .puzzle;
      final missing = puzzle.answers.first.start;
      await _solve(tester, puzzle, skip: missing);
      now = const Duration(seconds: 60);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      now += const Duration(hours: 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      now += const Duration(seconds: 61);
      await tester.tap(
        find.byKey(ValueKey('cell-${missing.row}-${missing.column}')),
      );
      await tester.pump();
      await tester.tap(find.text('Reklamla Harf Aç'));
      await tester.pump();
      now += const Duration(hours: 2);
      ad.reward.complete(HintAdResult.earned);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Bu deneme: 1200\nEn iyi: 1200\nSüre: 02:01\nİpucu: 1\nHatalı kontrol: 0',
        ),
        findsOneWidget,
      );
      expect(session.completedScores[1]!.elapsedSeconds, 121);
      expect(session.completedScores[1]!.hintsUsed, 1);
      now += const Duration(hours: 3);
      await tester.pump();
      expect(session.completedScores[1]!.elapsedSeconds, 121);
    },
  );

  testWidgets(
    'dismissed replay ad grants no hint and system back discards it',
    (tester) async {
      final store = MemoryPuzzleProgressStore();
      final session = sessionAt(store: store);
      session.checkpointElapsed(const Duration(seconds: 22));
      await session.flush;
      final record = store.record;
      final ad = _PendingAd();
      await open(tester, session, ad: ad);
      final p = tester
          .widget<PuzzleScreen>(find.byType(PuzzleScreen))
          .puzzle
          .answers
          .first
          .start;
      await tester.tap(find.byKey(ValueKey('cell-${p.row}-${p.column}')));
      await tester.pump();
      await tester.tap(find.text('Reklamla Harf Aç'));
      await tester.pump();
      ad.reward.complete(HintAdResult.dismissed);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(ValueKey('cell-${p.row}-${p.column}')),
          matching: find.text(''),
        ),
        findsOneWidget,
      );
      await _enter(tester, p, 'Z');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Open replay'), findsOneWidget);
      await session.flush;
      expect(store.record, record);
      await open(tester, session);
      expect(
        tester.widget<PuzzleScreen>(find.byType(PuzzleScreen)).initialLetters,
        isEmpty,
      );
    },
  );

  testWidgets('one pending replay reward grants exactly one locked hint', (
    tester,
  ) async {
    final session = sessionAt();
    final ad = _PendingAd();
    await open(tester, session, ad: ad);
    final screen = tester.widget<PuzzleScreen>(find.byType(PuzzleScreen));
    final p = screen.puzzle.answers.first.start;
    await tester.tap(find.byKey(ValueKey('cell-${p.row}-${p.column}')));
    await tester.pump();
    await tester.tap(find.text('Reklamla Harf Aç'));
    await tester.pump();
    final button = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('Reklamla Harf Aç'),
        matching: find.byType(TextButton),
      ),
    );
    expect(button.onPressed, isNull);
    ad.reward.complete(HintAdResult.earned);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Z');
    await tester.tap(find.text('Temizle'));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(ValueKey('cell-${p.row}-${p.column}')),
        matching: find.text(_solution(screen.puzzle)[p]!),
      ),
      findsOneWidget,
    );
    await _solve(tester, screen.puzzle);
    expect(session.completedScores[1]!.hintsUsed, 1);
    expect(session.completedScores[1]!.score, 1300);
  });

  for (final previousSeconds in <int?>[null, 0, 600]) {
    testWidgets(
      'completion refreshes progression best with previous time $previousSeconds',
      (tester) async {
        final session = sessionAt();
        if (previousSeconds != null) {
          session.recordReplayScore(
            CompletedPuzzleScore.calculate(
              puzzleIndex: 1,
              elapsedSeconds: previousSeconds,
              hintsUsed: 0,
              wrongChecks: 0,
            ),
          );
        }
        await tester.pumpWidget(ArrowwordApp(session: session));
        await tester.tap(find.text('Bulmacalar'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('puzzle-tile-1')));
        await tester.pumpAndSettle();
        final puzzle = tester
            .widget<PuzzleScreen>(find.byType(PuzzleScreen))
            .puzzle;
        if (previousSeconds == 0) {
          final entry = _solution(puzzle).entries.first;
          await _enter(tester, entry.key, entry.value == 'Z' ? 'X' : 'Z');
          await tester.tap(find.text('Kontrol Et'));
          await tester.pump();
        }
        await _solve(tester, puzzle);
        expect(session.completedScores[1]!.score, 1400);
        expect(
          find.text('Yeni rekor!'),
          previousSeconds == 0 ? findsNothing : findsOneWidget,
        );
        await tester.tap(find.text('Bulmacalara Dön'));
        await tester.pumpAndSettle();
        expect(find.byType(PuzzleProgressionScreen), findsOneWidget);
        expect(find.text('1400 puan'), findsOneWidget);
        expect(session.current.puzzleIndex, 2);
      },
    );
  }

  testWidgets('unfinished replay exit and restore retain normal attempt', (
    tester,
  ) async {
    final store = MemoryPuzzleProgressStore();
    final session = sessionAt(store: store);
    final position = session.current.puzzle!.answers.first.start;
    session.updateAttemptProgress(
      {position: 'Z'},
      {},
      const Duration(seconds: 33),
      2,
    );
    await session.flush;
    await open(tester, session);
    await _enter(tester, position, 'B');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await session.flush;
    final restored = await PuzzleSession.restore(
      store: store,
      generator: _Fixtures(fixture),
    );
    addTearDown(restored.dispose);
    expect(restored.current.puzzleIndex, 2);
    expect(restored.completedThrough, 1);
    expect(restored.letters, {position: 'Z'});
    expect(restored.elapsed, const Duration(seconds: 33));
    expect(restored.wrongChecks, 2);
    expect(restored.completedScores, isEmpty);
    await open(tester, restored);
    expect(
      tester.widget<PuzzleScreen>(find.byType(PuzzleScreen)).initialLetters,
      isEmpty,
    );
  });

  testWidgets('system back after replay completion returns to progression', (
    tester,
  ) async {
    final store = MemoryPuzzleProgressStore();
    final session = sessionAt(store: store);
    final position = session.current.puzzle!.answers.first.start;
    session.updateAttemptProgress(
      {position: 'Z'},
      {},
      const Duration(seconds: 33),
      2,
    );
    await tester.pumpWidget(ArrowwordApp(session: session));
    await tester.tap(find.text('Bulmacalar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('puzzle-tile-1')));
    await tester.pumpAndSettle();
    final puzzle = tester
        .widget<PuzzleScreen>(find.byType(PuzzleScreen))
        .puzzle;
    await _solve(tester, puzzle);
    expect(find.text('Bulmaca tamamlandı!'), findsOneWidget);
    final best = session.completedScores[1]!;
    await session.flush;
    final record = store.record;
    final writes = store.writes;

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(PuzzleProgressionScreen), findsOneWidget);
    expect(find.byType(PuzzleReplayScreen), findsNothing);
    expect(find.byType(PuzzleScreen), findsNothing);
    expect(find.text('${best.score} puan'), findsOneWidget);
    expect(session.completedScores[1], same(best));
    expect(session.current.puzzleIndex, 2);
    expect(session.completedThrough, 1);
    expect(session.letters, {position: 'Z'});
    expect(session.elapsed, const Duration(seconds: 33));
    expect(session.wrongChecks, 2);
    await session.flush;
    expect(store.record, record);
    expect(store.writes, writes);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failed replay generation displays an error without changing session',
    (tester) async {
      final generator = _Fixtures(fixture);
      final session = sessionAt(generator: generator);
      final current = session.current;
      generator.failReplay = true;
      await open(tester, session);
      expect(find.byType(PuzzleScreen), findsNothing);
      expect(find.textContaining('oluşturulamadı'), findsWidgets);
      expect(tester.takeException(), isNull);
      expect(session.current, same(current));
      expect(session.completedThrough, 1);
      expect(session.completedScores, isEmpty);
    },
  );
}
