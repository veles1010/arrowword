import 'package:arrowword/features/puzzle/content/word_catalogue.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_generator.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_metrics.dart';
import 'package:arrowword/features/puzzle/generation/word_entry.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final c = WordCatalogue(
    version: 3,
    entries: const [
      WordEntry('APPLE', 'Elma'),
      WordEntry('PEAR', 'Armut'),
      WordEntry('RAIN', 'Yağmur'),
      WordEntry('TREE', 'Ağaç'),
    ],
  );
  const single = PuzzleGenerationConfig(
    targetAnswerCount: 1,
    minAnswersPerDirection: 0,
    minCrossings: 0,
  );
  PuzzleSequenceConfig policy({
    bool balanced = true,
    bool bounded = false,
    int cooldown = 0,
    PuzzleGenerationConfig generation = single,
  }) => PuzzleSequenceConfig(
    baseSeed: prototypeBaseSeed,
    usageBalancingEnabled: balanced,
    boundedSupportEnabled: bounded,
    cooldownPuzzles: cooldown,
    generation: generation,
  );
  PuzzleHistoryEntry h(int index, String solution, {int version = 3}) =>
      PuzzleHistoryEntry(
        puzzleIndex: index,
        catalogVersion: version,
        words: {solution.toLowerCase(): solution},
      );
  final history = [h(1, 'TREE'), h(2, 'RAIN'), h(3, 'TREE')];
  EligiblePool pool(
    List<PuzzleHistoryEntry> history, {
    int index = 4,
    PuzzleSequenceConfig? config,
  }) => buildEligiblePool(
    catalogue: c,
    config: config ?? policy(),
    puzzleIndex: index,
    history: history,
  );

  test(
    'verified lifetime stats include unseen, repeated and last-used entries',
    () {
      final p = pool(history), reversed = pool(history.reversed.toList());
      expect(p.isSuccess, isTrue);
      expect(p.usageById['apple']!.count, 0);
      expect(p.usageById['apple']!.lastUsedIndex, isNull);
      expect(p.usageById['rain']!.count, 1);
      expect(p.usageById['tree']!.count, 2);
      expect(p.usageById['tree']!.lastUsedIndex, 3);
      expect(p.usageById['tree']!.indices, [1, 3]);
      expect(
        p.usageById.map((k, v) => MapEntry(k, v.indices)),
        reversed.usageById.map((k, v) => MapEntry(k, v.indices)),
      );
      expect(
        () => p.usageById['tree']!.indices.clear(),
        throwsUnsupportedError,
      );
    },
  );
  test(
    'usage tiers widen cumulatively by membership, independent of order',
    () {
      final pools = generationPools(pool(history), balanced: true).toList();
      expect(pools.map((p) => p.entries.map((w) => w.solution).toList()), [
        ['APPLE', 'PEAR'],
        ['APPLE', 'PEAR', 'RAIN'],
        ['APPLE', 'PEAR', 'RAIN', 'TREE'],
      ]);
      expect(pools.map((p) => p.includedUsageTiers), [
        [0],
        [0, 1],
        [0, 1, 2],
      ]);
    },
  );
  test('cooldown and difficulty exclusions survive every usage tier', () {
    final p = pool(history, config: policy(cooldown: 1));
    expect(p.excludedRecentIds, ['tree']);
    // Even deliberately stale zero-use metadata cannot reintroduce an entry
    // excluded from the eligible membership by cooldown.
    final stale = EligiblePool(
      p.entries,
      p.excludedRecentIds,
      null,
      usageById: {for (final w in c.entries) w.id: WordUsage([])},
    );
    expect(
      generationPools(
        stale,
        balanced: true,
      ).expand((p) => p.entries).any((w) => w.id == 'tree'),
      isFalse,
    );
    final frequent = pool(
      [for (var i = 1; i <= 5; i++) h(i, 'TREE'), h(6, 'RAIN')],
      index: 7,
      config: policy(cooldown: 1),
    );
    final tiers = generationPools(frequent, balanced: true).toList();
    expect(tiers.last.includedUsageTiers, [0, 5]);
    expect(tiers.last.entries.map((w) => w.id), contains('tree'));
    expect(tiers.last.entries.map((w) => w.id), isNot(contains('rain')));
  });
  test('full history rejects missing older entries, duplicate indices and v2 history', () {
    expect(
      pool(history.skip(1).toList()).failureReason,
      contains('Missing lifetime history for puzzle 1'),
    );
    expect(
      pool([...history, history.first]).failureReason,
      contains('duplicate'),
    );
    expect(
      pool([h(1, 'TREE', version: 2), ...history.skip(1)]).failureReason,
      contains('version'),
    );
    final invalid = PuzzleHistoryEntry(
      puzzleIndex: 1,
      catalogVersion: 3,
      words: {'tree': 'APPLE'},
    );
    expect(
      pool([invalid, ...history.skip(1)]).failureReason,
      contains('Invalid history'),
    );
  });
  test(
    'Puzzle 10 requires 1–9 when balanced; disabled mode needs only 5–9',
    () {
      final words = prototypeCatalogue.entries.take(9).toList();
      final full = [for (var i = 0; i < 9; i++) h(i + 1, words[i].solution)];
      final balanced = PuzzleSequenceGenerator(
        prototypeCatalogue,
        policy(cooldown: 5),
      );
      final missing = balanced.generateNext(
        puzzleIndex: 10,
        history: full.skip(4).toList(),
      );
      expect(missing.failureReason, contains('Missing lifetime'));
      expect(missing.generation, isNull);
      expect(
        balanced.generateNext(puzzleIndex: 10, history: full).isSuccess,
        isTrue,
      );
      final disabled = PuzzleSequenceGenerator(
        prototypeCatalogue,
        policy(balanced: false, cooldown: 5),
      );
      expect(
        disabled
            .generateNext(puzzleIndex: 10, history: full.skip(4).toList())
            .isSuccess,
        isTrue,
      );
    },
  );
  test(
    'failed minimum tier widens with the same seed, preserving diagnostics',
    () {
      final bank = WordCatalogue(
        version: 3,
        entries: const [WordEntry('APPLE', 'Elma'), WordEntry('TREE', 'Ağaç')],
      );
      // APPLE cannot fit a five-cell axis including its clue; TREE can.
      const grid = PuzzleGenerationConfig(
        rows: 5,
        columns: 5,
        targetAnswerCount: 1,
        minAnswersPerDirection: 0,
        minCrossings: 0,
      );
      final r = PuzzleSequenceGenerator(
        bank,
        policy(generation: grid),
      ).generateNext(puzzleIndex: 2, history: [h(1, 'TREE')]);
      expect(r.isSuccess, isTrue, reason: r.failureReason);
      expect(r.attempts, hasLength(2));
      expect(r.attempts.first.generation!.isSuccess, isFalse);
      expect(r.attempts.last.pool.includedUsageTiers, [0, 1]);
      expect(r.usagePreferenceWidened, isTrue);
      expect(r.puzzle!.answers.single.solution, 'TREE');
      final direct = const PuzzleGenerator().generate(
        wordBank: bank.entries,
        seed: r.seed,
        config: grid,
      );
      expect(
        puzzleStructuralSignature(r.puzzle!),
        puzzleStructuralSignature(direct.puzzle!),
      );
      expect(
        r.totalCandidateChecks,
        r.attempts.fold<int>(
          0,
          (sum, a) => sum + (a.generation?.candidateChecks ?? 0),
        ),
      );
    },
  );
  test('undersized tier is recorded and skipped, not passed to generator', () {
    final bank = WordCatalogue(
      version: 3,
      entries: const [
        WordEntry('APPLE', 'Elma'),
        WordEntry('TREE', 'Ağaç'),
        WordEntry('PEAR', 'Armut'),
      ],
    );
    const grid = PuzzleGenerationConfig(
      targetAnswerCount: 2,
      minAnswersPerDirection: 1,
      minCrossings: 1,
    );
    final hist = PuzzleHistoryEntry(
      puzzleIndex: 1,
      catalogVersion: 3,
      words: {'tree': 'TREE', 'pear': 'PEAR'},
    );
    final r = PuzzleSequenceGenerator(
      bank,
      policy(generation: grid),
    ).generateNext(puzzleIndex: 2, history: [hist]);
    expect(r.attempts.length, 2);
    expect(r.attempts.first.pool.entries, hasLength(1));
    expect(r.attempts.first.generation, isNull);
    expect(r.attempts.first.failureReason, contains('skipped'));
    expect(r.isSuccess, isTrue, reason: r.failureReason);
  });
  test('all-tier exhaustion is explicit and never relaxes cooldown', () {
    final r = PuzzleSequenceGenerator(
      c,
      policy(
        cooldown: 1,
        generation: const PuzzleGenerationConfig(
          rows: 3,
          columns: 3,
          targetAnswerCount: 1,
          minAnswersPerDirection: 0,
          minCrossings: 0,
        ),
      ),
    ).generateNext(puzzleIndex: 4, history: history);
    expect(r.isSuccess, isFalse);
    expect(r.puzzle, isNull);
    expect(r.attempts, hasLength(2));
    expect(r.generationPoolCount, 3);
    expect(
      r.attempts.every((a) => !a.pool.entries.any((w) => w.id == 'tree')),
      isTrue,
    );
    expect(r.failureReason, contains('cooldown exclusions tree'));
    expect(r.failureReason, contains('attempts'));
    expect(r.failureReason, contains(r.generation!.failureReason!));
  });
  test(
    'widening visits all distinct tiers instead of jumping to full pool',
    () {
      final bank = WordCatalogue(
        version: 3,
        entries: const [
          WordEntry('APPLE', 'Elma'),
          WordEntry('PEACH', 'Şeftali'),
          WordEntry('TREE', 'Ağaç'),
        ],
      );
      const grid = PuzzleGenerationConfig(
        rows: 5,
        columns: 5,
        targetAnswerCount: 1,
        minAnswersPerDirection: 0,
        minCrossings: 0,
      );
      final r = PuzzleSequenceGenerator(bank, policy(generation: grid))
          .generateNext(
            puzzleIndex: 4,
            history: [h(1, 'PEACH'), h(2, 'TREE'), h(3, 'TREE')],
          );
      expect(r.isSuccess, isTrue, reason: r.failureReason);
      expect(r.attempts.map((a) => a.pool.includedUsageTiers), [
        [0],
        [0, 1],
        [0, 1, 2],
      ]);
      expect(r.attempts.map((a) => a.isSuccess), [false, false, true]);
      expect(r.maximumIncludedUsage, 2);
    },
  );
  test('widening cannot restore difficulty-filtered content', () {
    final bank = WordCatalogue(
      version: 3,
      entries: const [
        WordEntry('APPLE', 'Elma'),
        WordEntry('TREE', 'Ağaç'),
        WordEntry('RAIN', 'Yağmur', difficulty: WordDifficulty.hard),
      ],
    );
    final p = buildEligiblePool(
      catalogue: bank,
      config: const PuzzleSequenceConfig(
        baseSeed: 1,
        cooldownPuzzles: 0,
        allowedDifficulties: {WordDifficulty.easy},
        generation: single,
      ),
      puzzleIndex: 2,
      history: [h(1, 'TREE')],
    );
    expect(
      generationPools(p, balanced: true).map((p) => p.entries.map((w) => w.id)),
      [
        ['apple'],
        ['apple', 'tree'],
      ],
    );
  });
}
