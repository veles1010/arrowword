import '../features/puzzle/data/prototype_puzzle.dart';
import '../features/puzzle/sequence/puzzle_sequence.dart';
import '../features/puzzle/domain/puzzle_difficulty.dart';
import '../features/puzzle/domain/normal_puzzle_contract.dart';
import 'puzzle_track.dart';

/// Debug/profile launch selector; release startup always uses player progression.
int developmentPuzzleIndex([String value = '1']) {
  final index = int.tryParse(value);
  if (index == null || !isNormalPuzzleIndex(index)) {
    throw ArgumentError.value(
      value,
      'ARROWWORD_PUZZLE_INDEX',
      'Expected an index from 1 to $normalPuzzleCount.',
    );
  }
  return index;
}

PuzzleDifficulty developmentPuzzleDifficulty([String value = 'easy']) =>
    switch (value) {
      'easy' => PuzzleDifficulty.easy,
      'medium' => PuzzleDifficulty.medium,
      'hard' => PuzzleDifficulty.hard,
      _ => throw ArgumentError.value(
        value,
        'ARROWWORD_PUZZLE_DIFFICULTY',
        'Expected easy, medium or hard.',
      ),
    };

class DevelopmentPuzzleLaunch {
  const DevelopmentPuzzleLaunch(this.index, this.difficulty);
  final int index;
  final PuzzleDifficulty difficulty;
}

/// Parse before opening any player store. Profile is supported for playtesting;
/// release ignores all development defines, including malformed ones.
DevelopmentPuzzleLaunch? resolveDevelopmentPuzzleLaunch({
  required bool indexProvided,
  required bool releaseMode,
  String index = '1',
  String difficulty = 'easy',
}) {
  if (releaseMode || !indexProvided) return null;
  return DevelopmentPuzzleLaunch(
    developmentPuzzleIndex(index),
    developmentPuzzleDifficulty(difficulty),
  );
}

/// Without an override index, even a supplied/invalid difficulty is ignored.
PuzzleTrackConfiguration developmentTrackConfiguration(
  int? index, [
  String value = 'easy',
]) => index == null
    ? PuzzleTrackConfiguration.easy
    : PuzzleTrackConfiguration.forDifficulty(
        developmentPuzzleDifficulty(value),
      );

SequencePuzzleResult generateDevelopmentPuzzle(
  int index, {
  PuzzleDifficulty difficulty = PuzzleDifficulty.easy,
}) {
  developmentPuzzleIndex(index.toString());
  if (index == 1 && difficulty == PuzzleDifficulty.easy) {
    return generatePrototypePuzzle();
  }
  // Range replay starts at 1 internally, rebuilding complete usage/cooldown history.
  final result = PuzzleTrackConfiguration.forDifficulty(difficulty)
      .createGenerator!()
      .generateRange(startIndex: index, count: 1);
  return result.failure ?? result.puzzles.single;
}
