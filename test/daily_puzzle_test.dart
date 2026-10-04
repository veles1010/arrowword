import 'package:arrowword/features/puzzle/daily/daily_puzzle.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_metrics.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_validator.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('date key uses supplied calendar date and ignores time of day', () {
    expect(dailyDateKey(DateTime(2026, 10, 4, 23, 59)), '2026-10-04');
    expect(dailyDateKey(DateTime(2026, 1, 2)), '2026-01-02');
    expect(dailyDateKey(DateTime.utc(2024, 2, 29, 0, 1)), '2024-02-29');
    expect(dailyDateKey(DateTime.utc(1, 1, 1)), '0001-01-01');
    expect(() => dailyDateKey(DateTime.utc(0)), throwsArgumentError);
    expect(() => dailyDateKey(DateTime.utc(10000)), throwsArgumentError);
  });

  test('only canonical real calendar dates are valid', () {
    for (final date in [
      '0001-01-01',
      '2024-02-29',
      '2026-10-04',
      '9999-12-31',
    ]) {
      expect(isValidDailyDateKey(date), isTrue, reason: date);
    }
    for (final date in [
      '',
      '0000-01-01',
      '2026-2-04',
      '2026-02-4',
      '2026-02-29',
      '1900-02-29',
      '2026-04-31',
      '2026-00-04',
      '2026-13-04',
      '2026-10-00',
      '2026-10-32',
      '2026-10-04T00:00:00',
      ' 2026-10-04',
      '2026-10-04\n',
    ]) {
      expect(isValidDailyDateKey(date), isFalse, reason: date);
      expect(() => dailyPuzzleId(date), throwsArgumentError);
      expect(() => dailyPuzzleSeed(date), throwsArgumentError);
      final generation = generateDailyPuzzle(date);
      expect(generation.isSuccess, isFalse);
      expect(generation.puzzle, isNull);
      expect(generation.failureReason, contains('Invalid Daily date'));
      expect(generation.attempts, isEmpty);
    }
  });

  test('versioned identity and golden FNV-1a uint32 seeds are stable', () {
    expect(dailySeedVersion, 1);
    expect(prototypeCatalogueVersion, 3);
    expect(dailyPuzzleId('2026-10-04'), 'daily-v1-c3-2026-10-04');
    expect(dailyPuzzleSeed('2026-10-04'), 927491995);
    expect(dailyPuzzleSeed('2026-10-05'), 910714376);
    expect(dailyPuzzleSeed('0001-01-01'), 3653865095);
    expect(dailyPuzzleSeed('2024-02-29'), 1356812941);
    expect(dailyPuzzleId('2026-10-04'), isNot(dailyPuzzleId('2026-10-05')));
    expect(dailyPuzzleSeed('2026-10-04'), isNot(dailyPuzzleSeed('2026-10-05')));
  });

  for (final fixture in const <String, int>{
    '2026-10-04': 927491995,
    '2026-10-05': 910714376,
    '2027-01-01': 2653078257,
    '2030-12-31': 2720821326,
  }.entries) {
    test('Daily v1 calendar/seed/identity golden ${fixture.key}', () {
      expect(
        dailyDateKey(DateTime.parse('${fixture.key}T23:59:59')),
        fixture.key,
      );
      expect(dailySeedVersion, 1);
      expect(dailyPuzzleSeed(fixture.key), fixture.value);
      expect(dailyPuzzleId(fixture.key), 'daily-v1-c3-${fixture.key}');
    });
  }

  group('real Daily generation', () {
    late DailyPuzzleGeneration first, repeated;
    setUpAll(() {
      first = generateDailyPuzzle('2026-10-04');
      // Changing ordinary progression has no input to the Daily generator.
      final progression = buildEligiblePool(
        catalogue: prototypeCatalogue,
        config: prototypeSequenceConfig,
        puzzleIndex: 2,
        history: [
          PuzzleHistoryEntry(
            puzzleIndex: 1,
            catalogVersion: prototypeCatalogueVersion,
            words: {
              for (final word in prototypeCatalogue.entries.take(10))
                word.id: word.solution,
            },
          ),
        ],
      );
      expect(progression.entries, hasLength(290));
      repeated = generateDailyPuzzle('2026-10-04');
    });

    test('same date repeats full structure independent of progression', () {
      expect(first.isSuccess, isTrue, reason: first.failureReason);
      expect(repeated.isSuccess, isTrue, reason: repeated.failureReason);
      expect(first.puzzle!.id, 'daily-v1-c3-2026-10-04');
      expect(repeated.puzzle!.id, first.puzzle!.id);
      expect(
        puzzleStructuralSignature(first.puzzle!),
        puzzleStructuralSignature(repeated.puzzle!),
      );
      expect(first.attempts.length, repeated.attempts.length);
      for (var i = 0; i < first.attempts.length; i++) {
        expect(first.attempts[i].searchNodes, repeated.attempts[i].searchNodes);
        expect(
          first.attempts[i].candidateChecks,
          repeated.attempts[i].candidateChecks,
        );
      }
    });

    test('October 4 versioned board structure is a locked golden', () {
      expect(
        puzzleStructuralSignature(first.puzzle!),
        'baby:BABY:0:2,5:2,4|believe:BELIEVE:1:2,7:1,7|bridge:BRIDGE:1:2,5:1,5|'
        'door:DOOR:0:3,2:3,1|exam:EXAM:0:9,2:9,1|green:GREEN:0:6,5:6,4|'
        'hand:HAND:0:5,2:5,1|horse:HORSE:1:5,2:4,2|race:RACE:0:7,2:7,1|sofa:SOFA:1:2,3:1,3',
      );
    });

    test('October 5 versioned board structure is a locked golden', () {
      final next = generateDailyPuzzle('2026-10-05');
      expect(next.isSuccess, isTrue, reason: next.failureReason);
      expect(
        puzzleStructuralSignature(next.puzzle!),
        'back:BACK:0:6,2:6,1|coat:COAT:1:5,7:4,7|knee:KNEE:0:8,2:8,1|'
        'leaf:LEAF:0:7,5:7,4|learn:LEARN:1:4,3:3,3|neck:NECK:0:5,5:5,4|'
        'race:RACE:0:3,5:3,4|snow:SNOW:0:2,2:2,1|week:WEEK:1:2,8:1,8|wrinkle:WRINKLE:1:2,5:1,5',
      );
    });

    test('full catalogue board is strictly valid with configured minima', () {
      final puzzle = first.puzzle!;
      final validation = const PuzzleValidator().validate(
        puzzle,
        expectedAnswerCount: prototypeGenerationConfig.targetAnswerCount,
      );
      final metrics = PuzzleMetrics(puzzle);
      expect(prototypeCatalogue.entries, hasLength(300));
      expect(validation.errors, isEmpty);
      expect(validation.phantomAdjacencyCount, 0);
      expect(validation.unexplainedRunCount, 0);
      expect(puzzle.answers.map((a) => a.id).toSet(), hasLength(10));
      expect(puzzle.answers.map((a) => a.solution).toSet(), hasLength(10));
      final words = {for (final w in prototypeCatalogue.entries) w.id: w};
      for (final answer in puzzle.answers) {
        expect(answer.solution, words[answer.id]!.solution);
        expect(answer.turkishClue, words[answer.id]!.turkishClue);
      }
      expect(puzzle.isAnswerGraphConnected, isTrue);
      expect(
        metrics.horizontalCount,
        greaterThanOrEqualTo(prototypeGenerationConfig.minAnswersPerDirection),
      );
      expect(
        metrics.verticalCount,
        greaterThanOrEqualTo(prototypeGenerationConfig.minAnswersPerDirection),
      );
      expect(
        metrics.crossingCount,
        greaterThanOrEqualTo(prototypeGenerationConfig.minCrossings),
      );
      expect(puzzle.rowCount, prototypeGenerationConfig.rows);
      expect(puzzle.columnCount, prototypeGenerationConfig.columns);
      expect(
        puzzle.meaningfulPositions.every(puzzle.displayBounds.containsLogical),
        isTrue,
      );
    });

    test('generation is bounded and readable first board stops lazily', () {
      expect(dailyMaxGenerationAttempts, 2);
      expect(first.attempts.length, inInclusiveRange(1, 2));
      for (final attempt in first.attempts) {
        expect(
          attempt.searchNodes,
          lessThanOrEqualTo(prototypeGenerationConfig.maxSearchNodes),
        );
        expect(
          attempt.backtracks,
          lessThanOrEqualTo(prototypeGenerationConfig.maxBacktracks),
        );
        expect(
          attempt.candidateChecks,
          lessThanOrEqualTo(prototypeGenerationConfig.maxCandidateChecks),
        );
      }
      final initial = first.attempts.first;
      if (initial.isSuccess && initial.metrics!.displayColumnCount <= 9) {
        expect(first.attempts, hasLength(1));
      } else {
        expect(first.attempts, hasLength(2));
      }
      if (first.attempts.any(
        (a) => a.isSuccess && a.metrics!.displayColumnCount <= 9,
      )) {
        expect(first.puzzle!.displayBounds.columnCount, lessThanOrEqualTo(9));
      }
      expect(() => first.attempts.clear(), throwsUnsupportedError);
    });
  });
}
