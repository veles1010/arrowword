import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/data/difficulty_puzzles.dart';
import 'package:arrowword/features/puzzle/domain/normal_puzzle_contract.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:io';

import 'package:arrowword/features/puzzle/localization/clue_pack.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_metrics.dart';

import '../tool/inspect_tracks.dart' as inspection;
import 'fixtures/normal_end_range_locks.dart';

void main() {
  final reports = <String, Map<String, Object?>>{};
  final packs = {
    for (final locale in ['tr', 'en'])
      locale: decodeCluePack(
        File('assets/clues/$locale.json').readAsStringSync(),
      ),
  };
  final resolver = LocalizedClueResolver(packs, completeLocales: {'tr', 'en'});
  final used = <String, Set<String>>{};
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
          onPuzzle: (result) {
            final puzzle = result.puzzle!;
            final signature = puzzleStructuralSignature(puzzle);
            final before = puzzle.answers
                .map(
                  (a) =>
                      (a.id, a.solution, a.start, a.cluePosition, a.direction),
                )
                .toList();
            final bounds = puzzle.displayBounds;
            final crossings = PuzzleMetrics(puzzle).crossingCount;
            final id = puzzle.id, seed = result.seed;
            for (final answer in puzzle.answers) {
              expect(
                resolver.resolve(answer.clueId!, 'tr'),
                answer.turkishClue,
              );
              expect(
                resolver.resolve(answer.clueId!, 'en'),
                packs['en']![answer.clueId],
              );
              expect(
                resolver.resolve(answer.clueId!, 'en'),
                isNot(answer.turkishClue),
              );
              (used[entry.key] ??= {}).add(answer.clueId!);
            }
            expect(puzzleStructuralSignature(puzzle), signature);
            expect(
              puzzle.answers
                  .map(
                    (a) => (
                      a.id,
                      a.solution,
                      a.start,
                      a.cluePosition,
                      a.direction,
                    ),
                  )
                  .toList(),
              before,
            );
            expect(puzzle.id, id);
            expect(result.seed, seed);
            expect(puzzle.displayBounds.minRow, bounds.minRow);
            expect(puzzle.displayBounds.maxRow, bounds.maxRow);
            expect(puzzle.displayBounds.minColumn, bounds.minColumn);
            expect(puzzle.displayBounds.maxColumn, bounds.maxColumn);
            expect(PuzzleMetrics(puzzle).crossingCount, crossings);
          },
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
  test('aggregate product contract is 108 repeat-verified strict-valid boards', () {
    expect(normalPuzzleCount, 36);
    expect(totalNormalPuzzleCount, 108);
    expect(reports, hasLength(3));
    expect(
      reports.values.fold<int>(0, (n, r) => n + (r['count'] as int)),
      totalNormalPuzzleCount,
    );
    final total = used.values.expand((ids) => ids).toSet().length;
    expect(packs['en'], hasLength(900));
    expect(used.keys.toSet(), {'easy', 'medium', 'hard'});
    stdout.writeln(
      'English IDs used by 108 boards: $total/900; per track ${used.map((track, ids) => MapEntry(track, ids.length))}',
    );
  });
}
