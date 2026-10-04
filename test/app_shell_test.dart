import 'package:arrowword/app/app.dart';
import 'package:arrowword/app/app_settings.dart';
import 'package:arrowword/app/app_shell.dart';
import 'package:arrowword/app/daily_landing_screen.dart';
import 'package:arrowword/app/daily_session.dart';
import 'package:arrowword/app/daily_progress_store.dart';
import 'package:arrowword/app/home_screen.dart';
import 'package:arrowword/app/puzzle_session.dart';
import 'package:arrowword/app/puzzle_progression_screen.dart';
import 'package:arrowword/app/statistics_screen.dart';
import 'package:arrowword/app/daily_history_screen.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:arrowword/features/puzzle/daily/daily_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/presentation/puzzle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Fixture extends PuzzleSequenceGenerator {
  _Fixture(this.result) : super(prototypeCatalogue, prototypeSequenceConfig);
  final SequencePuzzleResult result;
  @override
  SequencePuzzleResult generateNext({
    required int puzzleIndex,
    List<PuzzleHistoryEntry> history = const [],
  }) => result;
}

void main() {
  late SequencePuzzleResult fixture;
  setUpAll(() => fixture = generatePrototypePuzzle());
  Future<(PuzzleSession, DailySession)> pump(
    WidgetTester tester, {
    bool completed = false,
    bool dark = false,
  }) async {
    final session = PuzzleSession(generator: _Fixture(fixture));
    var calls = 0;
    final daily = await DailySession.restore(
      store: MemoryDailyProgressStore(
        DailyProgress(
          results: completed
              ? {
                  '2026-10-04': DailyPuzzleScore.calculate(
                    dateKey: '2026-10-04',
                    dailyPuzzleId: dailyPuzzleId('2026-10-04'),
                    elapsedSeconds: 80,
                    hintsUsed: 0,
                    wrongChecks: 0,
                  ),
                }
              : {},
        ).encode(),
      ),
      localNow: () => DateTime(2026, 10, 4),
      generator: (date) {
        calls++;
        return DailyPuzzleGeneration.success(
          Puzzle(
            id: dailyPuzzleId(date),
            label: 'Günlük',
            rowCount: 10,
            columnCount: 10,
            answers: fixture.puzzle!.answers,
          ),
        );
      },
    );
    addTearDown(session.dispose);
    addTearDown(daily.dispose);
    final settings = AppSettings(
      MemorySettingsStore(),
      dark ? ThemeMode.dark : ThemeMode.light,
    );
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      ArrowwordApp(session: session, dailySession: daily, settings: settings),
    );
    expect(calls, 0);
    return (session, daily);
  }

  Future<void> tab(WidgetTester tester, int i) async {
    await tester.tap(find.byKey(ValueKey('navigation-$i')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'haptic fires once per actual tap/release commit and never on preview/startup',
    (tester) async {
      final (session, daily) = await pump(tester);
      var haptics = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            session: session,
            dailySession: daily,
            puzzleBuilder: (_) => const SizedBox(),
            selectionHaptic: () async {
              haptics++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(haptics, 0);
      await tab(tester, 1);
      expect(haptics, 1);
      await tab(tester, 1);
      expect(haptics, 1);
      final item = find.byKey(const ValueKey('navigation-1'));
      final width = tester.getSize(item).width;
      final gesture = await tester.startGesture(tester.getCenter(item));
      await gesture.moveBy(Offset(width * .7, 0));
      await tester.pump();
      expect(haptics, 1);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(haptics, 2);
      final second = find.byKey(const ValueKey('navigation-2'));
      final back = await tester.startGesture(tester.getCenter(second));
      await back.moveBy(Offset(width * .3, 0));
      await tester.pump();
      await back.up();
      await tester.pumpAndSettle();
      expect(haptics, 2);
    },
  );
  testWidgets('unsupported haptics fail silently without changing navigation', (
    tester,
  ) async {
    final (session, daily) = await pump(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: AppShell(
          session: session,
          dailySession: daily,
          puzzleBuilder: (_) => const SizedBox(),
          selectionHaptic: () => throw UnsupportedError('haptics'),
        ),
      ),
    );
    await tab(tester, 2);
    expect(find.byType(DailyLandingScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('startup Home is clean; all tabs and system Back work', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(HomeScreen),
        matching: find.text('Bulmacalar'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(HomeScreen),
        matching: find.text('İstatistikler'),
      ),
      findsNothing,
    );
    await tab(tester, 1);
    expect(find.byType(PuzzleProgressionScreen), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
    await tab(tester, 2);
    expect(find.byType(DailyLandingScreen), findsOneWidget);
    await tab(tester, 3);
    expect(find.byType(StatisticsScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    final pop = tester.widget<PopScope>(
      find.byWidgetPredicate((widget) => widget is PopScope).first,
    );
    expect(pop.canPop, isTrue);
  });
  testWidgets('normal route returns Home and tab scroll state is retained', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Başla'));
    await tester.pumpAndSettle();
    expect(find.byType(PuzzleScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    await tab(tester, 3);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    final offset = scroll.position.pixels;
    await tab(tester, 1);
    await tab(tester, 3);
    expect(
      tester.state<ScrollableState>(find.byType(Scrollable).first),
      same(scroll),
    );
    expect(scroll.position.pixels, offset);
  });
  testWidgets(
    'unfinished Daily opens lazily and routes back to Daily landing',
    (tester) async {
      final (_, daily) = await pump(tester);
      await tab(tester, 2);
      expect(find.text('Oyna'), findsOneWidget);
      expect(daily.hasCurrentProgress, isFalse);
      await tester.tap(find.byKey(const ValueKey('daily-landing-action')));
      await tester.pumpAndSettle();
      expect(find.byType(PuzzleScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(DailyLandingScreen), findsOneWidget);
      await tester.tap(find.text('Günlük Geçmiş'));
      await tester.pumpAndSettle();
      expect(find.byType(DailyHistoryScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(DailyLandingScreen), findsOneWidget);
    },
  );
  testWidgets('completed Daily landing remains result only', (tester) async {
    final (_, daily) = await pump(tester, completed: true);
    await tab(tester, 2);
    expect(find.text('Bugün tamamlandı · 1400 puan'), findsOneWidget);
    expect(find.text('Sonucu Gör'), findsOneWidget);
    expect(daily.openToday(), isNull);
    expect(daily.results.length, 1);
  });
  testWidgets('all compact dark tabs fit 1.5x text and avoid generation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final (_, daily) = await pump(tester, dark: true);
    for (var i = 0; i < 4; i++) {
      await tab(tester, i);
      expect(tester.takeException(), isNull);
      expect(daily.hasCurrentProgress, isFalse);
    }
    await tab(tester, 0);
    expect(find.byTooltip('Ayarlar'), findsOneWidget);
  });
}
