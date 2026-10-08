import 'dart:async';

import 'package:arrowword/features/puzzle/ads/rewarded_hint_ad_service.dart';
import 'package:arrowword/features/puzzle/data/manual_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/presentation/puzzle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _PendingAd extends FakeRewardedHintAdService {
  final completion = Completer<HintAdResult>();
  void reward() {
    if (!completion.isCompleted) completion.complete(HintAdResult.earned);
  }

  @override
  Future<HintAdResult> show() {
    shows++;
    return completion.future;
  }
}

void main() {
  Future<void> open(
    WidgetTester tester,
    RewardedHintAdService ad,
    void Function(Map<GridPosition, String>, Set<GridPosition>) changed,
  ) => tester.pumpWidget(
    MaterialApp(
      home: PuzzleScreen(
        puzzle: manualPuzzle,
        rewardedAdFactory: () => ad,
        onProgressChanged: changed,
      ),
    ),
  );

  for (final result in HintAdResult.values) {
    testWidgets('$result grants only earned reward', (tester) async {
      final ad = FakeRewardedHintAdService(result: result);
      Set<GridPosition> hints = {};
      Map<GridPosition, String> letters = {};
      await open(tester, ad, (l, h) {
        letters = l;
        hints = h;
      });
      await tester.tap(find.text('Reklamla Harf Aç'));
      await tester.pumpAndSettle();
      expect(hints.length, result == HintAdResult.earned ? 1 : 0);
      if (result == HintAdResult.earned) {
        expect(
          letters[manualPuzzle.answers.first.start],
          manualPuzzle.answers.first.solution[0],
        );
        await tester.enterText(find.byType(TextField), 'Z');
        await tester.tap(find.text('Temizle'));
        await tester.pump();
        expect(hints.length, 1);
        expect(letters.length, 1);
      }
    });
  }
  testWidgets('loading/unavailable cannot grant hints', (tester) async {
    var mutations = 0;
    await open(
      tester,
      FakeRewardedHintAdService(ready: false, loading: true),
      (_, _) => mutations++,
    );
    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Reklam hazırlanıyor'),
    );
    expect(button.onPressed, isNull);
    expect(mutations, 0);
  });
  testWidgets('unavailable ad offers retry without a free fallback', (
    tester,
  ) async {
    final ad = FakeRewardedHintAdService(ready: false);
    var mutations = 0;
    await open(tester, ad, (_, _) => mutations++);
    await tester.tap(find.text('Reklamla Harf Aç'));
    await tester.pump();
    expect(ad.shows, 0);
    expect(mutations, 0);
    expect(
      find.text('Reklam şu anda hazır değil. Lütfen tekrar deneyin.'),
      findsOneWidget,
    );
  });
  testWidgets('captures original cell and repeated reward cannot grant twice', (
    tester,
  ) async {
    final ad = _PendingAd();
    Set<GridPosition> hints = {};
    await open(tester, ad, (_, h) => hints = h);
    final original = manualPuzzle.answers.first.start;
    final other = manualPuzzle.answers.first.positions[1];
    await tester.tap(find.text('Reklamla Harf Aç'));
    await tester.pump();
    await tester.tap(find.byKey(ValueKey('cell-${other.row}-${other.column}')));
    ad.reward();
    ad.reward();
    await tester.pumpAndSettle();
    expect(hints, {original});
    expect(ad.shows, 1);
  });
  testWidgets('captured cell is revalidated after reward', (tester) async {
    final ad = _PendingAd();
    Set<GridPosition> hints = {};
    await open(tester, ad, (_, h) => hints = h);
    await tester.tap(find.text('Reklamla Harf Aç'));
    await tester.pump();
    // Simulate an external state update during the ad. The in-app keyboard is
    // intentionally disabled until dismissal, but reward revalidation remains.
    final dynamic state = tester.state(find.byType(PuzzleScreen));
    state.game.enterLetter(manualPuzzle.answers.first.solution[0]);
    ad.reward();
    await tester.pumpAndSettle();
    expect(hints, isEmpty);
  });
  testWidgets('reward after screen disposal is ignored', (tester) async {
    final ad = _PendingAd();
    var mutations = 0;
    await open(tester, ad, (_, _) => mutations++);
    await tester.tap(find.text('Reklamla Harf Aç'));
    await tester.pumpWidget(const SizedBox());
    ad.reward();
    await tester.pump();
    expect(mutations, 0);
    expect(tester.takeException(), isNull);
  });
}
