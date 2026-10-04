/// Calculates the version 1 score for a completed puzzle.
int calculatePuzzleScore({
  required int elapsedSeconds,
  required int hintsUsed,
  required int wrongChecks,
}) {
  _requireNonnegative(elapsedSeconds, 'elapsedSeconds');
  _requireNonnegative(hintsUsed, 'hintsUsed');
  _requireNonnegative(wrongChecks, 'wrongChecks');
  final bonus = switch (elapsedSeconds) {
    <= 120 => 400,
    <= 180 => 300,
    <= 300 => 200,
    <= 480 => 100,
    _ => 0,
  };
  final score = 1000 + bonus - 100 * hintsUsed - 25 * wrongChecks;
  return score < 0 ? 0 : score;
}

void _requireNonnegative(int value, String name) {
  if (value < 0) {
    throw ArgumentError.value(value, name, 'Must be nonnegative');
  }
}

/// Immutable, validated local record of a completed puzzle's score.
class CompletedPuzzleScore {
  factory CompletedPuzzleScore({
    required int puzzleIndex,
    required int score,
    required int elapsedSeconds,
    required int hintsUsed,
    required int wrongChecks,
    int scoringVersion = 1,
  }) {
    if (puzzleIndex < 1) {
      throw ArgumentError.value(
        puzzleIndex,
        'puzzleIndex',
        'Must be at least 1',
      );
    }
    if (scoringVersion != 1) {
      throw ArgumentError.value(scoringVersion, 'scoringVersion', 'Must be 1');
    }
    final expectedScore = calculatePuzzleScore(
      elapsedSeconds: elapsedSeconds,
      hintsUsed: hintsUsed,
      wrongChecks: wrongChecks,
    );
    if (score != expectedScore) {
      throw ArgumentError.value(score, 'score', 'Must equal $expectedScore');
    }
    return CompletedPuzzleScore._(
      puzzleIndex: puzzleIndex,
      score: score,
      elapsedSeconds: elapsedSeconds,
      hintsUsed: hintsUsed,
      wrongChecks: wrongChecks,
      scoringVersion: scoringVersion,
    );
  }

  const CompletedPuzzleScore._({
    required this.puzzleIndex,
    required this.score,
    required this.elapsedSeconds,
    required this.hintsUsed,
    required this.wrongChecks,
    required this.scoringVersion,
  });

  factory CompletedPuzzleScore.calculate({
    required int puzzleIndex,
    required int elapsedSeconds,
    required int hintsUsed,
    required int wrongChecks,
    int scoringVersion = 1,
  }) => CompletedPuzzleScore(
    puzzleIndex: puzzleIndex,
    score: calculatePuzzleScore(
      elapsedSeconds: elapsedSeconds,
      hintsUsed: hintsUsed,
      wrongChecks: wrongChecks,
    ),
    elapsedSeconds: elapsedSeconds,
    hintsUsed: hintsUsed,
    wrongChecks: wrongChecks,
    scoringVersion: scoringVersion,
  );

  factory CompletedPuzzleScore.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('Puzzle score must be an object');
    }
    int readInt(String key) {
      final value = json[key];
      if (value is! int) {
        throw FormatException('$key must be an integer');
      }
      return value;
    }

    try {
      return CompletedPuzzleScore(
        puzzleIndex: readInt('puzzleIndex'),
        score: readInt('score'),
        elapsedSeconds: readInt('elapsedSeconds'),
        hintsUsed: readInt('hintsUsed'),
        wrongChecks: readInt('wrongChecks'),
        scoringVersion: readInt('scoringVersion'),
      );
    } on ArgumentError catch (error) {
      throw FormatException('Invalid puzzle score: $error');
    }
  }

  final int puzzleIndex;
  final int score;
  final int elapsedSeconds;
  final int hintsUsed;
  final int wrongChecks;
  final int scoringVersion;

  Map<String, Object> toJson() => {
    'puzzleIndex': puzzleIndex,
    'score': score,
    'elapsedSeconds': elapsedSeconds,
    'hintsUsed': hintsUsed,
    'wrongChecks': wrongChecks,
    'scoringVersion': scoringVersion,
  };
}
