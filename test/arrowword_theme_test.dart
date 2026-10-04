import 'package:arrowword/app/arrowword_theme.dart';
import 'package:arrowword/features/puzzle/data/manual_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/presentation/puzzle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final dark in [false, true]) {
    final theme = dark ? ArrowwordTheme.dark() : ArrowwordTheme.light();
    test(
      'blue neutral ${dark ? 'dark' : 'light'} palette has readable contrast',
      () {
        final cs = theme.colorScheme;
        final primary = cs.primary;
        expect(primary.b, greaterThan(primary.g));
        expect(primary.b, greaterThan(primary.r));
        double contrast(Color a, Color b) {
          final x = a.computeLuminance(), y = b.computeLuminance();
          return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
        }

        expect(contrast(cs.primary, cs.onPrimary), greaterThanOrEqualTo(4.5));
        expect(
          contrast(cs.secondaryContainer, cs.onSecondaryContainer),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(cs.tertiaryContainer, cs.onTertiaryContainer),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(cs.errorContainer, cs.onErrorContainer),
          greaterThanOrEqualTo(4.5),
        );
        expect((cs.surface.r - cs.surface.g).abs(), lessThan(.03));
      },
    );
    testWidgets(
      'selected active hinted error states ${dark ? 'dark' : 'light'}',
      (tester) async {
        const hint = GridPosition(3, 3);
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: PuzzleScreen(
              puzzle: manualPuzzle,
              initialRevealedCells: {hint},
              initialLetters: {const GridPosition(3, 2): 'Z'},
            ),
          ),
        );
        await tester.pumpAndSettle();
        Finder cell(GridPosition p) =>
            find.byKey(ValueKey('cell-${p.row}-${p.column}'));
        BoxDecoration box(GridPosition p) => tester
            .widgetList<Container>(
              find.descendant(of: cell(p), matching: find.byType(Container)),
            )
            .map((c) => c.decoration)
            .whereType<BoxDecoration>()
            .first;
        await tester.tap(cell(const GridPosition(8, 2)));
        await tester.pump();
        final neutralHint = box(hint);
        expect(neutralHint.color, theme.colorScheme.primaryContainer);
        expect((neutralHint.border! as Border).bottom.width, 3);
        final letter = tester.widget<Text>(
          find.descendant(of: cell(hint), matching: find.byType(Text)).first,
        );
        expect(letter.style!.decoration, TextDecoration.underline);
        expect(letter.style!.decorationThickness, 2);
        final semantics = tester.ensureSemantics();
        expect(
          find.bySemanticsLabel(RegExp('İpucuyla açıldı, kilitli')),
          findsWidgets,
        );
        await tester.tap(cell(const GridPosition(3, 2)));
        await tester.pump();
        expect(box(const GridPosition(3, 2)).color, theme.colorScheme.primary);
        expect(box(hint).color, theme.colorScheme.secondaryContainer);
        expect((box(hint).border! as Border).bottom.width, 3);
        await tester.tap(cell(hint));
        await tester.pump();
        expect(box(hint).color, theme.colorScheme.primary);
        expect(
          (box(hint).border! as Border).bottom.color,
          theme.colorScheme.onPrimary,
        );
        await tester.tap(find.text('Kontrol Et'));
        await tester.pump();
        expect(
          box(const GridPosition(3, 2)).color,
          theme.colorScheme.errorContainer,
        );
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }
}
