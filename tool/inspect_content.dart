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
  final counts = arguments.where((a) => !a.startsWith('--')).toList();
  final count = counts.isEmpty ? 30 : int.parse(counts.single);
  final known = {'--compare', '--unbalanced', '--naive'};
  if (arguments.any((a) => a.startsWith('--') && !known.contains(a))) {
    throw ArgumentError('Use [count] [--compare | --unbalanced | --naive].');
  }
  if (arguments.contains('--compare')) {
    final baseline = inspectSequence(count, balanced: false);
    final naive = inspectSequence(count, balanced: true, bounded: false);
    final fair = inspectSequence(count, balanced: true);
    stdout.writeln(
      '\n## Comparison (same records and seed, current-run timings)\n',
    );
    stdout.writeln('| Metric | Unbalanced | Naive v3 | Bounded support |');
    stdout.writeln('|---|---|---|---|');
    for (final key in baseline.keys) {
      stdout.writeln(
        '| $key | ${baseline[key]} | ${naive[key]} | ${fair[key]} |',
      );
    }
  } else {
    inspectSequence(
      count,
      balanced: !arguments.contains('--unbalanced'),
      bounded: !arguments.contains('--naive'),
    );
  }
}

Map<String, num> inspectSequence(
  int count, {
  required bool balanced,
  bool bounded = true,
}) {
  if (count < 1) throw ArgumentError('Count must be positive.');
  final c = prototypeCatalogue, h = c.health;
  if (!c.isValid ||
      c.version != 3 ||
      h.lowPartnerIds(maximum: 0).isNotEmpty ||
      h.totalCount != 300) {
    throw StateError('Invalid v3 catalogue: ${c.issues}');
  }
  stdout.writeln(
    '# Catalogue v3 stress report — balanced=$balanced, bounded=$bounded\n',
  );
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
    PuzzleSequenceConfig(
      usageBalancingEnabled: balanced,
      boundedSupportEnabled: bounded,
      baseSeed: prototypeBaseSeed,
      cooldownPuzzles: 5,
      generation: prototypeGenerationConfig,
    ),
  );
  final results = <SequencePuzzleResult>[], times = <int>[];
  stdout.writeln(
    '| Index | ID | Seed | Eligible | Generation pool | Tiers | Attempts | Score | Crossings | Leaves | Rows×cols | Density | ms (all attempts) | Checks (all attempts) | Nodes (final attempt) | Complete (final attempt) |',
  );
  stdout.writeln(
    '|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|',
  );
  for (var index = 1; index <= count; index++) {
    final watch = Stopwatch()..start();
    final r = sequence.generateNext(
      puzzleIndex: index,
      history: results.map((r) => r.toHistory()).toList(),
    );
    watch.stop();
    verifyStressPuzzle(r, results);
    final verified = buildEligiblePool(
      catalogue: c,
      config: sequence.config,
      puzzleIndex: index,
      history: results.map((r) => r.toHistory()).toList(),
    );
    if (!verified.isSuccess) throw StateError(verified.failureReason!);
    results.add(r);
    times.add(watch.elapsedMilliseconds);
    final g = r.generation!, m = g.metrics!;
    stdout.writeln(
      '| $index | ${r.puzzle!.id} | ${r.seed} | ${r.pool.entries.length} | ${r.generationPoolCount} | ${r.finalAttempt!.pool.includedUsageTiers} | ${r.attempts.length} | ${m.qualityScore} | ${m.crossingCount} | ${m.leafAnswerCount} | ${m.displayRowCount}×${m.displayColumnCount} | ${m.density.toStringAsFixed(4)} | ${times.last} | ${r.totalCandidateChecks} | ${g.searchNodes} | ${g.completeSolutionsFound} |',
    );
  }
  stdout.writeln('\nAnswers and attempt outcomes:');
  for (final r in results) {
    stdout.writeln(
      '- ${r.puzzleIndex}: ${r.puzzle!.answers.map((a) => a.solution).join(', ')}; cooldown excluded ${r.pool.excludedRecentIds.length}; min usage ${r.minimumEligibleUsage}; widened ${r.usagePreferenceWidened}; ${r.attempts.map((a) => 'tiers=${a.pool.includedUsageTiers}, pool=${a.pool.entries.length}, ${a.failureReason ?? 'success'}').join(' / ')}',
    );
  }
  stdout.writeln(
    'Attempts min / average / max: ${summary(results.map((r) => r.attempts.length))}.',
  );
  stdout.writeln('Support diagnostics:');
  for (final r in results) {
    final selected = r.finalAttempt!;
    stdout.writeln(
      '- ${r.puzzleIndex}: target pool ${selected.pool.targetIds.length}; candidates ${selected.pool.supportCandidateCount}; offered ${selected.pool.supportIds}; selected target/support ${selected.selectedTargetCount}/${selected.selectedSupportCount}; successes ${r.attempts.where((a) => a.isSuccess).length}; ${r.selectionReason}',
    );
    for (final a in r.attempts) {
      stdout.writeln(
        '  stage: support ${a.pool.supportIds.length}; ids ${a.pool.supportIds}; tiers ${a.pool.includedUsageTiers}; selected target/support ${a.selectedTargetCount}/${a.selectedSupportCount}; ${a.failureReason ?? 'success'}',
      );
    }
  }
  stdout.writeln(
    'Chosen support-size histogram: ${histogram(results.map((r) => r.finalAttempt!.pool.supportIds.length))}; target/support answers average: ${results.fold<int>(0, (n, r) => n + r.finalAttempt!.selectedTargetCount) / count}/${results.fold<int>(0, (n, r) => n + r.finalAttempt!.selectedSupportCount) / count}.',
  );
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
    'Candidate checks min / average / max: ${summary(results.map((r) => r.totalCandidateChecks))}.',
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
  final byId = {for (final w in c.entries) w.id: w};
  final slots = results
      .expand((r) => r.puzzle!.answers)
      .map((a) => byId[a.id]!)
      .toList();
  final used = repeat.indicesByWord.keys.map((id) => byId[id]!).toList();
  stdout.writeln(
    'Difficulty slots: ${histogram(slots.map((w) => w.difficulty.name))}; unique: ${histogram(used.map((w) => w.difficulty.name))}.',
  );
  stdout.writeln(
    'Length slots: ${histogram(slots.map((w) => w.solution.length))}; unique: ${histogram(used.map((w) => w.solution.length))}.',
  );
  for (final length in [4, 5, 6, 7]) {
    final n = used.where((w) => w.solution.length == length).length;
    stdout.writeln(
      'Length $length coverage: $n/${h.lengthCounts[length]} (${(100 * n / h.lengthCounts[length]!).toStringAsFixed(2)}%).',
    );
  }
  double average(Iterable<num> values) =>
      values.fold<num>(0, (a, b) => a + b) / values.length;
  return {
    'unique words': used.length,
    'coverage percent': 100 * used.length / c.entries.length,
    'maximum usage': top.first.value,
    'unused': usage.values.where((n) => n == 0).length,
    'maximum quality': scores.last,
    'minimum crossings': metrics
        .map((m) => m.crossingCount)
        .reduce((a, b) => a < b ? a : b),
    'maximum crossings': metrics
        .map((m) => m.crossingCount)
        .reduce((a, b) => a > b ? a : b),
    'ten-column boards': metrics
        .where((m) => m.displayColumnCount == 10)
        .length,
    'minimum repeat distance': gaps.isEmpty
        ? 0
        : gaps.reduce((a, b) => a < b ? a : b),
    'average repeat distance': gaps.isEmpty ? 0 : average(gaps),
    'maximum repeat distance': gaps.isEmpty
        ? 0
        : gaps.reduce((a, b) => a > b ? a : b),
    'minimum ms': times.reduce((a, b) => a < b ? a : b),
    'maximum ms': times.reduce((a, b) => a > b ? a : b),
    'total ms': times.reduce((a, b) => a + b),
    'maximum attempts': results
        .map((r) => r.attempts.length)
        .reduce((a, b) => a > b ? a : b),
    'maximum candidate checks': results
        .map((r) => r.totalCandidateChecks)
        .reduce((a, b) => a > b ? a : b),
    'average quality': average(scores),
    'minimum quality': scores.first,
    'average crossings': average(metrics.map((m) => m.crossingCount)),
    'average ms': average(times),
    'average attempts': average(results.map((r) => r.attempts.length)),
    'average candidate checks': average(
      results.map((r) => r.totalCandidateChecks),
    ),
  };
}
