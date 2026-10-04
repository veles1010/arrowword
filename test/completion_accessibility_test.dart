import 'package:arrowword/features/puzzle/data/manual_puzzle.dart';
import 'package:arrowword/features/puzzle/presentation/puzzle_screen.dart';
import 'package:arrowword/features/puzzle/presentation/puzzle_completion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final mode in ['normal', 'replay', 'daily']) {
    testWidgets('$mode completion scrolls on compact large-text layout', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 480);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        MaterialApp(
          home: PuzzleScreen(
            puzzle: manualPuzzle,
            initialLetters: {
              for (final a in manualPuzzle.answers)
                for (var i = 0; i < a.length; i++)
                  a.positions[i]: a.solution[i],
            },
            completion: mode == 'normal'
                ? null
                : PuzzleCompletionPresentation(
                    title: mode == 'daily'
                        ? 'Günün bulmacası tamamlandı!'
                        : 'Bulmaca tamamlandı!',
                    contentBuilder: (_) => const Text(
                      'Bu deneme: 1250\nEn iyi: 1400\nSüre: 05:00\nİpucu: 1\nHatalı kontrol: 2\nYeni rekor!',
                    ),
                    actionLabel: mode == 'daily'
                        ? 'Ana Sayfaya Dön'
                        : 'Bulmacalara Dön',
                    onFinished: () {},
                  ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<AlertDialog>(find.byType(AlertDialog)).scrollable,
        isTrue,
      );
      expect(find.byType(SingleChildScrollView), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
