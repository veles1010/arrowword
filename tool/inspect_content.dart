import 'dart:io';

import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';

void main(List<String> arguments) {
  final catalogue = prototypeCatalogue;
  final health = catalogue.health;
  stdout.writeln(
    'Catalogue v${catalogue.version}: ${health.totalCount} entries; '
    '${health.uniqueSolutionCount} unique solutions; issues ${catalogue.issues}',
  );
  stdout.writeln(
    'Difficulty: ${health.difficultyCounts}; lengths: ${health.lengthCounts}',
  );
  stdout.writeln('Letter occurrences: ${health.letterFrequency}');
  final partners = health.partnerCounts.values.toList()..sort();
  stdout.writeln(
    'Partners min/avg/max: ${partners.first}/${health.averagePartners}/${partners.last}; '
    'zero ${health.lowPartnerIds(maximum: 0)}; low (<=2) ${health.lowPartnerIds()}',
  );
  if (!catalogue.isValid) {
    exitCode = 1;
    return;
  }
  // One documented experiment: same catalogue/base seed/budgets, descend K.
  for (final cooldown
      in arguments.isEmpty ? [5, 4, 3, 2] : arguments.map(int.parse)) {
    stdout.writeln(
      '\nBase seed $prototypeBaseSeed; strict cooldown $cooldown; count 10',
    );
    final sequence = PuzzleSequenceGenerator(
      catalogue,
      PuzzleSequenceConfig(
        baseSeed: prototypeBaseSeed,
        cooldownPuzzles: cooldown,
        generation: prototypeGenerationConfig,
      ),
    );
    final history = <PuzzleHistoryEntry>[];
    final results = <SequencePuzzleResult>[];
    for (var index = 1; index <= 10; index++) {
      final watch = Stopwatch()..start();
      final result = sequence.generateNext(
        puzzleIndex: index,
        history: history,
      );
      watch.stop();
      if (!result.isSuccess) {
        stdout.writeln('FAILED: ${result.failureReason}');
        break;
      }
      history.add(result.toHistory());
      results.add(result);
      final p = result.puzzle!, m = result.generation!.metrics!;
      stdout.writeln(
        '$index | ${p.id} | seed ${result.seed} | eligible ${result.pool.entries.length} | '
        '${p.answers.map((a) => a.solution).join(',')} | score ${m.qualityScore} | '
        'crossings ${m.crossingCount} | leaves ${m.leafAnswerCount} | '
        '${m.displayRowCount}x${m.displayColumnCount} | density ${m.density.toStringAsFixed(4)} | '
        '${watch.elapsedMilliseconds}ms | nodes ${result.generation!.searchNodes} | '
        'checks ${result.generation!.candidateChecks} | phantom ${m.phantomAdjacencyCount}',
      );
    }
    if (results.length != 10) continue;
    final repeats = SequenceRepeatAnalysis(results);
    final scores =
        results.map((r) => r.generation!.metrics!.qualityScore).toList()
          ..sort();
    stdout.writeln(
      'SUCCESS: min/avg/max score ${scores.first}/'
      '${scores.reduce((a, b) => a + b) / scores.length}/${scores.last}; '
      'unique words ${repeats.indicesByWord.length}; repeated words ${repeats.repeatedWordCount}; '
      'minimum repeat distance ${repeats.minimumDistance}',
    );
    for (final e in repeats.indicesByWord.entries) {
      stdout.writeln(
        '${e.key}: puzzles ${e.value}; minimum distance ${repeats.minimumDistanceByWord[e.key]}',
      );
    }
    return;
  }
  exitCode = 1;
}
