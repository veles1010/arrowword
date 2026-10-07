import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/data/difficulty_puzzles.dart';
import 'package:arrowword/features/puzzle/domain/normal_puzzle_contract.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/inspect_tracks.dart' as inspection;
import 'fixtures/normal_end_range_locks.dart';

void main() {
  final reports = <String, Map<String, Object?>>{};
  for (final entry in {
    'easy': () =>
        PuzzleSequenceGenerator(prototypeCatalogue, prototypeSequenceConfig),
    'medium': createMediumGenerator,
    'hard': createHardGenerator,
  }.entries) {
    test(
      '${entry.key} all 36 strict valid, deterministic repeats and locked end range',
      () {
        final report = inspection.inspectTrack(
          entry.key,
          entry.value(),
          count: normalPuzzleCount,
          repeat: true,
        );
        reports[entry.key] = report;
        expect(report['count'], normalPuzzleCount);
        expect(report['strictValid'], isTrue);
        expect(report['deterministicRepeatVerified'], isTrue);
        expect(report['phantomAdjacencies'], 0);
        expect(report['unexplainedRuns'], 0);
        expect(report['cooldownViolations'], 0);
        final puzzles = report['puzzles'] as List<Map<String, Object>>;
        for (final lock in normalEndRangeLocks[entry.key]!) {
          final actual = puzzles.singleWhere((p) => p['index'] == lock.index);
          expect(actual['id'], lock.id);
          expect(actual['seed'], lock.seed);
          expect(actual['signature'], lock.signature);
        }
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  }
  test(
    'aggregate product contract is 108 repeat-verified strict-valid boards',
    () {
      expect(normalPuzzleCount, 36);
      expect(totalNormalPuzzleCount, 108);
      expect(reports, hasLength(3));
      expect(
        reports.values.fold<int>(0, (n, r) => n + (r['count'] as int)),
        totalNormalPuzzleCount,
      );
    },
  );
}
