import 'package:arrowword/app/app.dart';
import 'package:arrowword/app/app_shell.dart';
import 'package:arrowword/app/daily_progress_store.dart';
import 'package:arrowword/app/daily_session.dart';
import 'package:arrowword/app/development_puzzle.dart';
import 'package:arrowword/app/puzzle_progress_store.dart';
import 'package:arrowword/app/puzzle_session.dart';
import 'package:arrowword/app/puzzle_track.dart';
import 'package:arrowword/features/puzzle/ads/rewarded_hint_ad_service.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_difficulty.dart';
import 'package:arrowword/features/puzzle/presentation/puzzle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _UntouchedStore extends MemoryPuzzleProgressStore {
  _UntouchedStore() : super('player data must not be read or changed');
  int reads = 0, clears = 0;
  @override
  Future<String?> read() async {
    reads++;
    return super.read();
  }

  @override
  Future<void> clear() async {
    clears++;
    await super.clear();
  }
}

void main() {
  DevelopmentPuzzleLaunch? resolve({
    bool provided = true,
    bool release = false,
    String index = '27',
    String difficulty = 'easy',
  }) => resolveDevelopmentPuzzleLaunch(
    indexProvided: provided,
    releaseMode: release,
    index: index,
    difficulty: difficulty,
  );

  test('no index means normal startup even with a difficulty define', () {
    expect(resolve(provided: false, difficulty: 'hard'), isNull);
    expect(resolve(provided: false, difficulty: 'invalid'), isNull);
  });
  test('index-only override is Easy at the exact requested index', () {
    final launch = resolve()!;
    expect(launch.index, 27);
    expect(launch.difficulty, PuzzleDifficulty.easy);
  });
  for (final difficulty in ['medium', 'hard']) {
    test(
      'debug and profile resolve $difficulty without the debug-only gate',
      () {
        final launch = resolve(difficulty: difficulty)!;
        expect(launch.index, 27);
        expect(launch.difficulty.id, difficulty);
      },
    );
  }
  test('release ignores development defines and malformed override values', () {
    expect(resolve(release: true, index: 'bad', difficulty: 'bad'), isNull);
  });
  test('all six requested profile playtest commands resolve their exact track/index', () {
    for (final track in {
      'medium': [27, 1, 11],
      'hard': [1, 27, 19],
    }.entries) {
      for (final index in track.value) {
        final launch = resolve(index: '$index', difficulty: track.key)!;
        expect(launch.index, index);
        expect(launch.difficulty.id, track.key);
      }
    }
  });
  test('invalid supplied index/difficulty fails instead of opening Easy', () {
    for (final index in ['', '0', '-1', 'abc', '4294967296']) {
      expect(() => resolve(index: index), throwsArgumentError);
    }
    expect(() => resolve(difficulty: 'Medium'), throwsArgumentError);
  });

  final sessions = <PuzzleDifficulty, PuzzleSession>{};
  final stores = <PuzzleDifficulty, _UntouchedStore>{};
  setUpAll(() async {
    for (final difficulty in PuzzleDifficulty.values) {
      final store = stores[difficulty] = _UntouchedStore();
      sessions[difficulty] = await PuzzleTrack(
        configuration: PuzzleTrackConfiguration.forDifficulty(difficulty),
        store: store,
      ).open(developmentIndex: difficulty == PuzzleDifficulty.medium ? 2 : 1);
    }
  });
  tearDownAll(() {
    for (final session in sessions.values) {
      session.dispose();
    }
  });

  for (final difficulty in PuzzleDifficulty.values) {
    testWidgets(
      '$difficulty opens exact memory-only board, no Home or progression',
      (tester) async {
        final session = sessions[difficulty]!;
        final index = difficulty == PuzzleDifficulty.medium ? 2 : 1;
        await tester.pumpWidget(
          ArrowwordApp(
            session: session,
            developmentOverride: true,
            rewardedAdFactory: () => FakeRewardedHintAdService(),
          ),
        );
        await tester.pumpAndSettle();
        expect(session.current.puzzleIndex, index);
        expect(
          session.current.puzzle!.id,
          difficulty == PuzzleDifficulty.easy
              ? 'generated-v3-000001'
              : 'generated-${difficulty.id}-v1-${index.toString().padLeft(6, '0')}',
        );
        expect(
          find.text('${difficulty.turkishLabel} · Bulmaca $index'),
          findsOneWidget,
        );
        expect(find.text('Geliştirme · İlerleme kaydedilmez'), findsOneWidget);
        expect(find.byType(PuzzleScreen), findsOneWidget);
        expect(find.byType(AppShell), findsNothing);
        expect(find.text('Devam Et'), findsNothing);
        expect(session.store, isNull);
        expect(stores[difficulty]!.reads, 0);
        expect(stores[difficulty]!.writes, 0);
        expect(stores[difficulty]!.clears, 0);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'override completion previews score but never changes progression, best scores or history',
    (tester) async {
      final session = sessions[PuzzleDifficulty.hard]!;
      final beforeHistory = session.history.toList();
      final beforeCompleted = session.completedThrough;
      final dailyStore = MemoryDailyProgressStore();
      final daily = await DailySession.restore(
        store: dailyStore,
        localNow: () => DateTime(2026, 10, 6),
      );
      addTearDown(daily.dispose);
      await tester.pumpWidget(
        ArrowwordApp(
          session: session,
          developmentOverride: true,
          dailySession: daily,
          rewardedAdFactory: () => FakeRewardedHintAdService(),
        ),
      );
      await tester.pumpAndSettle();
      final screen = tester.widget<PuzzleScreen>(find.byType(PuzzleScreen));
      expect(screen.onCompleted, isNull);
      expect(screen.onNextPuzzle, isNull);
      final solution = {
        for (final answer in session.current.puzzle!.answers)
          for (var i = 0; i < answer.length; i++)
            answer.positions[i]: answer.solution[i],
      };
      for (final entry in solution.entries) {
        await tester.tap(
          find.byKey(ValueKey('cell-${entry.key.row}-${entry.key.column}')),
        );
        await tester.enterText(find.byType(TextField), entry.value);
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.text('Bulmaca tamamlandı!'), findsOneWidget);
      expect(find.textContaining('Puan:'), findsOneWidget);
      expect(find.text('Oturumu Kapat'), findsOneWidget);
      expect(find.text('Sonraki Bulmaca'), findsNothing);
      await tester.runAsync(() => session.flush);
      expect(session.current.puzzleIndex, 1);
      expect(session.completedThrough, beforeCompleted);
      expect(session.completedScores, isEmpty);
      expect(session.history, beforeHistory);
      for (final store in stores.values) {
        expect(store.reads, 0);
        expect(store.writes, 0);
        expect(store.clears, 0);
        expect(store.record, 'player data must not be read or changed');
      }
      expect(dailyStore.writes, 0);
      expect(dailyStore.clears, 0);
      expect(daily.results, isEmpty);
      var exits = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemNavigator.pop') exits++;
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.tap(find.text('Oturumu Kapat'));
      await tester.pumpAndSettle();
      expect(exits, 1);
      expect(find.byType(AppShell), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'system Back exits override without opening Home and recreation discards letters',
    (tester) async {
      final session = sessions[PuzzleDifficulty.medium]!;
      final store = stores[PuzzleDifficulty.medium]!;
      await tester.pumpWidget(
        ArrowwordApp(
          session: session,
          developmentOverride: true,
          rewardedAdFactory: () => FakeRewardedHintAdService(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Z');
      await tester.pump();
      expect(session.letters, isNotEmpty);
      var exits = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemNavigator.pop') exits++;
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(exits, 1);
      expect(find.byType(AppShell), findsNothing);
      await tester.pumpWidget(const SizedBox());
      final fresh = await tester.runAsync(
        () => PuzzleTrack(
          configuration: PuzzleTrackConfiguration.medium,
          store: store,
        ).open(developmentIndex: 2),
      );
      addTearDown(fresh!.dispose);
      expect(fresh.current.puzzle!.id, session.current.puzzle!.id);
      expect(fresh.letters, isEmpty);
      expect(fresh.completedScores, isEmpty);
      expect(store.reads, 0);
      expect(store.writes, 0);
      expect(store.clears, 0);
    },
  );

  testWidgets(
    'without override the same Easy session opens normal shell without a development label',
    (tester) async {
      await tester.pumpWidget(
        ArrowwordApp(session: sessions[PuzzleDifficulty.easy]!),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.textContaining('Geliştirme'), findsNothing);
      expect(find.byType(PuzzleScreen), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
