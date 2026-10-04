import 'package:arrowword/features/puzzle/domain/puzzle_score.dart';
import 'package:flutter_test/flutter_test.dart';

CompletedPuzzleScore score(int seconds, {int hints = 0, int wrong = 0}) =>
    CompletedPuzzleScore.calculate(
      puzzleIndex: 1,
      elapsedSeconds: seconds,
      hintsUsed: hints,
      wrongChecks: wrong,
    );

void main() {
  test('best score prioritizes score, then faster time, and retains ties', () {
    final existing = score(100, hints: 1);
    expect(isBetterPuzzleScore(existing, null), isTrue);
    expect(isBetterPuzzleScore(score(120), existing), isTrue);
    expect(isBetterPuzzleScore(score(50, hints: 2), existing), isFalse);
    expect(isBetterPuzzleScore(score(99, hints: 1), existing), isTrue);
    expect(isBetterPuzzleScore(score(101, hints: 1), existing), isFalse);
    expect(isBetterPuzzleScore(score(100, hints: 1), existing), isFalse);
    // Different penalties do not break equal score/time ties.
    expect(isBetterPuzzleScore(score(100, wrong: 4), existing), isFalse);
  });

  test('huge penalty counts clamp to zero without integer overflow', () {
    for (final count in [0x7fffffffffffffff, 0x4000000000000000]) {
      expect(
        calculatePuzzleScore(
          elapsedSeconds: 0,
          hintsUsed: count,
          wrongChecks: 0,
        ),
        0,
      );
      expect(
        calculatePuzzleScore(
          elapsedSeconds: 0,
          hintsUsed: 0,
          wrongChecks: count,
        ),
        0,
      );
    }
  });

  test('a different puzzle cannot replace another puzzle best record', () {
    final candidate = CompletedPuzzleScore.calculate(
      puzzleIndex: 2,
      elapsedSeconds: 0,
      hintsUsed: 0,
      wrongChecks: 0,
    );
    expect(isBetterPuzzleScore(candidate, score(400)), isFalse);
  });

  test('corrupt candidates cannot become best-score value objects', () {
    final existing = score(100);
    for (final field in [
      'score',
      'elapsedSeconds',
      'hintsUsed',
      'wrongChecks',
      'scoringVersion',
      'puzzleIndex',
    ]) {
      final json = existing.toJson()..[field] = -1;
      expect(() => CompletedPuzzleScore.fromJson(json), throwsFormatException);
    }
    expect(
      CompletedPuzzleScore.fromJson(existing.toJson()).toJson(),
      existing.toJson(),
    );
  });
}
