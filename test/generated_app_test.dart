import 'package:arrowword/app/app.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_generator.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:arrowword/features/puzzle/presentation/puzzle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SequencePuzzleResult generated;
  setUpAll(() => generated = generatePrototypePuzzle());

  testWidgets('fixed-seed generated board renders and survives app rebuild', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ArrowwordApp(generation: generated));
    final first = generated.puzzle!.answers.first;
    expect(generated.puzzleIndex, 1);
    expect(generated.generationPoolCount, 300);
    expect(generated.attempts.single.pool.includedUsageTiers, [0]);
    expect(generated.seed, derivePuzzleSeed(prototypeBaseSeed, 1));
    expect(generated.puzzle!.id, 'generated-v3-000001');
    expect(
      tester.widget<PuzzleScreen>(find.byType(PuzzleScreen)).puzzle,
      same(generated.puzzle),
    );
    await tester.tap(
      find.byKey(
        ValueKey('cell-${first.cluePosition.row}-${first.cluePosition.column}'),
      ),
    );
    await tester.enterText(find.byType(TextField), first.solution[0]);
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pumpWidget(ArrowwordApp(generation: generated));
    expect(
      tester.widget<PuzzleScreen>(find.byType(PuzzleScreen)).puzzle,
      same(generated.puzzle),
    );
    expect(
      find.descendant(
        of: find.byKey(
          ValueKey('cell-${first.start.row}-${first.start.column}'),
        ),
        matching: find.text(first.solution[0]),
      ),
      findsOneWidget,
    );
    expect(find.text('${first.turkishClue} (${first.length})'), findsOneWidget);
    expect(find.text('Kontrol Et').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('generation failure displays reason without manual fallback', (
    tester,
  ) async {
    final failure = PuzzleSequenceGenerator(
      prototypeCatalogue,
      const PuzzleSequenceConfig(
        baseSeed: prototypeBaseSeed,
        generation: PuzzleGenerationConfig(maxSearchNodes: 1),
      ),
    ).generateNext(puzzleIndex: 1);
    await tester.pumpWidget(ArrowwordApp(generation: failure));
    expect(find.byType(PuzzleScreen), findsNothing);
    expect(find.textContaining('Bulmaca oluşturulamadı'), findsOneWidget);
    expect(find.textContaining(failure.failureReason!), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
