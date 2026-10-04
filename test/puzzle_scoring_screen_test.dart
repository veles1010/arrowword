import 'dart:async';

import 'package:arrowword/features/puzzle/ads/rewarded_hint_ad_service.dart';
import 'package:arrowword/features/puzzle/data/manual_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_score.dart';
import 'package:arrowword/features/puzzle/presentation/puzzle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<GridPosition, String> _solution() => {
  for (final answer in manualPuzzle.answers)
    for (var i = 0; i < answer.length; i++)
      answer.positions[i]: answer.solution[i],
};

Widget _app(PuzzleScreen screen, {GlobalKey<NavigatorState>? navigatorKey}) =>
    MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [puzzleRouteObserver],
      home: screen,
    );

class _PendingAd extends FakeRewardedHintAdService {
  final reward = Completer<HintAdResult>();
  @override
  Future<HintAdResult> show() => reward.future;
}

void main() {
  testWidgets('inactive time is excluded and active time checkpoints', (
    tester,
  ) async {
    var now = Duration.zero;
    final checkpoints = <Duration>[];
    await tester.pumpWidget(
      _app(
        PuzzleScreen(
          puzzle: manualPuzzle,
          monotonicNow: () => now,
          onElapsedChanged: checkpoints.add,
        ),
      ),
    );
    now += const Duration(seconds: 9);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    expect(checkpoints.last, const Duration(seconds: 9));
    now += const Duration(hours: 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(checkpoints.last, const Duration(seconds: 9));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    now += const Duration(seconds: 4);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    expect(checkpoints.last, const Duration(seconds: 13));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('rewarded hint time excludes the full-screen ad', (tester) async {
    var now = Duration.zero;
    final ad = _PendingAd();
    final letters = _solution()..remove(manualPuzzle.answers.first.start);
    Duration? elapsed;
    var hints = 0;
    CompletedPuzzleScore? score;
    await tester.pumpWidget(
      _app(
        PuzzleScreen(
          puzzle: manualPuzzle,
          initialLetters: letters,
          rewardedAdFactory: () => ad,
          monotonicNow: () => now,
          onAttemptProgress: (_, revealed, time, _) {
            elapsed = time;
            hints = revealed.length;
          },
          onCompleted: () => score = CompletedPuzzleScore.calculate(
            puzzleIndex: 1,
            elapsedSeconds: elapsed!.inSeconds,
            hintsUsed: hints,
            wrongChecks: 0,
          ),
          scoreResult: () => score,
        ),
      ),
    );
    now = const Duration(seconds: 121);
    await tester.tap(find.text('Reklamla Harf Aç'));
    await tester.pump();
    now += const Duration(hours: 2);
    ad.reward.complete(HintAdResult.earned);
    await tester.pumpAndSettle();
    expect(score!.score, 1200);
    expect(score!.elapsedSeconds, 121);
    expect(score!.hintsUsed, 1);
    expect(find.text('Bulmaca tamamlandı!'), findsOneWidget);
  });

  testWidgets('covered route pauses until it is revealed', (tester) async {
    var now = Duration.zero;
    final checkpoints = <Duration>[];
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      _app(
        PuzzleScreen(
          puzzle: manualPuzzle,
          monotonicNow: () => now,
          onElapsedChanged: checkpoints.add,
        ),
        navigatorKey: navigator,
      ),
    );
    now += const Duration(seconds: 6);
    navigator.currentState!.push<void>(
      MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Covered'))),
    );
    await tester.pumpAndSettle();
    expect(checkpoints.last, const Duration(seconds: 6));
    now += const Duration(minutes: 20);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    now += const Duration(seconds: 2);
    await tester.pumpWidget(const SizedBox());
    expect(checkpoints.last, const Duration(seconds: 8));
  });

  testWidgets('selection does not persist an attempt mutation', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _app(
        PuzzleScreen(
          puzzle: manualPuzzle,
          monotonicNow: () => Duration.zero,
          onAttemptProgress: (_, _, _, _) => calls++,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('cell-2-4')));
    await tester.pump();
    expect(calls, 0);
  });

  testWidgets('mutations persist time and checks before completion score', (
    tester,
  ) async {
    var now = Duration.zero;
    final missing = manualPuzzle.answers.first.start;
    final letters = _solution()..remove(missing);
    Duration? persistedElapsed;
    var persistedChecks = 0;
    CompletedPuzzleScore? score;
    await tester.pumpWidget(
      _app(
        PuzzleScreen(
          puzzle: manualPuzzle,
          initialLetters: letters,
          monotonicNow: () => now,
          onAttemptProgress: (_, _, elapsed, checks) {
            persistedElapsed = elapsed;
            persistedChecks = checks;
          },
          onCompleted: () {
            score = CompletedPuzzleScore.calculate(
              puzzleIndex: 1,
              elapsedSeconds: persistedElapsed!.inSeconds,
              hintsUsed: 0,
              wrongChecks: persistedChecks,
            );
          },
          scoreResult: () => score,
        ),
      ),
    );
    now = const Duration(seconds: 5);
    await tester.tap(
      find.byKey(ValueKey('cell-${missing.row}-${missing.column}')),
    );
    await tester.enterText(find.byType(TextField), 'X');
    await tester.pump();
    expect(persistedElapsed, const Duration(seconds: 5));
    await tester.tap(find.text('Kontrol Et'));
    await tester.pump();
    expect(persistedChecks, 1);
    now = const Duration(seconds: 12);
    await tester.tap(
      find.byKey(ValueKey('cell-${missing.row}-${missing.column}')),
    );
    await tester.enterText(find.byType(TextField), 'W');
    await tester.pumpAndSettle();
    expect(persistedElapsed, const Duration(seconds: 12));
    expect(find.text('Bulmaca tamamlandı!'), findsOneWidget);
    expect(
      find.text('Puan: 1375\nSüre: 00:12\nİpucu: 0\nHatalı kontrol: 1'),
      findsOneWidget,
    );
    now += const Duration(hours: 3);
    await tester.pump();
    expect(score!.elapsedSeconds, 12);
  });

  for (final legacy in [false, true]) {
    testWidgets(
      'restored finalized ${legacy ? 'legacy' : 'scored'} completion',
      (tester) async {
        var now = Duration.zero;
        final record = CompletedPuzzleScore.calculate(
          puzzleIndex: 1,
          elapsedSeconds: 150,
          hintsUsed: 2,
          wrongChecks: 3,
        );
        final checkpoints = <Duration>[];
        await tester.pumpWidget(
          _app(
            PuzzleScreen(
              puzzle: manualPuzzle,
              initialLetters: _solution(),
              initialElapsed: const Duration(seconds: 150),
              initialWrongChecks: 3,
              attemptFinalized: true,
              monotonicNow: () => now,
              onElapsedChanged: checkpoints.add,
              scoreResult: () => legacy ? null : record,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            legacy
                ? 'Bu bulmaca puanlama sistemi eklenmeden önce tamamlandı.'
                : 'Puan: 1025\nSüre: 02:30\nİpucu: 2\nHatalı kontrol: 3',
          ),
          findsOneWidget,
        );
        now += const Duration(hours: 2);
        await tester.tap(find.text('Kapat'));
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
        expect(checkpoints.last, const Duration(seconds: 150));
        expect(record.score, 1025);
      },
    );
  }
}
