import 'package:arrowword/app/development_puzzle.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'development launch defaults to index 1 and rejects invalid indices',
    () {
      expect(developmentPuzzleIndex(), 1);
      for (final value in ['0', '-1', 'invalid', '4294967296']) {
        expect(() => developmentPuzzleIndex(value), throwsArgumentError);
      }
    },
  );

  test('overridden index replays normal balanced history', () {
    final result = generateDevelopmentPuzzle(developmentPuzzleIndex('2'));
    final first = generatePrototypePuzzle();
    final expected = PuzzleSequenceGenerator(
      prototypeCatalogue,
      prototypeSequenceConfig,
    ).generateNext(puzzleIndex: 2, history: [first.toHistory()]);
    expect(result.isSuccess, isTrue, reason: result.failureReason);
    expect(result.puzzleIndex, 2);
    expect(
      result.generation!.metrics!.structuralSignature,
      expected.generation!.metrics!.structuralSignature,
    );
    expect(
      result.pool.excludedRecentIds.toSet(),
      first.puzzle!.answers.map((a) => a.id).toSet(),
    );
  });
}
