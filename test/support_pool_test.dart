import 'package:arrowword/features/puzzle/content/word_catalogue.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_generator.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_metrics.dart';
import 'package:arrowword/features/puzzle/generation/word_entry.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'mobile geometry wins even below quality guard or with less novelty',
    () {
      const narrow = _Metrics(columns: 9, qualityScore: 3400);
      const wide = _Metrics(columns: 10, qualityScore: 4200);
      expect(compareSupportMetrics(narrow, 6, wide, 10), greaterThan(0));
      expect(compareSupportMetrics(wide, 10, narrow, 6), lessThan(0));
    },
  );
  test(
    'within mobile geometry novelty and quality comparison is preserved',
    () {
      const a = _Metrics(columns: 9, qualityScore: 3900);
      const b = _Metrics(columns: 9, qualityScore: 4000);
      expect(compareSupportMetrics(a, 10, b, 9), greaterThan(0));
      expect(compareSupportMetrics(a, 9, b, 9), lessThan(0));
      expect(compareSupportMetrics(a, 9, a, 9), 0);
    },
  );
  test(
    'all-wide successes still rank by existing comparison instead of failing',
    () {
      const a = _Metrics(columns: 10, qualityScore: 3900);
      const b = _Metrics(columns: 10, qualityScore: 4000);
      expect(compareSupportMetrics(a, 10, b, 9), greaterThan(0));
      expect(compareSupportMetrics(a, 9, b, 9), lessThan(0));
    },
  );
  test(
    'Puzzle 1 stays stable and quality guard rejects a weak novelty winner',
    () {
      final first = generatePrototypePuzzle();
      expect(first.puzzle!.answers.map((a) => a.solution), [
        'BROTHER',
        'ROOM',
        'RAIN',
        'UNCLE',
        'HOME',
        'MOON',
        'FACE',
        'EXAM',
        'MEAT',
        'FARM',
      ]);
      final m = first.generation!.metrics!;
      expect(
        [
          m.qualityScore,
          m.crossingCount,
          m.leafAnswerCount,
          m.displayRowCount,
          m.displayColumnCount,
        ],
        [4216, 12, 1, 9, 8],
      );
      final strong = BalancingAttempt(
        GenerationPool(first.finalAttempt!.pool.entries, [0]),
        first.generation,
        null,
      );
      const words = [WordEntry('AAAA', 'Test')];
      final weak = const PuzzleGenerator().generate(
        wordBank: words,
        seed: 1,
        config: const PuzzleGenerationConfig(
          rows: 5,
          columns: 5,
          targetAnswerCount: 1,
          minAnswersPerDirection: 0,
          minCrossings: 0,
        ),
      );
      final novel = BalancingAttempt(
        GenerationPool(words, [0], targetIds: ['aaaa']),
        weak,
        null,
      );
      expect(compareSupportAttempts(strong, novel), greaterThan(0));
    },
  );
  EligiblePool pool(
    List<WordEntry> words,
    Map<String, List<int>> indices, {
    List<String> excluded = const [],
  }) => EligiblePool(
    words.where((w) => !excluded.contains(w.id)).toList(),
    excluded,
    null,
    usageById: {for (final w in words) w.id: WordUsage(indices[w.id] ?? [])},
  );
  List<String> ranked(EligiblePool p, List<WordEntry> targets) =>
      rankSupportWords(p, targets).map((s) => s.word.id).toList();

  test(
    'bridge score rewards distinct target neighbors and compact connectivity',
    () {
      const targets = [
        WordEntry('APPLE', 'Elma'),
        WordEntry('TREE', 'Ağaç'),
        WordEntry('RAIN', 'Yağmur'),
      ];
      const supports = [
        WordEntry('TEAR', 'Gözyaşı'),
        WordEntry('WXYZ', 'Test'),
      ];
      final p = pool(
        [...targets, ...supports],
        {
          'tear': [1],
          'wxyz': [1],
        },
      );
      final scores = rankSupportWords(p, targets);
      expect(scores.first.word.solution, 'TEAR');
      expect(scores.first.partnerCount, 3);
      expect(scores.last.partnerCount, 0);
      expect(scores.first.overlapCount, greaterThan(0));
      expect(scores.first.bridgeScore, 750);
    },
  );
  test(
    'usage outranks connectivity and recency; recency and ID break exact ties',
    () {
      const targets = [WordEntry('TREE', 'Ağaç')];
      const words = [
        ...targets,
        WordEntry('WXYZ', 'Test'),
        WordEntry('TEAR', 'Test', id: 'tear-z'),
        WordEntry('RATE', 'Test', id: 'rate-a'),
        WordEntry('EAST', 'Test'),
      ];
      final p = pool(words, {
        'wxyz': [9],
        'tear-z': [1, 2],
        'rate-a': [1, 2],
        'east': [3, 4],
      });
      expect(ranked(p, targets).first, 'wxyz');
      expect(
        ranked(p, targets).indexOf('rate-a'),
        lessThan(ranked(p, targets).indexOf('tear-z')),
      );
      // Same letter multiset and score: older last use takes priority over id.
      final recent = pool(words, {
        'wxyz': [9],
        'tear-z': [1, 2],
        'rate-a': [1, 8],
        'east': [3, 4],
      });
      expect(
        ranked(recent, targets).indexOf('tear-z'),
        lessThan(ranked(recent, targets).indexOf('rate-a')),
      );
      expect(
        ranked(
          pool(words.reversed.toList(), {
            'wxyz': [9],
            'tear-z': [1, 2],
            'rate-a': [1, 2],
            'east': [3, 4],
          }),
          targets.reversed.toList(),
        ),
        ranked(p, targets),
      );
    },
  );
  test(
    'bounded pools are monotonic and expose only capped support membership',
    () {
      final words = [
        const WordEntry('APPLE', 'Elma'),
        for (var i = 0; i < 20; i++)
          WordEntry('TREE', 'Test', id: 'support-$i'),
      ];
      // This policy-only fixture uses distinct IDs; catalogue uniqueness is tested elsewhere.
      final p = pool(
        words,
        {
          for (final w in words.skip(1)) w.id: [1],
        },
        excluded: ['support-0'],
      );
      final stages = boundedSupportPools(p, 1).toList();
      expect(stages.map((p) => p.supportIds.length), [0, 2, 4, 16, 19]);
      for (var i = 1; i < stages.length; i++) {
        expect(
          stages[i].entries.map((w) => w.id),
          containsAll(stages[i - 1].entries.map((w) => w.id)),
        );
      }
      for (final stage in stages) {
        expect(stage.entries.any((w) => w.id == 'support-0'), isFalse);
        expect(
          stage.supportIds.length,
          stage.entries.length - stage.targetIds.length,
        );
      }
      expect(stages[2].supportIds, hasLength(4));
      // Ten distinct answer IDs drawn from this pool can never include >4 support IDs.
      expect(
        stages[2].entries.where((w) => !stages[2].targetIds.contains(w.id)),
        hasLength(4),
      );
    },
  );
  test('undersized target starts at the minimum support size needed', () {
    final words = [
      const WordEntry('APPLE', 'Elma'),
      for (var i = 0; i < 12; i++) WordEntry('TREE', 'Test', id: 'support-$i'),
    ];
    final stages = boundedSupportPools(
      pool(words, {
        for (final w in words.skip(1)) w.id: [1],
      }),
      10,
    ).toList();
    expect(stages.first.entries, hasLength(10));
    expect(stages.first.supportIds, hasLength(9));
    expect(stages.every((p) => p.entries.length >= 10), isTrue);
  });
  test('target and two supports fail, four supports succeed without full tier', () {
    // Seven-letter targets cannot fit this five-cell grid. Top bridges connect
    // all three targets, but need five letters plus a clue. Compact lower-ranked
    // bridges fit once the four-word support cap is offered.
    final bank = WordCatalogue(
      version: 3,
      entries: const [
        WordEntry('ABCDEFG', 'Test'),
        WordEntry('GHIJKLM', 'Test'),
        WordEntry('MNOPQRS', 'Test'),
        WordEntry('AGMXY', 'Test'),
        WordEntry('BHNXY', 'Test'),
        WordEntry('AAAA', 'Test'),
        WordEntry('BBBB', 'Test'),
        WordEntry('ZZZZ', 'Test'),
        WordEntry('YYYY', 'Test'),
      ],
    );
    final support = bank.entries.where((w) => w.solution.length < 7).toList();
    final history = [
      for (var i = 0; i < support.length; i++)
        PuzzleHistoryEntry(
          puzzleIndex: i + 1,
          catalogVersion: 3,
          words: {support[i].id: support[i].solution},
        ),
    ];
    const config = PuzzleSequenceConfig(
      baseSeed: 1,
      cooldownPuzzles: 0,
      successfulSupportAttempts: 1,
      generation: PuzzleGenerationConfig(
        rows: 5,
        columns: 5,
        targetAnswerCount: 1,
        minAnswersPerDirection: 0,
        minCrossings: 0,
      ),
    );
    final result = PuzzleSequenceGenerator(
      bank,
      config,
    ).generateNext(puzzleIndex: history.length + 1, history: history);
    expect(result.isSuccess, isTrue, reason: result.failureReason);
    expect(result.attempts.map((a) => a.pool.supportIds.length), [0, 2, 4]);
    expect(result.attempts.map((a) => a.isSuccess), [false, false, true]);
    expect(
      result.finalAttempt!.selectedSupportCount,
      lessThanOrEqualTo(result.finalAttempt!.pool.supportIds.length),
    );
    final chosen = result.finalAttempt!;
    final withoutTargets = BalancingAttempt(
      GenerationPool(chosen.pool.entries, [0, 1]),
      chosen.generation,
      null,
    );
    final withTarget = BalancingAttempt(
      GenerationPool(chosen.pool.entries, [
        0,
        1,
      ], targetIds: chosen.generation!.puzzle!.answers.map((a) => a.id)),
      chosen.generation,
      null,
    );
    expect(compareSupportAttempts(withTarget, withoutTargets), greaterThan(0));
    expect(compareSupportAttempts(withTarget, withTarget), 0);
  });
}

class _Metrics implements PuzzleMetrics {
  const _Metrics({required this.columns, required this.qualityScore});
  final int columns;
  @override
  final int qualityScore;
  @override
  int get displayColumnCount => columns;
  @override
  int get leafAnswerCount => 2;
  @override
  int get crossingCount => 12;
  @override
  String get structuralSignature => '$columns:$qualityScore';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
