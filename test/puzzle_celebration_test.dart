import 'package:arrowword/features/puzzle/presentation/puzzle_celebration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> showResult(
    WidgetTester tester, {
    bool reducedMotion = false,
    bool celebrate = true,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorSchemeSeed: Colors.blue),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    disableAnimations: reducedMotion,
                    textScaler: TextScaler.linear(textScale),
                  ),
                  child: PuzzleCelebration(
                    celebrate: celebrate,
                    child: AlertDialog(
                      scrollable: true,
                      title: const PuzzleCompletionTitle('Completed'),
                      content: const Text('Score: 1400'),
                      actions: [
                        FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Next'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              child: const Text('Show'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Show'));
    await tester.pump();
  }

  testWidgets('confetti ends and leaves no repeating animation', (tester) async {
    await showResult(tester);
    expect(find.byKey(const ValueKey('completion-confetti')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('completion-confetti')), findsNothing);
    expect(find.text('Score: 1400'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('confetti does not intercept the next action', (tester) async {
    await showResult(tester);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Completed'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion and restored results are quiet', (tester) async {
    await showResult(tester, reducedMotion: true);
    expect(find.byKey(const ValueKey('completion-confetti')), findsNothing);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await showResult(tester, celebrate: false);
    expect(find.byKey(const ValueKey('completion-confetti')), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('large text keeps the result action reachable', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await showResult(tester, reducedMotion: true, textScale: 2);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Completed'), findsNothing);
  });
}
