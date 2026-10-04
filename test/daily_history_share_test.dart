import 'package:arrowword/app/daily_history_screen.dart';
import 'package:arrowword/app/daily_progress_store.dart';
import 'package:arrowword/app/daily_puzzle_screen.dart';
import 'package:arrowword/app/daily_result_share_service.dart';
import 'package:arrowword/app/daily_session.dart';
import 'package:arrowword/features/puzzle/daily/daily_puzzle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeShare implements DailyResultShareService {
  final texts = <String>[];
  @override
  Future<void> share(String text, {Rect? origin}) async => texts.add(text);
}

DailyPuzzleScore result(String date) => DailyPuzzleScore.calculate(
  dateKey: date,
  dailyPuzzleId: dailyPuzzleId(date),
  elapsedSeconds: 80,
  hintsUsed: 1,
  wrongChecks: 1,
);

void main() {
  Future<DailySession> session(List<String> dates) async =>
      DailySession.restore(
        store: MemoryDailyProgressStore(
          DailyProgress(results: {for (final date in dates) date: result(date)})
              .encode(),
        ),
        localNow: () => DateTime(2026, 10, 4),
        generator: (_) =>
            throw StateError('Metadata must not generate puzzles'),
      );
  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('empty history', (tester) async {
    final s = await session([]);
    addTearDown(s.dispose);
    await pump(tester, DailyHistoryScreen(session: s));
    expect(find.text('Henüz tamamlanan günlük bulmaca yok.'), findsOneWidget);
  });
  testWidgets('newest first with details and no replay controls', (
    tester,
  ) async {
    final s = await session(['2026-10-02', '2026-10-04', '2026-10-03']);
    addTearDown(s.dispose);
    await pump(tester, DailyHistoryScreen(session: s));
    expect(
      tester.getTopLeft(find.text('4 Ekim 2026')).dy,
      lessThan(tester.getTopLeft(find.text('3 Ekim 2026')).dy),
    );
    expect(find.text('1275 puan'), findsWidgets);
    expect(find.text('01:20 · 1 ipucu · 1 hatalı kontrol'), findsWidgets);
    expect(find.byType(InkWell), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('large history lazily scrolls safely', (tester) async {
    final dates = [
      for (var i = 0; i < 1000; i++) dailyDateKey(DateTime(2026, 10, 4 - i)),
    ];
    final s = await session(dates);
    addTearDown(s.dispose);
    await pump(tester, DailyHistoryScreen(session: s));
    expect(find.byType(Card).evaluate().length, lessThan(20));
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  test('share text is exact and contains no identity/content', () {
    expect(
      dailyResultShareText(result('2026-10-04'), streak: 3),
      'Arrowword — Günün Bulmacası\n4 Ekim 2026\n\nPuan: 1275\nSüre: 01:20\nİpucu: 1\nHatalı kontrol: 1\nSeri: 3 gün',
    );
    expect(
      dailyResultShareText(result('2026-10-04'), streak: 0),
      isNot(contains('Seri:')),
    );
    expect(
      dailyResultShareText(result('2026-10-04'), streak: 3),
      isNot(contains('daily-v')),
    );
  });
  testWidgets('completed result shares exactly once and remains compact', (
    tester,
  ) async {
    final s = await session(['2026-10-02', '2026-10-03', '2026-10-04']);
    addTearDown(s.dispose);
    final share = FakeShare();
    await pump(tester, DailyPuzzleScreen(session: s, shareService: share));
    expect(find.text('3 günlük seri'), findsOneWidget);
    await tester.ensureVisible(find.text('Paylaş'));
    await tester.tap(find.text('Paylaş'));
    await tester.pumpAndSettle();
    expect(share.texts, [dailyResultShareText(s.todayResult!, streak: 3)]);
    await tester.ensureVisible(find.text('Günlük Geçmiş'));
    await tester.tap(find.text('Günlük Geçmiş'));
    await tester.pumpAndSettle();
    expect(find.byType(DailyHistoryScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('restart and rollover derive streak without changing results', () async {
    var now = DateTime(2026, 10, 4);
    final store = MemoryDailyProgressStore(
      DailyProgress(
        results: {
          '2026-10-03': result('2026-10-03'),
          '2026-10-04': result('2026-10-04'),
        },
      ).encode(),
    );
    final s = await DailySession.restore(store: store, localNow: () => now);
    final restored = await DailySession.restore(
      store: store,
      localNow: () => now,
    );
    addTearDown(s.dispose);
    addTearDown(restored.dispose);
    expect(restored.statistics.currentStreak, 2);
    now = DateTime(2026, 10, 6);
    restored.refreshDate();
    expect(restored.statistics.currentStreak, 0);
    expect(restored.statistics.longestStreak, 2);
    expect(restored.results.length, 2);
    expect(store.writes, 0);
  });
}
