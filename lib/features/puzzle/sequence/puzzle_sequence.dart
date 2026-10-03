import '../content/word_catalogue.dart';
import '../domain/puzzle.dart';
import '../generation/puzzle_generator.dart';
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
    this.allowedDifficulties = const {
      WordDifficulty.easy,
      WordDifficulty.medium,
      WordDifficulty.hard,
    },
    this.generation = const PuzzleGenerationConfig(),
  });
  final int baseSeed, cooldownPuzzles;
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
    this.failureReason,
  ) : entries = List.unmodifiable(entries),
      excludedRecentIds = List.unmodifiable(excludedIds.toList()..sort());
  final List<WordEntry> entries;
  final List<String> excludedRecentIds;
  final String? failureReason;
  bool get isSuccess => failureReason == null;
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
      config.allowedDifficulties.isEmpty) {
    return fail('Invalid sequence index, cooldown or difficulty policy.');
  }
  final byId = {for (final w in catalogue.entries) w.id: w};
  final recent = <int, PuzzleHistoryEntry>{};
  final first = puzzleIndex - config.cooldownPuzzles < 1
      ? 1
      : puzzleIndex - config.cooldownPuzzles;
  for (final entry in history) {
    if (entry.puzzleIndex < 1 || entry.puzzleIndex >= puzzleIndex) {
      return fail(
        'History must contain only earlier one-based puzzle indices.',
      );
    }
    if (entry.puzzleIndex < first) continue;
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
  for (var index = first; index < puzzleIndex; index++) {
    if (!recent.containsKey(index)) {
      return fail('Missing cooldown history for puzzle $index.');
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
  });
  final int puzzleIndex, seed, catalogVersion;
  final EligiblePool pool;
  final Puzzle? puzzle;
  final PuzzleGenerationResult? generation;
  final String? failureReason;
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
    SequencePuzzleResult fail(
      String reason, [
      PuzzleGenerationResult? generated,
    ]) => SequencePuzzleResult(
      puzzleIndex: puzzleIndex,
      seed: seed,
      catalogVersion: catalogue.version,
      pool: pool,
      generation: generated,
      failureReason:
          'Puzzle $puzzleIndex (seed $seed; eligible ${pool.entries.length}; '
          'cooldown exclusions ${pool.excludedRecentIds.join(', ')}): $reason',
    );
    if (!pool.isSuccess) return fail(pool.failureReason!);
    final generated = const PuzzleGenerator().generate(
      wordBank: pool.entries,
      seed: seed,
      config: config.generation,
    );
    if (!generated.isSuccess) return fail(generated.failureReason!, generated);
    final board = generated.puzzle!;
    final validation = const PuzzleValidator().validate(
      board,
      expectedAnswerCount: config.generation.targetAnswerCount,
    );
    final allowed = {for (final w in pool.entries) w.id: w.solution};
    final right = board.answers
        .where((a) => a.direction == AnswerDirection.right)
        .length;
    if (!validation.isValid ||
        board.answers.map((a) => a.id).toSet().length != board.answers.length ||
        board.answers.map((a) => a.solution).toSet().length !=
            board.answers.length ||
        board.answers.any((a) => allowed[a.id] != a.solution) ||
        right < config.generation.minAnswersPerDirection ||
        board.answers.length - right <
            config.generation.minAnswersPerDirection ||
        board.crossingPositions.length < config.generation.minCrossings ||
        !board.meaningfulPositions.every(board.displayBounds.containsLogical)) {
      return fail(
        'Generated-board contract failed: ${validation.errors}',
        generated,
      );
    }
    return SequencePuzzleResult(
      puzzleIndex: puzzleIndex,
      seed: seed,
      catalogVersion: catalogue.version,
      pool: pool,
      generation: generated,
      puzzle: Puzzle(
        id: 'generated-v${catalogue.version}-${puzzleIndex.toString().padLeft(6, '0')}',
        label: 'Bulmaca $puzzleIndex',
        rowCount: board.rowCount,
        columnCount: board.columnCount,
        answers: board.answers,
      ),
    );
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
