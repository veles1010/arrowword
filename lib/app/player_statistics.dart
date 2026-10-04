import '../features/puzzle/domain/puzzle_score.dart';

/// A snapshot derived from the one stored best score for each scored puzzle.
class PlayerStatistics {
  const PlayerStatistics._({
    required this.completedPuzzleCount,
    required this.scoredPuzzleCount,
    required this.totalScore,
    required this.bestScore,
    required this.hintFreeBestScoreCount,
    required this.errorFreeBestScoreCount,
  });

  factory PlayerStatistics.fromScores({
    required int completedThrough,
    required Iterable<CompletedPuzzleScore> scores,
  }) {
    var count = 0;
    var total = 0;
    var hintFree = 0;
    var errorFree = 0;
    CompletedPuzzleScore? best;
    for (final score in scores) {
      count++;
      total += score.score;
      if (score.hintsUsed == 0) hintFree++;
      if (score.wrongChecks == 0) errorFree++;
      if (best == null ||
          score.score > best.score ||
          (score.score == best.score &&
              (score.elapsedSeconds < best.elapsedSeconds ||
                  (score.elapsedSeconds == best.elapsedSeconds &&
                      score.puzzleIndex < best.puzzleIndex)))) {
        best = score;
      }
    }
    return PlayerStatistics._(
      completedPuzzleCount: completedThrough,
      scoredPuzzleCount: count,
      totalScore: total,
      bestScore: best,
      hintFreeBestScoreCount: hintFree,
      errorFreeBestScoreCount: errorFree,
    );
  }

  final int completedPuzzleCount;
  final int scoredPuzzleCount;
  final int totalScore;
  final CompletedPuzzleScore? bestScore;
  final int hintFreeBestScoreCount;
  final int errorFreeBestScoreCount;

  double? get averageScore =>
      scoredPuzzleCount == 0 ? null : totalScore / scoredPuzzleCount;
  int? get maxScore => bestScore?.score;
}
