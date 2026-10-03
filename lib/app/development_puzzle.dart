import '../features/puzzle/data/prototype_puzzle.dart';
import '../features/puzzle/sequence/puzzle_sequence.dart';

/// Debug launch selector only; release/profile startup remains Puzzle 1.
int developmentPuzzleIndex([String value = '1']) {
  final index = int.tryParse(value);
  if (index == null || index < 1 || index > 0xffffffff) {
    throw ArgumentError.value(
      value,
      'ARROWWORD_PUZZLE_INDEX',
      'Expected an index from 1 to 4294967295.',
    );
  }
  return index;
}

SequencePuzzleResult generateDevelopmentPuzzle(int index) {
  developmentPuzzleIndex(index.toString());
  if (index == 1) return generatePrototypePuzzle();
  // Range replay starts at 1 internally, rebuilding complete usage/cooldown history.
  final result = PuzzleSequenceGenerator(
    prototypeCatalogue,
    prototypeSequenceConfig,
  ).generateRange(startIndex: index, count: 1);
  return result.failure ?? result.puzzles.single;
}
