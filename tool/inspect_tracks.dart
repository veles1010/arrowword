import 'dart:convert';
import 'dart:io';

import 'package:arrowword/features/puzzle/content/track_catalogue_audit.dart';
import 'package:arrowword/features/puzzle/data/difficulty_puzzles.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle.dart';
import 'package:arrowword/features/puzzle/domain/normal_puzzle_contract.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_metrics.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';

import 'inspect_content.dart' show verifyStressPuzzle;

Map<String, num> stats(Iterable<num> values) {
  final all = values.toList()..sort();
  if (all.isEmpty) return {'min': 0, 'avg': 0, 'max': 0};
  return {
    'min': all.first,
    'avg': all.fold<num>(0, (a, b) => a + b) / all.length,
    'max': all.last,
  };
}

Map<String, Object?> inspectTrack(
  String name,
  PuzzleSequenceGenerator generator, {
  int count = 30,
  bool progress = false,
  Set<int> inspectIndices = const {},
  bool repeat = false,
}) {
  final catalogue = generator.catalogue;
  final forbidden = switch (name) {
    'easy' => [...mediumCatalogue.entries, ...hardCatalogue.entries],
    'medium' => [...prototypeCatalogue.entries, ...hardCatalogue.entries],
    'hard' => [...prototypeCatalogue.entries, ...mediumCatalogue.entries],
    _ => throw ArgumentError.value(name, 'track'),
  };
  final audit = TrackCatalogueAudit(
    catalogue,
    forbidden: forbidden,
    minimumPartners: name == 'easy' ? 0 : 100,
  );
  // The legacy Easy bank intentionally includes Turkish/English cognates.
  // Its established content policy is not the newer descriptive-clue gate.
  // Board validation below remains identical and strict for all three tracks.
  if (name != 'easy' && !audit.isValid) {
    throw StateError(audit.issues.join('\n'));
  }
  final previous = <SequencePuzzleResult>[];
  final rows = <Map<String, Object>>[];
  final uses = <String, List<int>>{
    for (final entry in catalogue.entries) entry.id: [],
  };
  final times = <int>[];
  for (var index = 1; index <= count; index++) {
    final clock = Stopwatch()..start();
    final result = generator.generateNext(
      puzzleIndex: index,
      history: previous.map((p) => p.toHistory()).toList(),
    );
    clock.stop();
    verifyStressPuzzle(
      result,
      previous,
      cooldown: generator.config.cooldownPuzzles,
    );
    final metrics = PuzzleMetrics(result.puzzle!);
    if (repeat) {
      final repeated = generator.generateNext(
        puzzleIndex: index,
        history: previous.map((p) => p.toHistory()).toList(),
      );
      verifyStressPuzzle(
        repeated,
        previous,
        cooldown: generator.config.cooldownPuzzles,
      );
      if (repeated.puzzle!.id != result.puzzle!.id ||
          repeated.seed != result.seed ||
          puzzleStructuralSignature(repeated.puzzle!) !=
              metrics.structuralSignature ||
          jsonEncode(
                repeated.puzzle!.answers.map((a) => a.turkishClue).toList(),
              ) !=
              jsonEncode(
                result.puzzle!.answers.map((a) => a.turkishClue).toList(),
              )) {
        throw StateError('$name $index deterministic repeat mismatch');
      }
    }
    times.add(clock.elapsedMilliseconds);
    for (final answer in result.puzzle!.answers) {
      uses[answer.id]!.add(index);
    }
    rows.add({
      'index': index,
      'id': result.puzzle!.id,
      'seed': result.seed,
      'rows': metrics.displayRowCount,
      'columns': metrics.displayColumnCount,
      'crossings': metrics.crossingCount,
      'leaves': metrics.leafAnswerCount,
      'quality': metrics.qualityScore,
      'density': metrics.density,
      'attempts': result.attempts.length,
      'checks': result.totalCandidateChecks,
      'milliseconds': clock.elapsedMilliseconds,
      if (index <= 3 ||
          (index > normalPuzzleCount - 6 && index <= normalPuzzleCount))
        'signature': metrics.structuralSignature,
      if (inspectIndices.contains(index))
        'answers': [
          for (final answer in result.puzzle!.answers)
            {
              'solution': answer.solution,
              'clue': answer.turkishClue,
              'direction': answer.direction.name,
              'start': [answer.start.row, answer.start.column],
              'cluePosition': [
                answer.cluePosition.row,
                answer.cluePosition.column,
              ],
            },
        ],
      if (inspectIndices.contains(index))
        'board': [
          for (var r = 0; r < result.puzzle!.rowCount; r++)
            [
              for (var c = 0; c < result.puzzle!.columnCount; c++)
                _boardCell(result.puzzle!, GridPosition(r, c)),
            ].join(),
        ],
    });
    previous.add(result);
    if (progress) {
      stderr.writeln(
        '$name $index/$count valid; ${metrics.displayRowCount}x${metrics.displayColumnCount}, crossings=${metrics.crossingCount}, ms=${clock.elapsedMilliseconds}',
      );
    }
  }
  final distances = [
    for (final indices in uses.values)
      for (var i = 1; i < indices.length; i++) indices[i] - indices[i - 1],
  ];
  final unique = uses.values.where((indices) => indices.isNotEmpty).length;
  return {
    'track': name,
    'count': count,
    'strictValid': true,
    'deterministicRepeatVerified': repeat,
    'phantomAdjacencies': 0,
    'unexplainedRuns': 0,
    'cooldownViolations': 0,
    'catalogue': {
      'count': catalogue.entries.length,
      'lengths': catalogue.health.lengthCounts.map((k, v) => MapEntry('$k', v)),
      'wordDifficulty': catalogue.health.difficultyCounts.map(
        (k, v) => MapEntry(k.name, v),
      ),
      'partners': {
        'min': audit.minimumPartners,
        'avg': audit.averagePartners,
        'max': audit.maximumPartners,
      },
      'nearDuplicateClues': audit.nearDuplicateClues,
    },
    'unique': unique,
    'coveragePercent': unique / catalogue.entries.length * 100,
    'lengthCoverage': {
      for (final length in [4, 5, 6, 7])
        '$length': {
          'available': catalogue.entries
              .where((w) => w.solution.length == length)
              .length,
          'unique': catalogue.entries
              .where(
                (w) => w.solution.length == length && uses[w.id]!.isNotEmpty,
              )
              .length,
          'selections': catalogue.entries
              .where((w) => w.solution.length == length)
              .fold<int>(0, (n, w) => n + uses[w.id]!.length),
        },
    },
    'unused': [
      for (final w in catalogue.entries)
        if (uses[w.id]!.isEmpty) w.solution,
    ],
    'unusedPartners': stats([
      for (final w in catalogue.entries)
        if (uses[w.id]!.isEmpty) audit.partnerCounts[w.id]!,
    ]),
    'clueWords': {
      ...stats(
        catalogue.entries.map(
          (w) => w.turkishClue.trim().split(RegExp(r'\s+')).length,
        ),
      ),
      'over7': catalogue.entries
          .where((w) => w.turkishClue.trim().split(RegExp(r'\s+')).length > 7)
          .length,
      'over10': catalogue.entries
          .where((w) => w.turkishClue.trim().split(RegExp(r'\s+')).length > 10)
          .length,
    },
    'usage': stats(uses.values.map((v) => v.length)),
    'repeatDistance': stats(distances),
    'crossings': stats(rows.map((r) => r['crossings'] as num)),
    'leaves': stats(rows.map((r) => r['leaves'] as num)),
    'rows': stats(rows.map((r) => r['rows'] as num)),
    'columns': stats(rows.map((r) => r['columns'] as num)),
    'quality': stats(rows.map((r) => r['quality'] as num)),
    'tenColumnBoards': rows.where((r) => r['columns'] == 10).length,
    'attempts': stats(rows.map((r) => r['attempts'] as num)),
    'candidateChecks': stats(rows.map((r) => r['checks'] as num)),
    'milliseconds': stats(times),
    'totalMilliseconds': times.fold<int>(0, (a, b) => a + b),
    'puzzles': rows,
  };
}

String _boardCell(Puzzle puzzle, GridPosition position) {
  final answers = puzzle.answersAt(position);
  if (answers.isNotEmpty) {
    final answer = answers.first;
    return answer.solution[answer.positions.indexOf(position)];
  }
  return puzzle.cellAt(position).type == PuzzleCellType.clue ? '#' : '.';
}

void main(List<String> arguments) {
  if (arguments.contains('--seeds')) {
    stdout.writeln(
      jsonEncode({
        for (final entry in {
          'medium': mediumBaseSeed,
          'hard': hardBaseSeed,
        }.entries)
          entry.key: {
            for (final index in [1, 2, 3, 10])
              '$index': derivePuzzleSeed(entry.value, index),
          },
      }),
    );
    return;
  }
  final names = arguments
      .where((a) => a == 'easy' || a == 'medium' || a == 'hard')
      .toList();
  if (names.isEmpty) {
    names.addAll(
      arguments.contains('--all-normal')
          ? ['easy', 'medium', 'hard']
          : ['medium', 'hard'],
    );
  }
  final count = int.parse(
    arguments.firstWhere(
      (a) => int.tryParse(a) != null,
      orElse: () =>
          arguments.contains('--all-normal') ? '$normalPuzzleCount' : '30',
    ),
  );
  for (final name in names) {
    stdout.writeln(
      jsonEncode(
        inspectTrack(
          name,
          switch (name) {
            'easy' => PuzzleSequenceGenerator(
              prototypeCatalogue,
              prototypeSequenceConfig,
            ),
            'medium' => createMediumGenerator(),
            _ => createHardGenerator(),
          },
          count: count,
          progress: true,
          repeat: arguments.contains('--repeat'),
          inspectIndices: {
            for (final a in arguments.where((a) => a.startsWith('--board=')))
              int.parse(a.substring('--board='.length)),
          },
        ),
      ),
    );
  }
}
