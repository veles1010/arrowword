import 'dart:convert';

import 'package:arrowword/features/puzzle/domain/puzzle_score.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculatePuzzleScore', () {
    for (final entry in {
      0: 1400,
      120: 1400,
      121: 1300,
      180: 1300,
      181: 1200,
      300: 1200,
      301: 1100,
      480: 1100,
      481: 1000,
    }.entries) {
      test('time boundary ${entry.key}', () {
        expect(
          calculatePuzzleScore(
            elapsedSeconds: entry.key,
            hintsUsed: 0,
            wrongChecks: 0,
          ),
          entry.value,
        );
      });
    }

    test('subtracts hint and wrong-check penalties and floors at zero', () {
      expect(
        calculatePuzzleScore(elapsedSeconds: 120, hintsUsed: 2, wrongChecks: 3),
        1125,
      );
      expect(
        calculatePuzzleScore(
          elapsedSeconds: 481,
          hintsUsed: 10,
          wrongChecks: 0,
        ),
        0,
      );
      expect(
        calculatePuzzleScore(elapsedSeconds: 0, hintsUsed: 20, wrongChecks: 50),
        0,
      );
    });

    test('rejects each negative input', () {
      for (final values in [(-1, 0, 0), (0, -1, 0), (0, 0, -1)]) {
        expect(
          () => calculatePuzzleScore(
            elapsedSeconds: values.$1,
            hintsUsed: values.$2,
            wrongChecks: values.$3,
          ),
          throwsArgumentError,
        );
      }
    });
  });

  group('CompletedPuzzleScore', () {
    final record = CompletedPuzzleScore.calculate(
      puzzleIndex: 3,
      elapsedSeconds: 181,
      hintsUsed: 1,
      wrongChecks: 2,
    );

    test('calculates and round-trips through JSON', () {
      expect(record.score, 1050);
      expect(record.scoringVersion, 1);
      final restored = CompletedPuzzleScore.fromJson(
        jsonDecode(jsonEncode(record.toJson())),
      );
      expect(restored.toJson(), record.toJson());
    });

    test('rejects malformed objects and noninteger fields', () {
      for (final input in [null, [], 'score', 1]) {
        expect(
          () => CompletedPuzzleScore.fromJson(input),
          throwsFormatException,
        );
      }
      for (final key in record.toJson().keys) {
        for (final value in [null, '1', 1.0, true]) {
          expect(
            () =>
                CompletedPuzzleScore.fromJson({...record.toJson(), key: value}),
            throwsFormatException,
          );
        }
        final missing = record.toJson()..remove(key);
        expect(
          () => CompletedPuzzleScore.fromJson(missing),
          throwsFormatException,
        );
      }
    });

    test('rejects invalid values, versions and inconsistent scores', () {
      for (final entry in {
        'puzzleIndex': 0,
        'score': -1,
        'elapsedSeconds': -1,
        'hintsUsed': -1,
        'wrongChecks': -1,
        'scoringVersion': 2,
      }.entries) {
        expect(
          () => CompletedPuzzleScore.fromJson({
            ...record.toJson(),
            entry.key: entry.value,
          }),
          throwsFormatException,
        );
      }
      expect(
        () =>
            CompletedPuzzleScore.fromJson({...record.toJson(), 'score': 1051}),
        throwsFormatException,
      );
      expect(
        () => CompletedPuzzleScore.calculate(
          puzzleIndex: 0,
          elapsedSeconds: 0,
          hintsUsed: 0,
          wrongChecks: 0,
        ),
        throwsArgumentError,
      );
    });
  });
}
