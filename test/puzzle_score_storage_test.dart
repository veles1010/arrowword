import 'dart:convert';

import 'package:arrowword/app/puzzle_progress_store.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_score.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PuzzleProgress progress({int schema = 5}) => PuzzleProgress(
    catalogVersion: 3,
    puzzleIndex: 2,
    puzzleId: 'puzzle-2',
    signature: 'signature',
    letters: const {'1,1': 'A'},
    completedThrough: 2,
    schemaVersion: schema,
    history: const [
      ProgressHistoryEntry(puzzleIndex: 1, wordIds: ['word']),
    ],
    revealedCells: const ['1,1'],
    hintsUsed: 1,
    elapsedMilliseconds: 12345,
    wrongChecks: 2,
    completedScores: {
      2: CompletedPuzzleScore(
        puzzleIndex: 2,
        score: 1250,
        elapsedSeconds: 12,
        hintsUsed: 1,
        wrongChecks: 2,
      ),
    },
  );

  test('schema 4 preserves old progress without fabricating statistics', () {
    final encoded = progress(schema: 4).encode();
    final data = jsonDecode(encoded) as Map;
    expect(data.containsKey('elapsedMilliseconds'), isFalse);
    expect(data.containsKey('wrongChecks'), isFalse);
    expect(data.containsKey('completedScores'), isFalse);
    final restored = PuzzleProgress.decode(encoded);
    expect(restored.catalogVersion, 3);
    expect(restored.letters, {'1,1': 'A'});
    expect(restored.completedThrough, 2);
    expect(restored.history.single.wordIds, ['word']);
    expect(restored.revealedCells, ['1,1']);
    expect(restored.hintsUsed, 1);
    expect(restored.elapsedMilliseconds, 0);
    expect(restored.wrongChecks, 0);
    expect(restored.completedScores, isEmpty);
  });

  test('schema 5 round trips attempt statistics and compact scores', () {
    final encoded = progress().encode();
    final data = jsonDecode(encoded) as Map;
    expect(data['schemaVersion'], 5);
    expect((data['completedScores'] as Map).keys, ['2']);
    final restored = PuzzleProgress.decode(encoded);
    expect(restored.elapsedMilliseconds, 12345);
    expect(restored.wrongChecks, 2);
    expect(
      restored.completedScores[2]!.toJson(),
      progress().completedScores[2]!.toJson(),
    );
  });

  test('malformed statistics and completed scores are rejected', () {
    for (final mutation in <void Function(Map<String, dynamic>)>[
      (data) => data['elapsedMilliseconds'] = -1,
      (data) => data['elapsedMilliseconds'] = 1.5,
      (data) => data['wrongChecks'] = -1,
      (data) => data['wrongChecks'] = '2',
      (data) => data['completedScores'] = [],
      (data) => data['completedScores'] = {
        '02': (data['completedScores'] as Map)['2'],
      },
      (data) => data['completedScores'] = {
        '3': (data['completedScores'] as Map)['2'],
      },
      (data) => (data['completedScores']['2'] as Map)['puzzleIndex'] = 1,
      (data) => (data['completedScores']['2'] as Map)['score'] = -1,
      (data) => (data['completedScores']['2'] as Map)['elapsedSeconds'] = 121,
      (data) => (data['completedScores']['2'] as Map)['wrongChecks'] = 1,
      (data) => (data['completedScores']['2'] as Map)['hintsUsed'] = 0,
      (data) => (data['completedScores']['2'] as Map)['scoringVersion'] = 2,
    ]) {
      final data = jsonDecode(progress().encode()) as Map<String, dynamic>;
      mutation(data);
      expect(
        () => PuzzleProgress.decode(jsonEncode(data)),
        throwsFormatException,
      );
    }
  });
}
