import 'package:arrowword/app/player_statistics.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_score.dart';
import 'package:flutter_test/flutter_test.dart';

CompletedPuzzleScore _score(
  int index,
  int seconds, {
  int hints = 0,
  int wrong = 0,
}) => CompletedPuzzleScore.calculate(
  puzzleIndex: index,
  elapsedSeconds: seconds,
  hintsUsed: hints,
  wrongChecks: wrong,
);

void main() {
  test('empty statistics have no average or best score', () {
    final statistics = PlayerStatistics.fromScores(
      completedThrough: 0,
      scores: const [],
    );
    expect(statistics.completedPuzzleCount, 0);
    expect(statistics.scoredPuzzleCount, 0);
    expect(statistics.totalScore, 0);
    expect(statistics.averageScore, isNull);
    expect(statistics.maxScore, isNull);
    expect(statistics.bestScore, isNull);
    expect(statistics.hintFreeBestScoreCount, 0);
    expect(statistics.errorFreeBestScoreCount, 0);
  });

  test('legacy completions contribute only to completed count', () {
    final statistics = PlayerStatistics.fromScores(
      completedThrough: 12,
      scores: const [],
    );
    expect(statistics.completedPuzzleCount, 12);
    expect(statistics.scoredPuzzleCount, 0);
    expect(statistics.totalScore, 0);
    expect(statistics.averageScore, isNull);
    expect(statistics.maxScore, isNull);
    expect(statistics.hintFreeBestScoreCount, 0);
    expect(statistics.errorFreeBestScoreCount, 0);
  });

  test('totals and clean-result counts use only the stored best records', () {
    final best = _score(1, 90, hints: 1, wrong: 2);
    final statistics = PlayerStatistics.fromScores(
      completedThrough: 8,
      scores: [best, _score(2, 300, wrong: 1), _score(3, 600, hints: 3)],
    );
    expect(statistics.completedPuzzleCount, 8);
    expect(statistics.scoredPuzzleCount, 3);
    expect(statistics.totalScore, 3125);
    expect(statistics.averageScore, closeTo(3125 / 3, 0.000001));
    expect(statistics.maxScore, 1250);
    expect(statistics.bestScore, same(best));
    expect(statistics.hintFreeBestScoreCount, 1);
    expect(statistics.errorFreeBestScoreCount, 1);
  });

  test('highest score wins before faster time', () {
    final high = _score(2, 110);
    final statistics = PlayerStatistics.fromScores(
      completedThrough: 2,
      scores: [_score(1, 10, hints: 1), high],
    );
    expect(statistics.bestScore, same(high));
    expect(statistics.maxScore, 1400);
  });

  test('equal scores select faster time before puzzle index', () {
    final fast = _score(3, 70);
    final statistics = PlayerStatistics.fromScores(
      completedThrough: 3,
      scores: [_score(1, 80), fast, _score(2, 80)],
    );
    expect(statistics.bestScore, same(fast));
  });

  test('equal score and time select the lower index in either order', () {
    final first = _score(1, 80);
    final second = _score(2, 80);
    for (final scores in [
      [first, second],
      [second, first],
    ]) {
      final statistics = PlayerStatistics.fromScores(
        completedThrough: 2,
        scores: scores,
      );
      expect(statistics.bestScore, same(first));
    }
  });

  test('deriving a new snapshot reflects replacement without accumulation', () {
    final scores = {1: _score(1, 100, hints: 1, wrong: 1)};
    final original = PlayerStatistics.fromScores(
      completedThrough: 1,
      scores: scores.values,
    );
    scores[1] = _score(1, 90);
    final improved = PlayerStatistics.fromScores(
      completedThrough: 1,
      scores: scores.values,
    );
    expect(original.totalScore, 1275);
    expect(original.hintFreeBestScoreCount, 0);
    expect(original.errorFreeBestScoreCount, 0);
    expect(improved.completedPuzzleCount, 1);
    expect(improved.scoredPuzzleCount, 1);
    expect(improved.totalScore, 1400);
    expect(improved.hintFreeBestScoreCount, 1);
    expect(improved.errorFreeBestScoreCount, 1);
  });
}
