import 'package:arrowword/app/fluid_navigation_bar.dart';
import 'package:arrowword/app/arrowword_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<List<int>> pump(
    WidgetTester tester, {
    bool dark = false,
    double scale = 1,
    bool reducedMotion = false,
  }) async {
    final commits = <int>[];
    var index = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: dark ? ArrowwordTheme.dark() : ArrowwordTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(scale),
            disableAnimations: reducedMotion,
          ),
          child: Scaffold(
            bottomNavigationBar: StatefulBuilder(
              builder: (context, setState) => FluidNavigationBar(
                index: index,
                onSelected: (value) {
                  commits.add(value);
                  setState(() => index = value);
                },
              ),
            ),
          ),
        ),
      ),
    );
    return commits;
  }

  Finder item(int i) => find.byKey(ValueKey('navigation-$i'));
  Finder getPill() => find.byKey(const ValueKey('navigation-pill'));
  testWidgets('tap all items moves one pill and selects semantic destination', (
    tester,
  ) async {
    await pump(tester);
    final semantics = tester.ensureSemantics();
    for (var i = 0; i < 4; i++) {
      await tester.tap(item(i));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(getPill()).dx,
        closeTo(tester.getTopLeft(item(i)).dx + 4, .01),
      );
      expect(
        tester
            .getSemantics(find.bySemanticsLabel(shellLabels[i]))
            .flagsCollection
            .isSelected
            .toBoolOrNull(),
        isTrue,
      );
    }
    semantics.dispose();
  });
  testWidgets(
    'slow drag follows fractional positions without committing until release',
    (tester) async {
      final commits = await pump(tester);
      final start = tester.getTopLeft(getPill()).dx;
      final width = tester.getSize(item(0)).width;
      final gesture = await tester.startGesture(tester.getCenter(item(0)));
      await gesture.moveBy(Offset(width * .35, 0));
      await tester.pump();
      final first = tester.getTopLeft(getPill()).dx;
      expect(first, greaterThan(start));
      expect(first, lessThan(start + width));
      await gesture.moveBy(Offset(width * .35, 0));
      await tester.pump();
      expect(tester.getTopLeft(getPill()).dx, greaterThan(first));
      expect(commits, isEmpty);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(commits, [1]);
    },
  );
  testWidgets('drag out then back and partial release return to original', (
    tester,
  ) async {
    final commits = await pump(tester);
    final width = tester.getSize(item(0)).width;
    final gesture = await tester.startGesture(tester.getCenter(item(0)));
    await gesture.moveBy(Offset(width * 1.4, 0));
    await tester.pump();
    await gesture.moveBy(Offset(-width * 1.1, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(commits.last, 0);
    await tester.tap(item(2));
    await tester.pumpAndSettle();
    expect(commits.last, 2);
  });
  testWidgets('first last edges clamp', (tester) async {
    final commits = await pump(tester);
    await tester.drag(item(0), const Offset(-2000, 0));
    await tester.pumpAndSettle();
    expect(commits.last, 0);
    expect(tester.getTopLeft(getPill()).dx, tester.getTopLeft(item(0)).dx + 4);
    await tester.drag(item(0), const Offset(2000, 0));
    await tester.pumpAndSettle();
    expect(commits.last, 3);
    expect(
      tester.getTopLeft(getPill()).dx,
      closeTo(tester.getTopLeft(item(3)).dx + 4, .01),
    );
  });
  testWidgets('tiny movement and vertical intent do not switch', (
    tester,
  ) async {
    final commits = await pump(tester);
    await tester.drag(item(0), const Offset(4, 0));
    await tester.pumpAndSettle();
    expect(commits.every((i) => i == 0), isTrue);
    await tester.drag(item(0), const Offset(4, -100));
    await tester.pumpAndSettle();
    expect(commits.every((i) => i == 0), isTrue);
  });
  testWidgets('fast swipe uses nearest final position', (tester) async {
    final commits = await pump(tester);
    final width = tester.getSize(item(0)).width;
    await tester.fling(item(0), Offset(width * 1.2, 0), 1200);
    await tester.pumpAndSettle();
    expect(commits.last, 1);
  });
  testWidgets('compact dark bar handles 1.5x text', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pump(tester, dark: true, scale: 1.5);
    await tester.tap(item(3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(item(0)).height, greaterThanOrEqualTo(48));
  });
  testWidgets(
    'very large labels expand safely and reduced motion settles immediately',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pump(tester, scale: 3, reducedMotion: true);
      await tester.tap(item(3));
      await tester.pump();
      expect(
        tester.getTopLeft(getPill()).dx,
        closeTo(tester.getTopLeft(item(3)).dx + 4, .01),
      );
      expect(
        tester.getSize(getPill()).width,
        tester.getSize(item(3)).width - 8,
      );
      for (final label in shellLabels) {
        expect(find.text(label), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );
}
