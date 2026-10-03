import '../content/word_catalogue.dart';
import '../domain/puzzle.dart';
import '../generation/puzzle_generator.dart';
import '../generation/puzzle_metrics.dart';
import '../generation/puzzle_validator.dart';
import '../generation/word_entry.dart';

/// Seed contract v1: MurmurHash3's 32-bit avalanche of baseSeed XOR index.
/// Split multiplication keeps intermediate integers exact even on Dart web.
int derivePuzzleSeed(int baseSeed, int puzzleIndex) {
  if (baseSeed < 0 ||
      baseSeed > 0xffffffff ||
      puzzleIndex < 1 ||
      puzzleIndex > 0xffffffff) {
    throw ArgumentError(
      'Expected uint32 base seed and one-based uint32 index.',
    );
  }
  int multiply32(int a, int b) {
    final low = (a & 0xffff) * (b & 0xffff);
    final high =
        ((a >>> 16) * (b & 0xffff) + (a & 0xffff) * (b >>> 16)) & 0xffff;
    return (low + high * 65536) % 4294967296;
  }

  var x = baseSeed ^ puzzleIndex;
  x = multiply32(x ^ (x >>> 16), 0x85ebca6b);
  x = multiply32(x ^ (x >>> 13), 0xc2b2ae35);
  return (x ^ (x >>> 16)) & 0xffffffff;
}

class PuzzleSequenceConfig {
  const PuzzleSequenceConfig({
    required this.baseSeed,
    this.cooldownPuzzles = 5,
    this.usageBalancingEnabled = true,
    this.boundedSupportEnabled = true,
    this.successfulSupportAttempts = 3,
    this.allowedDifficulties = const {
      WordDifficulty.easy,
      WordDifficulty.medium,
      WordDifficulty.hard,
    },
    this.generation = const PuzzleGenerationConfig(),
  });
  final int baseSeed, cooldownPuzzles;
  final bool usageBalancingEnabled;

  /// False retains the original full-tier policy for developer comparisons.
  final bool boundedSupportEnabled;

  /// At most three successful widening stages; one is useful for diagnostics.
  final int successfulSupportAttempts;
  final Set<WordDifficulty> allowedDifficulties;
  final PuzzleGenerationConfig generation;
}

class PuzzleHistoryEntry {
  PuzzleHistoryEntry({
    required this.puzzleIndex,
    required this.catalogVersion,
    required Map<String, String> words,
  }) : words = Map.unmodifiable(
         words.map(
           (id, solution) => MapEntry(id, solution.trim().toUpperCase()),
         ),
       );
  final int puzzleIndex, catalogVersion;

  /// Stable id -> normalized solution, never object identity.
  final Map<String, String> words;
}

class EligiblePool {
  EligiblePool(
    List<WordEntry> entries,
    Iterable<String> excludedIds,
    this.failureReason, {
    Map<String, WordUsage> usageById = const {},
  }) : entries = List.unmodifiable(entries),
       usageById = Map.unmodifiable(usageById),
       excludedRecentIds = List.unmodifiable(excludedIds.toList()..sort());
  final List<WordEntry> entries;
  final List<String> excludedRecentIds;
  final String? failureReason;

  /// Lifetime counts when balancing is enabled; window counts otherwise.
  final Map<String, WordUsage> usageById;
  bool get isSuccess => failureReason == null;
}

class WordUsage {
  WordUsage(Iterable<int> indices)
    : indices = List.unmodifiable(indices.toList()..sort());
  final List<int> indices;
  int get count => indices.length;
  int? get lastUsedIndex => indices.isEmpty ? null : indices.last;
}

class GenerationPool {
  GenerationPool(
    Iterable<WordEntry> entries,
    Iterable<int> includedUsageTiers, {
    Iterable<String> targetIds = const [],
    Iterable<String> supportIds = const [],
    this.supportCandidateCount = 0,
  }) : entries = List.unmodifiable(
         entries.toList()..sort((a, b) => a.id.compareTo(b.id)),
       ),
       includedUsageTiers = List.unmodifiable(includedUsageTiers),
       targetIds = Set.unmodifiable(targetIds),
       supportIds = List.unmodifiable(supportIds);
  final List<WordEntry> entries;
  final List<int> includedUsageTiers;
  final Set<String> targetIds;
  final List<String> supportIds;
  final int supportCandidateCount;
}

class SupportWord {
  const SupportWord(
    this.word,
    this.usage,
    this.partnerCount,
    this.overlapCount,
  );
  final WordEntry word;
  final WordUsage usage;
  final int partnerCount, overlapCount;

  /// Target neighbors per occupied letter: compact bridges leave more room
  /// for the longer underused targets. Integer arithmetic keeps ties stable.
  int get bridgeScore => partnerCount * 1000 ~/ word.solution.length;
}

/// Count target-word neighbors and matching letter-index pairs, without grids.
List<SupportWord> rankSupportWords(
  EligiblePool eligible,
  List<WordEntry> targets,
) {
  final ids = targets.map((w) => w.id).toSet();
  Map<String, int> letters(String word) {
    final counts = <String, int>{};
    for (final c in word.split('')) {
      counts.update(c, (n) => n + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  final targetLetters = targets.map((w) => letters(w.solution)).toList();
  final ranked = <SupportWord>[];
  for (final word in eligible.entries.where((w) => !ids.contains(w.id))) {
    final counts = letters(word.solution);
    var partners = 0, overlap = 0;
    for (final target in targetLetters) {
      var matches = 0;
      for (final e in counts.entries) {
        matches += e.value * (target[e.key] ?? 0);
      }
      if (matches > 0) partners++;
      overlap += matches;
    }
    ranked.add(
      SupportWord(word, eligible.usageById[word.id]!, partners, overlap),
    );
  }
  ranked.sort((a, b) {
    for (final n in [
      a.usage.count.compareTo(b.usage.count),
      b.bridgeScore.compareTo(a.bridgeScore),
      b.partnerCount.compareTo(a.partnerCount),
      b.overlapCount.compareTo(a.overlapCount),
      (a.usage.lastUsedIndex ?? 0).compareTo(b.usage.lastUsedIndex ?? 0),
    ]) {
      if (n != 0) return n;
    }
    return a.word.id.compareTo(b.word.id);
  });
  return ranked;
}

Iterable<GenerationPool> boundedSupportPools(
  EligiblePool eligible,
  int answerCount,
) sync* {
  if (!eligible.isSuccess) return;
  final minimum = eligible.entries
      .map((w) => eligible.usageById[w.id]!.count)
      .reduce((a, b) => a < b ? a : b);
  final targets = eligible.entries
      .where((w) => eligible.usageById[w.id]!.count == minimum)
      .toList();
  final supports = rankSupportWords(eligible, targets);
  final needed = answerCount > targets.length
      ? answerCount - targets.length
      : 0;
  final sizes = <int>{};
  if (needed == 0) {
    sizes.add(0);
  } else {
    sizes.add(needed);
  }
  for (final size in [2, 4, 16]) {
    if (size >= needed) {
      sizes.add(size < supports.length ? size : supports.length);
    }
  }
  sizes.add(supports.length);
  for (final size in sizes.toList()..sort()) {
    if (size < needed) continue;
    final offered = supports.take(size).map((s) => s.word).toList();
    final tiers = {
      minimum,
      ...offered.map((w) => eligible.usageById[w.id]!.count),
    }.toList()..sort();
    yield GenerationPool(
      [...targets, ...offered],
      tiers,
      targetIds: targets.map((w) => w.id),
      supportIds: offered.map((w) => w.id),
      supportCandidateCount: supports.length,
    );
  }
}

/// Small sequence preference: each minimum-tier answer is worth 180 quality
/// points. The generator remains the sole source of board-quality scoring.
int compareSupportAttempts(BalancingAttempt a, BalancingAttempt b) {
  return compareSupportMetrics(
    a.generation!.metrics!,
    a.selectedTargetCount,
    b.generation!.metrics!,
    b.selectedTargetCount,
  );
}

/// Mobile geometry wins before novelty/quality, but never rejects all-wide pools.
int compareSupportMetrics(
  PuzzleMetrics x,
  int targetA,
  PuzzleMetrics y,
  int targetB,
) {
  final mobile = (x.displayColumnCount <= 9 ? 1 : 0).compareTo(
    y.displayColumnCount <= 9 ? 1 : 0,
  );
  if (mobile != 0) return mobile;
  // Prefer a readable board when one exists; never return an invalid board.
  bool acceptable(PuzzleMetrics m) =>
      m.qualityScore >= 3500 &&
      m.displayColumnCount <= 9 &&
      m.leafAnswerCount <= 3;
  final guard = (acceptable(x) ? 1 : 0).compareTo(acceptable(y) ? 1 : 0);
  if (guard != 0) return guard;
  for (final n in [
    (x.qualityScore + 180 * targetA - (x.displayColumnCount == 10 ? 400 : 0))
        .compareTo(
          y.qualityScore +
              180 * targetB -
              (y.displayColumnCount == 10 ? 400 : 0),
        ),
    targetA.compareTo(targetB),
    y.displayColumnCount.compareTo(x.displayColumnCount),
    x.crossingCount.compareTo(y.crossingCount),
    y.leafAnswerCount.compareTo(x.leafAnswerCount),
  ]) {
    if (n != 0) return n;
  }
  return y.structuralSignature.compareTo(x.structuralSignature);
}

/// Membership, not ordering, expresses fairness. Never admits excluded words.
Iterable<GenerationPool> generationPools(
  EligiblePool eligible, {
  required bool balanced,
}) sync* {
  if (!eligible.isSuccess) return;
  if (!balanced) {
    yield GenerationPool(eligible.entries, const []);
    return;
  }
  final tiers =
      eligible.entries
          .map((w) => eligible.usageById[w.id]!.count)
          .toSet()
          .toList()
        ..sort();
  for (var i = 0; i < tiers.length; i++) {
    yield GenerationPool(
      eligible.entries.where(
        (w) => eligible.usageById[w.id]!.count <= tiers[i],
      ),
      tiers.take(i + 1),
    );
  }
}

class BalancingAttempt {
  const BalancingAttempt(this.pool, this.generation, this.failureReason);
  final GenerationPool pool;

  /// Null means skipped because fewer than targetAnswerCount entries remain.
  final PuzzleGenerationResult? generation;
  final String? failureReason;
  bool get isSuccess => failureReason == null;
  int get selectedTargetCount =>
      generation?.puzzle?.answers
          .where((a) => pool.targetIds.contains(a.id))
          .length ??
      0;
  int get selectedSupportCount =>
      (generation?.puzzle?.answers.length ?? 0) - selectedTargetCount;
}

EligiblePool buildEligiblePool({
  required WordCatalogue catalogue,
  required PuzzleSequenceConfig config,
  required int puzzleIndex,
  List<PuzzleHistoryEntry> history = const [],
}) {
  EligiblePool fail(String reason) => EligiblePool(const [], const [], reason);
  if (!catalogue.isValid) {
    return fail(
      'Invalid catalogue: ${catalogue.issues.where((i) => !i.warning).join('; ')}',
    );
  }
  if (puzzleIndex < 1 ||
      config.cooldownPuzzles < 0 ||
      config.generation.targetAnswerCount < 1 ||
      config.successfulSupportAttempts < 1 ||
      config.successfulSupportAttempts > 3 ||
      config.allowedDifficulties.isEmpty) {
    return fail(
      'Invalid sequence index, target count, cooldown or difficulty policy.',
    );
  }
  final byId = {for (final w in catalogue.entries) w.id: w};
  final recent = <int, PuzzleHistoryEntry>{};
  final first = puzzleIndex - config.cooldownPuzzles < 1
      ? 1
      : puzzleIndex - config.cooldownPuzzles;
  final requiredFirst = config.usageBalancingEnabled ? 1 : first;
  for (final entry in history) {
    if (entry.puzzleIndex < 1 || entry.puzzleIndex >= puzzleIndex) {
      return fail(
        'History must contain only earlier one-based puzzle indices.',
      );
    }
    if (entry.puzzleIndex < requiredFirst) continue;
    if (entry.catalogVersion != catalogue.version ||
        recent.containsKey(entry.puzzleIndex)) {
      return fail(
        'History version mismatch or duplicate index ${entry.puzzleIndex}.',
      );
    }
    if (entry.words.length != config.generation.targetAnswerCount ||
        entry.words.values.toSet().length != entry.words.length ||
        entry.words.entries.any((w) => byId[w.key]?.solution != w.value)) {
      return fail('Invalid history vocabulary at puzzle ${entry.puzzleIndex}.');
    }
    recent[entry.puzzleIndex] = entry;
  }
  for (var index = requiredFirst; index < puzzleIndex; index++) {
    if (!recent.containsKey(index)) {
      return fail(
        'Missing ${config.usageBalancingEnabled ? 'lifetime' : 'cooldown'} history for puzzle $index.',
      );
    }
  }
  final excludedIds = <String>{}, excludedSolutions = <String>{};
  for (var index = first; index < puzzleIndex; index++) {
    excludedIds.addAll(recent[index]!.words.keys);
    excludedSolutions.addAll(recent[index]!.words.values);
  }
  final eligible =
      catalogue.entries
          .where(
            (w) =>
                config.allowedDifficulties.contains(w.difficulty) &&
                !excludedIds.contains(w.id) &&
                !excludedSolutions.contains(w.solution),
          )
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
  return EligiblePool(
    eligible,
    excludedIds,
    eligible.length < config.generation.targetAnswerCount
        ? 'Insufficient eligible vocabulary after cooldown/difficulty filtering: ${eligible.length} available, ${config.generation.targetAnswerCount} required.'
        : null,
    usageById: {
      for (final w in catalogue.entries)
        w.id: WordUsage(
          recent.values
              .where((e) => e.words.containsKey(w.id))
              .map((e) => e.puzzleIndex),
        ),
    },
  );
}

class SequencePuzzleResult {
  const SequencePuzzleResult({
    required this.puzzleIndex,
    required this.seed,
    required this.catalogVersion,
    required this.pool,
    this.puzzle,
    this.generation,
    this.failureReason,
    this.attempts = const [],
    this.selectedAttempt,
    this.selectionReason = '',
  });
  final int puzzleIndex, seed, catalogVersion;
  final EligiblePool pool;
  final Puzzle? puzzle;
  final PuzzleGenerationResult? generation;
  final String? failureReason;
  final List<BalancingAttempt> attempts;
  final BalancingAttempt? selectedAttempt;
  final String selectionReason;
  BalancingAttempt? get finalAttempt =>
      selectedAttempt ?? (attempts.isEmpty ? null : attempts.last);
  int get generationPoolCount => finalAttempt?.pool.entries.length ?? 0;
  int? get minimumEligibleUsage =>
      attempts.isEmpty || attempts.first.pool.includedUsageTiers.isEmpty
      ? null
      : attempts.first.pool.includedUsageTiers.first;
  int? get maximumIncludedUsage =>
      finalAttempt == null || finalAttempt!.pool.includedUsageTiers.isEmpty
      ? null
      : finalAttempt!.pool.includedUsageTiers.last;
  bool get usagePreferenceWidened => attempts.length > 1;
  int get totalCandidateChecks =>
      attempts.fold(0, (n, a) => n + (a.generation?.candidateChecks ?? 0));
  bool get isSuccess => puzzle != null && failureReason == null;
  PuzzleHistoryEntry toHistory() {
    if (!isSuccess) throw StateError('Failed puzzles cannot enter history.');
    return PuzzleHistoryEntry(
      puzzleIndex: puzzleIndex,
      catalogVersion: catalogVersion,
      words: {for (final a in puzzle!.answers) a.id: a.solution},
    );
  }
}

class PuzzleSequenceResult {
  PuzzleSequenceResult(List<SequencePuzzleResult> puzzles, this.failure)
    : puzzles = List.unmodifiable(puzzles);
  final List<SequencePuzzleResult> puzzles;
  final SequencePuzzleResult? failure;
  bool get isSuccess => failure == null;
}

class PuzzleSequenceGenerator {
  const PuzzleSequenceGenerator(this.catalogue, this.config);
  final WordCatalogue catalogue;
  final PuzzleSequenceConfig config;

  SequencePuzzleResult generateNext({
    required int puzzleIndex,
    List<PuzzleHistoryEntry> history = const [],
  }) {
    final seed = derivePuzzleSeed(config.baseSeed, puzzleIndex);
    final pool = buildEligiblePool(
      catalogue: catalogue,
      config: config,
      puzzleIndex: puzzleIndex,
      history: history,
    );
    final attempts = <BalancingAttempt>[];
    SequencePuzzleResult fail(
      String reason, [
      PuzzleGenerationResult? generated,
    ]) => SequencePuzzleResult(
      puzzleIndex: puzzleIndex,
      seed: seed,
      catalogVersion: catalogue.version,
      pool: pool,
      generation: generated,
      attempts: List.unmodifiable(attempts),
      failureReason:
          'Puzzle $puzzleIndex (seed $seed; eligible ${pool.entries.length}; '
          'cooldown exclusions ${pool.excludedRecentIds.join(', ')}; '
          'attempts ${attempts.map((a) => '${a.pool.includedUsageTiers}:${a.pool.entries.length}').join('; ')}): $reason',
    );
    if (!pool.isSuccess) return fail(pool.failureReason!);
    final bounded =
        config.usageBalancingEnabled && config.boundedSupportEnabled;
    BalancingAttempt? best;
    var successes = 0;
    final choices = bounded
        ? boundedSupportPools(pool, config.generation.targetAnswerCount)
        : generationPools(pool, balanced: config.usageBalancingEnabled);
    for (final selected in choices) {
      if (selected.entries.length < config.generation.targetAnswerCount) {
        attempts.add(
          BalancingAttempt(
            selected,
            null,
            'Insufficient generation-pool entries; skipped.',
          ),
        );
        continue;
      }
      // Every tier uses the same index-derived seed and unchanged search budget.
      final generated = const PuzzleGenerator().generate(
        wordBank: selected.entries,
        seed: seed,
        config: config.generation,
      );
      attempts.add(
        BalancingAttempt(selected, generated, generated.failureReason),
      );
      if (!generated.isSuccess) continue;
      final board = generated.puzzle!;
      final validation = const PuzzleValidator().validate(
        board,
        expectedAnswerCount: config.generation.targetAnswerCount,
      );
      final allowed = {for (final w in selected.entries) w.id: w.solution};
      final right = board.answers
          .where((a) => a.direction == AnswerDirection.right)
          .length;
      if (!validation.isValid ||
          board.answers.map((a) => a.id).toSet().length !=
              board.answers.length ||
          board.answers.map((a) => a.solution).toSet().length !=
              board.answers.length ||
          board.answers.any((a) => allowed[a.id] != a.solution) ||
          right < config.generation.minAnswersPerDirection ||
          board.answers.length - right <
              config.generation.minAnswersPerDirection ||
          board.crossingPositions.length < config.generation.minCrossings ||
          !board.meaningfulPositions.every(
            board.displayBounds.containsLogical,
          )) {
        return fail(
          'Generated-board contract failed: ${validation.errors}',
          generated,
        );
      }
      final candidate = attempts.last;
      successes++;
      if (best == null ||
          (bounded && compareSupportAttempts(candidate, best) > 0)) {
        best = candidate;
      }
      final m = generated.metrics!;
      if (!bounded ||
          (m.qualityScore >= 3900 &&
              m.displayColumnCount <= 9 &&
              m.leafAnswerCount <= 3) ||
          successes >= config.successfulSupportAttempts) {
        break;
      }
    }
    if (best != null) {
      final generated = best.generation!, board = generated.puzzle!;
      return SequencePuzzleResult(
        puzzleIndex: puzzleIndex,
        seed: seed,
        catalogVersion: catalogue.version,
        pool: pool,
        generation: generated,
        attempts: List.unmodifiable(attempts),
        selectedAttempt: best,
        selectionReason: bounded
            ? 'Prefer <=9 columns first, then quality >=3500 / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among $successes successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or ${config.successfulSupportAttempts} successes.'
            : 'First valid complete tier.',
        puzzle: Puzzle(
          id: 'generated-v${catalogue.version}-${puzzleIndex.toString().padLeft(6, '0')}',
          label: 'Bulmaca $puzzleIndex',
          rowCount: board.rowCount,
          columnCount: board.columnCount,
          answers: board.answers,
        ),
      );
    }
    return fail(attempts.last.failureReason!, attempts.last.generation);
  }

  /// Replay from index 1 so direct range access never skips cooldown history.
  /// Call generateNext with verified in-memory history to continue cheaply.
  PuzzleSequenceResult generateRange({int startIndex = 1, int count = 10}) {
    if (startIndex < 1 || count < 1 || startIndex + count - 1 > 0xffffffff) {
      throw ArgumentError('Invalid one-based sequence range.');
    }
    final history = <PuzzleHistoryEntry>[];
    final output = <SequencePuzzleResult>[];
    for (var index = 1; index < startIndex + count; index++) {
      final result = generateNext(puzzleIndex: index, history: history);
      if (!result.isSuccess) return PuzzleSequenceResult(output, result);
      history.add(result.toHistory());
      if (index >= startIndex) output.add(result);
    }
    return PuzzleSequenceResult(output, null);
  }
}

class SequenceRepeatAnalysis {
  SequenceRepeatAnalysis(List<SequencePuzzleResult> puzzles) {
    final usage = <String, List<int>>{};
    for (final puzzle in puzzles) {
      for (final a in puzzle.puzzle!.answers) {
        usage.putIfAbsent(a.id, () => []).add(puzzle.puzzleIndex);
      }
    }
    indicesByWord = Map.unmodifiable({
      for (final id in usage.keys.toList()..sort())
        id: List<int>.unmodifiable(usage[id]!..sort()),
    });
    minimumDistanceByWord = Map.unmodifiable({
      for (final entry in indicesByWord.entries)
        entry.key: _minimumDistance(entry.value),
    });
  }
  late final Map<String, List<int>> indicesByWord;
  late final Map<String, int?> minimumDistanceByWord;
  int get repeatedWordCount =>
      minimumDistanceByWord.values.whereType<int>().length;
  int? get minimumDistance => minimumDistanceByWord.values
      .whereType<int>()
      .fold<int?>(null, (a, b) => a == null || b < a ? b : a);
  static int? _minimumDistance(List<int> indices) {
    int? distance;
    for (var i = 1; i < indices.length; i++) {
      final gap = indices[i] - indices[i - 1];
      if (distance == null || gap < distance) distance = gap;
    }
    return distance;
  }
}
