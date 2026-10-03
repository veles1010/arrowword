import 'dart:io';

import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_metrics.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_validator.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';

/// Independent stress gate; exceptions make the command exit non-zero.
void verifyStressPuzzle(
  SequencePuzzleResult r,
  List<SequencePuzzleResult> previous, {
  int cooldown = 5,
}) {
  if (!r.isSuccess) throw StateError(r.failureReason!);
  final p = r.puzzle!, m = PuzzleMetrics(r.puzzle!);
  final v = const PuzzleValidator().validate(p, expectedAnswerCount: 10);
  if (!v.isValid ||
      v.phantomAdjacencyCount != 0 ||
      v.unexplainedRunCount != 0 ||
      !p.isAnswerGraphConnected ||
      m.horizontalCount < 4 ||
      m.verticalCount < 4 ||
      m.crossingCount < 9 ||
      p.rowCount != 10 ||
      p.columnCount != 10 ||
      !p.meaningfulPositions.every(p.displayBounds.containsLogical)) {
    throw StateError(
      'Puzzle ${r.puzzleIndex}: strict contract failed: ${v.errors}',
    );
  }
  final recent = previous.where(
    (old) => r.puzzleIndex - old.puzzleIndex <= cooldown,
  );
  final ids = recent
      .expand((old) => old.puzzle!.answers.map((a) => a.id))
      .toSet();
  final words = recent
      .expand((old) => old.puzzle!.answers.map((a) => a.solution))
      .toSet();
  if (p.answers.any((a) => ids.contains(a.id) || words.contains(a.solution))) {
    throw StateError('Puzzle ${r.puzzleIndex}: cooldown violation');
  }
}

String summary(Iterable<num> values) {
  final sorted = values.toList()..sort();
  return '${sorted.first} / ${(sorted.fold<num>(0, (a, b) => a + b) / sorted.length).toStringAsFixed(2)} / ${sorted.last}';
}

Map<T, int> histogram<T extends Comparable<dynamic>>(Iterable<T> values) {
  final counts = <T, int>{};
  for (final v in values) {
    counts.update(v, (n) => n + 1, ifAbsent: () => 1);
  }
  return {for (final k in counts.keys.toList()..sort()) k: counts[k]!};
}

void main(List<String> arguments) {
  final count = arguments.isEmpty ? 30 : int.parse(arguments.single);
  if (count < 1) throw ArgumentError('Count must be positive.');
  final c = prototypeCatalogue, h = c.health;
  if (!c.isValid ||
      c.version != 2 ||
      h.lowPartnerIds(maximum: 0).isNotEmpty ||
      h.totalCount != 300) {
    throw StateError('Invalid v2 catalogue: ${c.issues}');
  }
  stdout.writeln('# Catalogue v2 stress report\n');
  stdout.writeln(
    'Catalogue v${c.version}: ${h.totalCount} entries; ${h.uniqueSolutionCount} unique; issues ${c.issues}.',
  );
  stdout.writeln(
    'Difficulty: ${h.difficultyCounts}; lengths: ${h.lengthCounts}.',
  );
  stdout.writeln(
    'Tags (multi-tag entries counted in each): ${histogram(c.entries.expand((w) => w.tags))}.',
  );
  stdout.writeln('A–Z occurrences: ${h.letterFrequency}.');
  final partners = h.partnerCounts.entries.toList()
    ..sort((a, b) {
      final n = a.value.compareTo(b.value);
      return n != 0 ? n : a.key.compareTo(b.key);
    });
  stdout.writeln(
    'Crossing partners min / average / max: ${summary(h.partnerCounts.values)}; zero: ${h.lowPartnerIds(maximum: 0)}.',
  );
  stdout.writeln(
    'Bottom 10: ${partners.take(10).map((e) => '${e.key.toUpperCase()}:${e.value}').join(', ')}.',
  );
  final highest = [...partners]
    ..sort((a, b) {
      final n = b.value.compareTo(a.value);
      return n != 0 ? n : a.key.compareTo(b.key);
    });
  stdout.writeln(
    'Top 10: ${highest.take(10).map((e) => '${e.key.toUpperCase()}:${e.value}').join(', ')}.',
  );
  stdout.writeln(
    '\n## Sequence\n\nBase seed $prototypeBaseSeed; cooldown 5; count $count. No relaxation. Timing is local diagnostic only, around generateNext.\n',
  );
  final sequence = PuzzleSequenceGenerator(
    c,
    const PuzzleSequenceConfig(
      baseSeed: prototypeBaseSeed,
      cooldownPuzzles: 5,
      generation: prototypeGenerationConfig,
    ),
  );
  final results = <SequencePuzzleResult>[], times = <int>[];
  stdout.writeln(
    '| Index | ID | Seed | Eligible | Score | Crossings | Leaves | Rows×cols | Density | ms | Checks | Nodes | Complete |',
  );
  stdout.writeln('|---|---|---|---|---|---|---|---|---|---|---|---|---|');
  for (var index = 1; index <= count; index++) {
    final watch = Stopwatch()..start();
    final r = sequence.generateNext(
      puzzleIndex: index,
      history: results.map((r) => r.toHistory()).toList(),
    );
    watch.stop();
    verifyStressPuzzle(r, results);
    results.add(r);
    times.add(watch.elapsedMilliseconds);
    final g = r.generation!, m = g.metrics!;
    stdout.writeln(
      '| $index | ${r.puzzle!.id} | ${r.seed} | ${r.pool.entries.length} | ${m.qualityScore} | ${m.crossingCount} | ${m.leafAnswerCount} | ${m.displayRowCount}×${m.displayColumnCount} | ${m.density.toStringAsFixed(4)} | ${times.last} | ${g.candidateChecks} | ${g.searchNodes} | ${g.completeSolutionsFound} |',
    );
  }
  final metrics = results.map((r) => r.generation!.metrics!).toList();
  final scores = metrics.map((m) => m.qualityScore).toList()..sort();
  stdout.writeln(
    '\nPASS: $count/$count complete; independent strict validation passed; all phantom adjacencies and unexplained runs = 0; cooldown checked by both IDs and solutions.',
  );
  stdout.writeln(
    'Scores min / average / max: ${summary(scores)}; lowest indices ${results.where((r) => r.generation!.metrics!.qualityScore == scores.first).map((r) => r.puzzleIndex).toList()}; highest indices ${results.where((r) => r.generation!.metrics!.qualityScore == scores.last).map((r) => r.puzzleIndex).toList()}.',
  );
  stdout.writeln(
    'Crossings min / average / max: ${summary(metrics.map((m) => m.crossingCount))}; maximum leaves ${metrics.map((m) => m.leafAnswerCount).reduce((a, b) => a > b ? a : b)}.',
  );
  stdout.writeln(
    'Visible widths: ${histogram(metrics.map((m) => m.displayColumnCount))}; dimensions: ${histogram(metrics.map((m) => '${m.displayRowCount}×${m.displayColumnCount}'))}.',
  );
  stdout.writeln(
    'Rows min / average / max: ${summary(metrics.map((m) => m.displayRowCount))}; columns: ${summary(metrics.map((m) => m.displayColumnCount))}; density: ${summary(metrics.map((m) => m.density))}.',
  );
  stdout.writeln(
    '10-column boards (index:score:density): ${results.where((r) => r.generation!.metrics!.displayColumnCount == 10).map((r) => '${r.puzzleIndex}:${r.generation!.metrics!.qualityScore}:${r.generation!.metrics!.density.toStringAsFixed(4)}').join(', ')}.',
  );
  stdout.writeln(
    'Time ms min / average / max: ${summary(times)}; total ${times.reduce((a, b) => a + b)} ms.',
  );
  stdout.writeln(
    'Candidate checks min / average / max: ${summary(results.map((r) => r.generation!.candidateChecks))}.',
  );
  final repeat = SequenceRepeatAnalysis(results);
  final usage = {
    for (final w in c.entries)
      w.solution: repeat.indicesByWord[w.id]?.length ?? 0,
  };
  final top = usage.entries.toList()
    ..sort((a, b) {
      final n = b.value.compareTo(a.value);
      return n != 0 ? n : a.key.compareTo(b.key);
    });
  final gaps = <int>[];
  for (final indices in repeat.indicesByWord.values) {
    for (var i = 1; i < indices.length; i++) {
      gaps.add(indices[i] - indices[i - 1]);
    }
  }
  stdout.writeln('\n## Usage\n');
  stdout.writeln(
    'Unique ${repeat.indicesByWord.length} / ${c.entries.length}; coverage ${(100 * repeat.indicesByWord.length / c.entries.length).toStringAsFixed(2)}%; slots ${count * 10}.',
  );
  stdout.writeln(
    'Usage frequency → number of words: ${histogram(usage.values)}.',
  );
  stdout.writeln(
    'Top 15: ${top.take(15).map((e) => '${e.key}:${e.value}').join(', ')}.',
  );
  stdout.writeln(
    'Repeat distance min / average / max: ${gaps.isEmpty ? 'no repeats' : summary(gaps)}. Average is over consecutive reuse events, not per-word averages.',
  );
  stdout.writeln(
    'Never used (${usage.values.where((n) => n == 0).length}): ${usage.entries.where((e) => e.value == 0).map((e) => e.key).join(', ')}.',
  );
  final first = results.first, p = first.puzzle!, b = p.displayBounds;
  stdout.writeln(
    '\n## App Puzzle 1\n\n${p.id}; seed ${first.seed}; bounds rows ${b.minRow}–${b.maxRow}, columns ${b.minColumn}–${b.maxColumn}; ${times.first} ms.\n',
  );
  for (final a in p.answers) {
    stdout.writeln(
      '- ${a.solution} — ${a.turkishClue} — ${a.direction.name} — start(${a.start.row},${a.start.column}) — clue(${a.cluePosition.row},${a.cluePosition.column})',
    );
  }
}
