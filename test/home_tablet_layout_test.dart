import 'package:arrowword/app/daily_progress_store.dart';
import 'package:arrowword/app/daily_session.dart';
import 'package:arrowword/app/home_screen.dart';
import 'package:arrowword/app/puzzle_session.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
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

  for (final (platform, size, scale) in [
    (TargetPlatform.iOS, const Size(1024, 1366), 1.0),
    (TargetPlatform.iOS, const Size(1366, 1024), 1.0),
    (TargetPlatform.android, const Size(800, 1280), 1.0),
    (TargetPlatform.android, const Size(1280, 800), 1.0),
    (TargetPlatform.iOS, const Size(600, 1024), 1.5),
    (TargetPlatform.iOS, const Size(390, 844), 1.0),
    (TargetPlatform.android, const Size(320, 480), 2.0),
  ]) {
    testWidgets('home content stays centered at $platform $size scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final session = PuzzleSession(generator: _Fixture(fixture));
      final daily = await DailySession.restore(
        store: MemoryDailyProgressStore(),
        localNow: () => DateTime(2026, 10, 25),
      );
      addTearDown(session.dispose);
      addTearDown(daily.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: platform),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
            ),
            child: child!,
          ),
          home: HomeScreen(
            session: session,
            dailySession: daily,
            inShell: true,
            puzzleBuilder: (_) => const Scaffold(body: Text('Puzzle route')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final home = find.byType(HomeScreen);
      final viewport = tester.getRect(home);
      final title = find.descendant(of: home, matching: find.text('Bulmaca 1'));
      final start = find.descendant(
        of: home,
        matching: find.widgetWithText(FilledButton, 'Başla'),
      );
      final card = find.descendant(of: home, matching: find.byType(Card));
      for (final finder in [title, start, card]) {
        final rect = tester.getRect(finder);
        expect(rect.center.dx, closeTo(viewport.center.dx, 1));
        expect(rect.left, greaterThanOrEqualTo(viewport.left));
        expect(rect.right, lessThanOrEqualTo(viewport.right));
      }
      expect(tester.getSize(card).width, lessThanOrEqualTo(400));
      expect(tester.takeException(), isNull);

      final dailyAction = find.descendant(
        of: home,
        matching: find.byKey(const ValueKey('daily-action')),
      );
      await tester.ensureVisible(dailyAction);
      await tester.pumpAndSettle();
      final point = tester.getCenter(dailyAction);
      expect(point.dy, inInclusiveRange(0, size.height));
      expect(dailyAction.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
