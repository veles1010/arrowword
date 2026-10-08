import 'dart:math' as math;

import 'package:arrowword/features/puzzle/data/manual_puzzle.dart';
import 'package:arrowword/features/puzzle/presentation/puzzle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final scenario in [
    (name: 'narrow closed', width: 320.0, height: 640.0, inset: 0.0),
    (name: 'narrow open', width: 320.0, height: 640.0, inset: 240.0),
    (name: 'wide closed', width: 412.0, height: 844.0, inset: 0.0),
    (name: 'wide open', width: 412.0, height: 844.0, inset: 300.0),
  ]) {
    testWidgets('${scenario.name}: square 10 by 7 board and usable controls', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(scenario.width, scenario.height);
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 16);
      tester.view.padding = FakeViewPadding(
        top: 24,
        bottom: scenario.inset > 0 ? 0 : 16,
      );
      tester.view.viewInsets = FakeViewPadding(bottom: scenario.inset);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: PuzzleScreen(puzzle: manualPuzzle)),
      );
      expect(tester.takeException(), isNull);

      final board = tester.getRect(find.byKey(const ValueKey('puzzle-board')));
      final first = tester.getRect(find.byKey(const ValueKey('cell-0-1')));
      final last = tester.getRect(find.byKey(const ValueKey('cell-9-7')));
      final nextRow = tester.getRect(find.byKey(const ValueKey('cell-1-1')));
      expect(first.width, closeTo(first.height, 0.001));
      expect(board.width, closeTo(first.width * 7, 0.001));
      expect(board.height, closeTo(first.height * 10, 0.001));
      expect(nextRow.top, closeTo(first.bottom, 0.001));
      expect(last.bottom, closeTo(board.bottom, 0.001));
      expect(last.right, closeTo(board.right, 0.001));
      expect(board.center.dx, closeTo(scenario.width / 2, 0.001));
      expect(board.left, greaterThanOrEqualTo(10));
      final activeClue = find.byKey(const ValueKey('active-clue'));
      expect(tester.getRect(activeClue).bottom, lessThanOrEqualTo(board.top));
      // The persistent in-app keyboard now reserves height even without an IME.
      final boardArea = tester.getSize(
        find
            .ancestor(
              of: find.byKey(const ValueKey('puzzle-board')),
              matching: find.byType(Center),
            )
            .first,
      );
      expect(
        board.width,
        closeTo(math.min(scenario.width - 20, boardArea.height * 0.7), 0.001),
      );

      for (final label in ['Temizle', 'Kontrol Et']) {
        final control = find.widgetWithText(
          label == 'Temizle' ? OutlinedButton : FilledButton,
          label,
        );
        expect(control.hitTestable(), findsOneWidget);
        expect(
          tester.getRect(control).bottom,
          lessThanOrEqualTo(scenario.height - scenario.inset),
        );
      }
      // The displayed clue at logical (2,4) must still select TABLE.
      await tester.tap(find.byKey(const ValueKey('cell-2-4')));
      await tester.pump();
      expect(find.text('Masa (5)'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 't');
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('cell-3-4')),
          matching: find.text('T'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'opening and closing keyboard preserves input and board mapping',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 740);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: PuzzleScreen(puzzle: manualPuzzle)),
      );
      final boardFinder = find.byKey(const ValueKey('puzzle-board'));
      final closedSize = tester.getSize(boardFinder);
      await tester.tap(find.byKey(const ValueKey('cell-3-1')));
      await tester.enterText(find.byType(TextField), 'w');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      final openSize = tester.getSize(boardFinder);
      expect(openSize.height, lessThan(closedSize.height));
      expect(openSize.width / openSize.height, closeTo(0.7, 0.001));
      expect(find.text('Su (5)'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('cell-3-2')),
          matching: find.text('W'),
        ),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), 'a');
      tester.view.viewInsets = const FakeViewPadding();
      await tester.pumpAndSettle();
      expect(tester.getSize(boardFinder), closedSize);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('cell-3-3')),
          matching: find.text('A'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('grid delegate uses visible columns, not logical columns', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: PuzzleScreen(puzzle: manualPuzzle)),
    );
    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, manualPuzzle.displayBounds.columnCount);
  });
}
