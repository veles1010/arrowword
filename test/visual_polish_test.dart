import 'package:arrowword/app/arrowword_theme.dart';
import 'package:arrowword/app/fluid_navigation_bar.dart';
import 'package:arrowword/app/puzzle_difficulty_selector.dart';
import 'package:arrowword/app/puzzle_progression_screen.dart';
import 'package:arrowword/app/puzzle_session.dart';
import 'package:arrowword/app/player_puzzle_tracks.dart';
import 'package:arrowword/app/puzzle_track.dart';
import 'package:arrowword/app/puzzle_progress_store.dart';
import 'package:arrowword/app/statistics_screen.dart';
import 'package:arrowword/features/puzzle/data/manual_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_difficulty.dart';
import 'package:arrowword/features/puzzle/presentation/puzzle_screen.dart';
import 'package:arrowword/theme/arrowword_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
}

void main() {
  for (final dark in [false, true]) {
    final theme = dark ? ArrowwordTheme.dark() : ArrowwordTheme.light();
    final visuals = theme.extension<ArrowwordVisuals>()!,
        cs = theme.colorScheme;
    test('distinct square board surface hierarchy, dark=$dark', () {
      expect({
        visuals.puzzlePage,
        visuals.cell,
        visuals.clue,
        visuals.unused,
      }, hasLength(4));
      expect(visuals.active, isNot(visuals.cell));
      expect(visuals.hintActive, isNot(visuals.active));
      expect(visuals.active, isNot(cs.primary));
      if (dark) {
        expect(
          visuals.puzzlePage.computeLuminance(),
          lessThan(visuals.unused.computeLuminance()),
        );
        expect(
          visuals.unused.computeLuminance(),
          lessThan(visuals.cell.computeLuminance()),
        );
        expect(
          visuals.cell.computeLuminance(),
          lessThan(visuals.clue.computeLuminance()),
        );
      } else {
        expect(visuals.cell, const Color(0xffffffff));
        expect(
          visuals.clue.computeLuminance(),
          lessThan(visuals.unused.computeLuminance()),
        );
        expect(
          visuals.unused.computeLuminance(),
          lessThan(visuals.puzzlePage.computeLuminance()),
        );
      }
      expect(visuals.gridBorder.a, 1);
      expect(
        visuals.gridBorder,
        isNot(cs.outlineVariant.withValues(alpha: .7)),
      );
    });
    test(
      'letters, clues and restrained difficulty accents maintain readable contrast, dark=$dark',
      () {
        for (final pair in [
          (cs.onSurface, visuals.cell),
          (cs.onTertiaryContainer, visuals.clue),
          (cs.onSecondaryContainer, visuals.active),
          (cs.onSecondaryContainer, visuals.hintActive),
          (cs.onPrimary, cs.primary),
          (cs.onErrorContainer, cs.errorContainer),
          (cs.onSurfaceVariant, cs.surfaceContainerLow),
        ]) {
          expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
        }
        final accents = PuzzleDifficulty.values
            .map((d) => visuals.difficultyAccent(d, cs))
            .toSet();
        expect(accents, hasLength(3));
        for (final accent in accents) {
          expect(
            contrast(accent, cs.secondaryContainer),
            greaterThanOrEqualTo(4.5),
          );
        }
      },
    );
    testWidgets(
      'actual cell state precedence and hint cues remain square, dark=$dark',
      (tester) async {
        const hint = GridPosition(3, 3),
            wrong = GridPosition(3, 2),
            activeWrong = GridPosition(3, 4);
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: PuzzleScreen(
              puzzle: manualPuzzle,
              initialRevealedCells: {hint},
              initialLetters: {wrong: 'Z', activeWrong: 'Z'},
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
            .map((w) => w.decoration)
            .whereType<BoxDecoration>()
            .first;
        expect(
          tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
          visuals.puzzlePage,
        );
        expect(box(const GridPosition(8, 2)).color, visuals.cell);
        expect(box(const GridPosition(3, 1)).color, visuals.clue);
        expect(
          (box(const GridPosition(3, 1)).border! as Border).top.color,
          visuals.gridBorder,
        );
        expect(box(activeWrong).color, visuals.active);
        expect(box(hint).color, visuals.hintActive);
        expect(box(wrong).color, cs.primary);
        expect(
          (box(wrong).border! as Border).top.width,
          greaterThan((box(activeWrong).border! as Border).top.width),
        );
        final unused =
            [
              for (
                var r = manualPuzzle.displayBounds.minRow;
                r <= manualPuzzle.displayBounds.maxRow;
                r++
              )
                for (
                  var c = manualPuzzle.displayBounds.minColumn;
                  c <= manualPuzzle.displayBounds.maxColumn;
                  c++
                )
                  GridPosition(r, c),
            ].firstWhere(
              (p) => manualPuzzle.cellAt(p).type == PuzzleCellType.blocked,
            );
        expect(
          tester
              .widget<ColoredBox>(
                find.descendant(
                  of: cell(unused),
                  matching: find.byType(ColoredBox),
                ),
              )
              .color,
          visuals.unused,
        );
        await tester.tap(cell(const GridPosition(8, 2)));
        await tester.pump();
        expect(box(hint).color, cs.primaryContainer);
        expect((box(hint).border! as Border).bottom.width, 3);
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
        await tester.tap(cell(hint));
        await tester.pump();
        expect(box(hint).color, cs.primary);
        expect((box(hint).border! as Border).bottom.color, cs.onPrimary);
        await tester.tap(cell(wrong));
        await tester.tap(find.text('Kontrol Et'));
        await tester.pump();
        expect(box(wrong).color, cs.errorContainer);
        expect(box(activeWrong).color, cs.errorContainer);
        expect((box(wrong).border! as Border).top.color, cs.error);
        for (final p in [hint, wrong, activeWrong, const GridPosition(3, 1)]) {
          expect(box(p).borderRadius, isNull);
        }
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
    testWidgets(
      'narrow puzzle and keyboard with scale 1.3 stay usable, dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.3),
                viewInsets: const EdgeInsets.only(bottom: 220),
              ),
              child: child!,
            ),
            home: PuzzleScreen(puzzle: manualPuzzle),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Kontrol Et'), findsOneWidget);
        expect(find.text('Temizle'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'W');
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'approved nav radii, surface and pill insets are unchanged, dark=$dark',
      (tester) async {
        var index = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: StatefulBuilder(
              builder: (context, setState) => Scaffold(
                bottomNavigationBar: FluidNavigationBar(
                  index: index,
                  onSelected: (value) => setState(() => index = value),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final pill = find.byKey(const ValueKey('navigation-pill'));
        final decoration =
            tester.widget<DecoratedBox>(pill).decoration as BoxDecoration;
        expect(decoration.borderRadius, BorderRadius.circular(14));
        final frozenSurface = dark
            ? const Color(0xff202125)
            : const Color(0xffffffff);
        final frozenPrimary = dark
            ? const Color(0xff9bbcff)
            : const Color(0xff2864d7);
        expect(
          decoration.color,
          Color.alphaBlend(
            frozenPrimary.withValues(alpha: dark ? .12 : .07),
            frozenSurface,
          ),
        );
        final outer = tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: find.byType(FluidNavigationBar),
                matching: find.byType(DecoratedBox),
              ),
            )
            .map((w) => w.decoration)
            .whereType<BoxDecoration>()
            .singleWhere((b) => b.borderRadius == BorderRadius.circular(20));
        expect(outer.color, frozenSurface);
        final item = find.byKey(const ValueKey('navigation-0'));
        expect(
          tester.getTopLeft(pill).dx,
          closeTo(tester.getTopLeft(item).dx + 4, .01),
        );
        expect(
          tester.getSize(pill).width,
          closeTo(tester.getSize(item).width - 8, .01),
        );
        await tester.tap(find.byKey(const ValueKey('navigation-2')));
        await tester.pumpAndSettle();
        expect(index, 2);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'difficulty label accents change without recoloring whole surfaces, dark=$dark',
      (tester) async {
        var selected = PuzzleDifficulty.easy;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: StatefulBuilder(
              builder: (context, setState) => Scaffold(
                body: PuzzleDifficultySelector(
                  selected: selected,
                  onChanged: (d) => setState(() => selected = d),
                ),
              ),
            ),
          ),
        );
        for (final d in PuzzleDifficulty.values) {
          await tester.tap(find.text(d.turkishLabel));
          await tester.pumpAndSettle();
          final text = tester.widget<Text>(find.text(d.turkishLabel));
          expect(text.style!.color, visuals.difficultyAccent(d, cs));
          expect(text.style!.decoration, TextDecoration.underline);
        }
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'statistics icons follow selected difficulty while cards stay neutral, dark=$dark',
      (tester) async {
        final tracks = (await tester.runAsync(
          () => PlayerPuzzleTracks.restore(
            lastStore: MemoryLastPuzzleDifficultyStore(),
            tracks: {
              for (final d in PuzzleDifficulty.values)
                d: PuzzleTrack(
                  configuration: PuzzleTrackConfiguration.forDifficulty(d),
                  store: MemoryPuzzleProgressStore(),
                ),
            },
          ),
        ))!;
        addTearDown(tracks.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: StatisticsScreen(tracks: tracks),
          ),
        );
        await tester.pumpAndSettle();
        for (final d in PuzzleDifficulty.values) {
          await tester.tap(find.text(d.turkishLabel));
          await tester.pumpAndSettle();
          final card = find.byKey(const ValueKey('statistics-total'));
          final icon = tester.widget<Icon>(
            find.descendant(of: card, matching: find.byType(Icon)),
          );
          expect(icon.color, visuals.difficultyAccent(d, cs));
          expect(
            tester
                .widget<Card>(
                  find.descendant(of: card, matching: find.byType(Card)),
                )
                .color,
            isNull,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'progression keeps current blue, completed check and muted disabled lock',
    (tester) async {
      final session = PuzzleSession(startIndex: 2);
      addTearDown(session.dispose);
      final theme = ArrowwordTheme.dark();
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: PuzzleProgressionScreen(
            session: session,
            puzzleBuilder: (_) => const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Finder tile(int n) => find.byKey(ValueKey('puzzle-tile-$n'));
      Icon icon(int n) => tester.widget<Icon>(
        find.descendant(of: tile(n), matching: find.byType(Icon)).first,
      );
      expect(icon(1).icon, Icons.check_circle_outline);
      expect(icon(2).icon, Icons.play_arrow);
      expect(icon(3).icon, Icons.lock_outline);
      expect(icon(3).color, theme.colorScheme.outline);
      expect(tester.widget<InkWell>(tile(3)).onTap, isNull);
      expect(icon(2).color, theme.colorScheme.onPrimaryContainer);
      expect(tester.takeException(), isNull);
    },
  );
}
