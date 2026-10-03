import 'dart:io';

import 'package:arrowword/features/puzzle/data/prototype_word_bank.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_generator.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_validator.dart';

void main(List<String> arguments) {
  for (final seed
      in (arguments.isEmpty ? ['$prototypeBaseSeed'] : arguments).map(
        int.parse,
      )) {
    final stopwatch = Stopwatch()..start();
    final result = const PuzzleGenerator().generate(
      wordBank: prototypeWordBank,
      seed: seed,
      config: prototypeGenerationConfig,
    );
    stdout.writeln(
      'Seed $seed: ${result.failureReason ?? 'success'}; ${stopwatch.elapsedMilliseconds} ms; '
      '${result.searchNodes} nodes / ${result.backtracks} backtracks / ${result.candidateChecks} checks',
    );
    stdout.writeln(
      'complete ${result.completeSolutionsFound}; anchors ${result.anchorsTried}; '
      'first ${result.firstCompleteScore}; best ${result.bestCompleteScore}',
    );
    stdout.writeln(
      'generated ${result.candidatePlacementsGenerated}; legal ${result.legalCandidates}; '
      'rejected by validation ${result.candidatesRejected}; duplicate ${result.duplicateCandidates}; '
      'span rejected ${result.spanRejected}; bounds rejected ${result.boundsRejected}; '
      'occupied crossing opportunities skipped ${result.occupiedCrossingRejected}; '
      'visited hits/misses ${result.visitedStateHits}/${result.visitedStateMisses}',
    );
    final puzzle = result.puzzle;
    if (puzzle == null) {
      exitCode = 1;
      continue;
    }
    final metrics = result.metrics!;
    final bounds = puzzle.displayBounds;
    final validation = const PuzzleValidator().validate(
      puzzle,
      expectedAnswerCount: 10,
    );
    if (!validation.isValid) exitCode = 1;
    stdout.writeln(
      'bounds ${bounds.minRow}..${bounds.maxRow}, ${bounds.minColumn}..${bounds.maxColumn}; '
      'visible ${bounds.rowCount}x${bounds.columnCount}; '
      '${metrics.horizontalCount} right / ${metrics.verticalCount} down; ${metrics.crossingCount} crossings; '
      '${metrics.meaningfulCellCount}/${metrics.boundingBoxArea} density ${metrics.density}; '
      'score ${metrics.qualityScore}; phantom ${metrics.phantomAdjacencyCount}; '
      'runs ${metrics.horizontalRunCount}/${metrics.verticalRunCount}; '
      'unexplained ${validation.unexplainedRunCount}; errors ${validation.errors}',
    );
    stdout.writeln(
      'leaves ${metrics.leafAnswerCount}; degrees ${metrics.answerDegrees}; '
      'average ${metrics.averageAnswerDegree}; maximum ${metrics.maximumAnswerDegree}; '
      'leafExpansionArea ${metrics.leafExpansionArea}; danglingLength ${metrics.danglingLength}',
    );
    for (final answer in puzzle.answers) {
      stdout.writeln(
        '${answer.solution} — ${answer.turkishClue} — ${answer.direction.name} — '
        'start(${answer.start.row},${answer.start.column}) — clue(${answer.cluePosition.row},${answer.cluePosition.column})',
      );
    }
  }
}
