import 'package:arrowword/features/puzzle/content/word_catalogue.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/data/manual_puzzle.dart';
import 'package:arrowword/features/puzzle/data/word_catalogue_data.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_generator.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_metrics.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_validator.dart';
import 'package:arrowword/features/puzzle/generation/word_entry.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/inspect_content.dart' as stress;

void main() {
  final small = WordCatalogue(
    version: 1,
    entries: const [
      WordEntry('APPLE', 'Elma', id: 'fruit', tags: ['food']),
      WordEntry('PEAR', 'Armut', difficulty: WordDifficulty.medium),
      WordEntry('TREE', 'Ağaç'),
      WordEntry('RAIN', 'Yağmur', difficulty: WordDifficulty.hard),
    ],
  );
  PuzzleSequenceConfig config({
    int cooldown = 2,
    Set<WordDifficulty> allowed = const {
      WordDifficulty.easy,
      WordDifficulty.medium,
      WordDifficulty.hard,
    },
  }) => PuzzleSequenceConfig(
    baseSeed: prototypeBaseSeed,
    cooldownPuzzles: cooldown,
    usageBalancingEnabled: false,
    allowedDifficulties: allowed,
    generation: const PuzzleGenerationConfig(
      targetAnswerCount: 1,
      minAnswersPerDirection: 0,
      minCrossings: 0,
    ),
  );
  PuzzleHistoryEntry history(int index, String id, String word) =>
      PuzzleHistoryEntry(
        puzzleIndex: index,
        catalogVersion: 1,
        words: {id: word},
      );
  final h = [
    history(1, 'fruit', 'APPLE'),
    history(2, 'pear', 'PEAR'),
    history(3, 'tree', 'TREE'),
  ];
  EligiblePool pool(
    int index,
    List<PuzzleHistoryEntry> history, {
    PuzzleSequenceConfig? policy,
    WordCatalogue? c,
  }) => buildEligiblePool(
    catalogue: c ?? small,
    config: policy ?? config(),
    puzzleIndex: index,
    history: history,
  );
  List<String> ids(EligiblePool p) => p.entries.map((w) => w.id).toList();

  test('seed v1 known values are locked for indices 1, 2, 10', () {
    expect(derivePuzzleSeed(prototypeBaseSeed, 1), 3255270515);
    expect(derivePuzzleSeed(prototypeBaseSeed, 2), 3017514609);
    expect(derivePuzzleSeed(prototypeBaseSeed, 10), 3356167200);
    expect(derivePuzzleSeed(0, 1), 1364076727);
    expect(() => derivePuzzleSeed(0, 0), throwsArgumentError);
  });
  test(
    'split 32-bit seed multiplication agrees with exact BigInt reference',
    () {
      final mask = BigInt.from(0xffffffff);
      for (final base in [0, prototypeBaseSeed, 0xffffffff]) {
        for (final index in [1, 2, 10, 0xffffffff]) {
          var x = BigInt.from(base) ^ BigInt.from(index);
          x = ((x ^ (x >> 16)) * BigInt.from(0x85ebca6b)) & mask;
          x = ((x ^ (x >> 13)) * BigInt.from(0xc2b2ae35)) & mask;
          x = (x ^ (x >> 16)) & mask;
          expect(derivePuzzleSeed(base, index), x.toInt());
        }
      }
    },
  );
  test(
    'immediate and window history excluded; oldest returns after cooldown',
    () {
      expect(ids(pool(2, h.take(1).toList())), isNot(contains('fruit')));
      final at3 = pool(3, h.take(2).toList());
      expect(at3.excludedRecentIds, ['fruit', 'pear']);
      final at4 = pool(4, h);
      expect(at4.isSuccess, isTrue);
      expect(at4.excludedRecentIds, ['pear', 'tree']);
      expect(ids(at4), contains('fruit'));
    },
  );
  test(
    'history changes eligible words predictably, independent of input order',
    () {
      final first = pool(3, h.take(2).toList());
      final reordered = pool(
        3,
        h.take(2).toList().reversed.toList(),
        c: WordCatalogue(version: 1, entries: small.entries.reversed.toList()),
      );
      expect(ids(first), ids(reordered));
      expect(first.excludedRecentIds, reordered.excludedRecentIds);
      expect(ids(pool(2, [history(1, 'tree', 'TREE')])), contains('fruit'));
      expect(ids(pool(2, h.take(1).toList())), contains('tree'));
    },
  );
  test('difficulty and cooldown combine deterministically', () {
    final result = pool(
      2,
      h.take(1).toList(),
      policy: config(allowed: {WordDifficulty.easy}),
    );
    expect(ids(result), ['tree']);
    expect(result.excludedRecentIds, ['fruit']);
  });
  test(
    'strict shortage returns eligible count/exclusions, never relaxation',
    () {
      final result = pool(
        4,
        h,
        policy: config(
          cooldown: 3,
          allowed: {WordDifficulty.easy, WordDifficulty.medium},
        ),
      );
      expect(result.isSuccess, isFalse);
      expect(result.entries, isEmpty);
      expect(result.excludedRecentIds, ['fruit', 'pear', 'tree']);
      expect(
        result.failureReason,
        contains('Insufficient eligible vocabulary'),
      );
    },
  );
  test(
    'missing, duplicate, future and mismatched history is explicit failure',
    () {
      expect(pool(3, []).failureReason, contains('Missing'));
      expect(pool(2, [h.first, h.first]).failureReason, contains('duplicate'));
      expect(pool(2, h).failureReason, contains('earlier'));
      expect(
        pool(2, [history(1, 'fruit', 'PEAR')]).failureReason,
        contains('Invalid history'),
      );
      expect(
        pool(2, [
          PuzzleHistoryEntry(
            puzzleIndex: 1,
            catalogVersion: 2,
            words: {'fruit': 'APPLE'},
          ),
        ]).failureReason,
        contains('version'),
      );
    },
  );
  test('zero cooldown and invalid policies have explicit semantics', () {
    expect(ids(pool(4, [], policy: config(cooldown: 0))), [
      'fruit',
      'pear',
      'rain',
      'tree',
    ]);
    expect(pool(1, [], policy: config(cooldown: -1)).isSuccess, isFalse);
    expect(pool(1, [], policy: config(allowed: {})).isSuccess, isFalse);
    expect(const PuzzleSequenceConfig(baseSeed: 1).cooldownPuzzles, 5);
  });
  test('invalid catalogue and insufficient pool fail before grid search', () {
    final invalid = WordCatalogue(
      version: 1,
      entries: const [WordEntry('BAD!', '')],
    );
    final bad = PuzzleSequenceGenerator(
      invalid,
      prototypeSequenceConfig,
    ).generateNext(puzzleIndex: 1);
    expect(bad.generation, isNull);
    expect(bad.failureReason, contains('Invalid catalogue'));
    final shortage = PuzzleSequenceGenerator(
      small,
      prototypeSequenceConfig,
    ).generateNext(puzzleIndex: 1);
    expect(shortage.generation, isNull);
    expect(shortage.puzzleIndex, 1);
    expect(shortage.seed, 3255270515);
    expect(shortage.pool.entries, hasLength(4));
    expect(shortage.failureReason, contains('Insufficient eligible'));
  });
  test(
    'explicit content ids survive generator normalization and grid output',
    () {
      final result = const PuzzleGenerator().generate(
        wordBank: small.entries,
        seed: 1,
        config: config().generation,
      );
      expect(result.isSuccess, isTrue);
      final a = result.puzzle!.answers.single;
      expect(
        small.entries.singleWhere((w) => w.solution == a.solution).id,
        a.id,
      );
      final single = const PuzzleGenerator().generate(
        wordBank: const [WordEntry(' apple ', 'Elma', id: 'fruit-001')],
        seed: 1,
        config: config().generation,
      );
      expect(single.puzzle!.answers.single.id, 'fruit-001');
    },
  );

  test('v3 difficulty filters expose the real eligible catalogue', () {
    for (final allowed in [
      {WordDifficulty.easy},
      {WordDifficulty.easy, WordDifficulty.medium},
      WordDifficulty.values.toSet(),
    ]) {
      final p = buildEligiblePool(
        catalogue: prototypeCatalogue,
        config: PuzzleSequenceConfig(
          baseSeed: prototypeBaseSeed,
          allowedDifficulties: allowed,
        ),
        puzzleIndex: 1,
      );
      expect(p.isSuccess, isTrue);
      expect(p.entries.every((w) => allowed.contains(w.difficulty)), isTrue);
      expect(
        p.entries.length,
        allowed.length == 1
            ? 210
            : allowed.length == 2
            ? 285
            : 300,
      );
    }
  });
  test('cooldown five permits first reuse only at index seven', () {
    final words = prototypeCatalogue.entries.take(50).toList();
    final recent = List.generate(
      5,
      (i) => PuzzleHistoryEntry(
        puzzleIndex: i + 1,
        catalogVersion: 3,
        words: {for (final w in words.skip(i * 10).take(10)) w.id: w.solution},
      ),
    );
    final six = buildEligiblePool(
      catalogue: prototypeCatalogue,
      config: prototypeSequenceConfig,
      puzzleIndex: 6,
      history: recent,
    );
    expect(six.entries, hasLength(250));
    expect(
      six.entries.any((w) => words.take(10).any((old) => old.id == w.id)),
      isFalse,
    );
    final seven = buildEligiblePool(
      catalogue: prototypeCatalogue,
      config: prototypeSequenceConfig,
      puzzleIndex: 7,
      history: [
        ...recent,
        PuzzleHistoryEntry(
          puzzleIndex: 6,
          catalogVersion: 3,
          words: {
            for (final w in prototypeCatalogue.entries.skip(50).take(10))
              w.id: w.solution,
          },
        ),
      ],
    );
    expect(seven.entries, hasLength(250));
    expect(
      seven.entries.map((w) => w.id),
      containsAll(words.take(10).map((w) => w.id)),
    );
  });

  group('seven-puzzle v3 sequence', () {
    late PuzzleSequenceResult first, second;
    setUpAll(() {
      first = PuzzleSequenceGenerator(
        prototypeCatalogue,
        prototypeSequenceConfig,
      ).generateRange(count: 7);
      second = PuzzleSequenceGenerator(
        WordCatalogue(version: 3, entries: catalogueWords.reversed.toList()),
        prototypeSequenceConfig,
      ).generateRange(count: 7);
    });
    test('full structure repeats exactly despite catalogue reordering', () {
      expect(first.isSuccess, isTrue, reason: first.failure?.failureReason);
      expect(second.isSuccess, isTrue, reason: second.failure?.failureReason);
      expect(first.puzzles, hasLength(7));
      for (var i = 0; i < 7; i++) {
        final a = first.puzzles[i], b = second.puzzles[i];
        expect(a.puzzleIndex, b.puzzleIndex);
        expect(a.catalogVersion, b.catalogVersion);
        expect(a.generationPoolCount, b.generationPoolCount);
        expect(a.minimumEligibleUsage, b.minimumEligibleUsage);
        expect(a.maximumIncludedUsage, b.maximumIncludedUsage);
        expect(
          a.attempts.map((x) => x.pool.includedUsageTiers),
          b.attempts.map((x) => x.pool.includedUsageTiers),
        );
        expect(
          a.attempts.map((x) => x.pool.entries.map((w) => w.id)),
          b.attempts.map((x) => x.pool.entries.map((w) => w.id)),
        );
        expect(a.totalCandidateChecks, b.totalCandidateChecks);
        expect(a.seed, b.seed);
        expect(a.puzzle!.id, b.puzzle!.id);
        expect(
          puzzleStructuralSignature(a.puzzle!),
          puzzleStructuralSignature(b.puzzle!),
        );
        expect(
          a.pool.entries.map((w) => w.id),
          b.pool.entries.map((w) => w.id),
        );
      }
      expect(first.puzzles[0].seed, isNot(first.puzzles[1].seed));
      expect(
        puzzleStructuralSignature(first.puzzles[0].puzzle!),
        isNot(puzzleStructuralSignature(first.puzzles[1].puzzle!)),
      );
    });
    test('stress gate accepts every valid sequence result', () {
      for (var i = 0; i < first.puzzles.length; i++) {
        expect(
          () => stress.verifyStressPuzzle(
            first.puzzles[i],
            first.puzzles.take(i).toList(),
          ),
          returnsNormally,
        );
      }
    });
    test('stress gate throws on generation failure, not just a warning', () {
      final r = first.puzzles.first;
      final failure = SequencePuzzleResult(
        puzzleIndex: 1,
        seed: r.seed,
        catalogVersion: 3,
        pool: r.pool,
        failureReason: 'Search budget exhausted',
      );
      expect(() => stress.verifyStressPuzzle(failure, []), throwsStateError);
    });
    test('stress gate rejects historical phantom-run fixture', () {
      final r = first.puzzles.first;
      final invalid = SequencePuzzleResult(
        puzzleIndex: 1,
        seed: r.seed,
        catalogVersion: 3,
        pool: r.pool,
        puzzle: manualPuzzle,
      );
      expect(() => stress.verifyStressPuzzle(invalid, []), throwsStateError);
    });
    test('stress gate rejects premature reuse but allows distance six', () {
      final r = first.puzzles.first;
      SequencePuzzleResult reuse(int index) => SequencePuzzleResult(
        puzzleIndex: index,
        seed: r.seed,
        catalogVersion: 3,
        pool: r.pool,
        puzzle: r.puzzle,
      );
      expect(() => stress.verifyStressPuzzle(reuse(6), [r]), throwsStateError);
      expect(() => stress.verifyStressPuzzle(reuse(7), [r]), returnsNormally);
    });
    test(
      'all seven enforce strict validity, unique answers, bounds and minima',
      () {
        for (final result in first.puzzles) {
          final p = result.puzzle!, m = result.generation!.metrics!;
          final v = const PuzzleValidator().validate(
            p,
            expectedAnswerCount: 10,
          );
          expect(v.errors, isEmpty);
          expect(v.phantomAdjacencyCount, 0);
          expect(v.unexplainedRunCount, 0);
          expect(p.answers, hasLength(10));
          expect(p.isAnswerGraphConnected, isTrue);
          expect(p.answers.map((a) => a.id).toSet(), hasLength(10));
          expect(p.answers.map((a) => a.solution).toSet(), hasLength(10));
          expect(
            p.meaningfulPositions.every(p.displayBounds.containsLogical),
            isTrue,
          );
          expect(m.horizontalCount, greaterThanOrEqualTo(4));
          expect(m.verticalCount, greaterThanOrEqualTo(4));
          expect(m.crossingCount, greaterThanOrEqualTo(9));
          expect(
            p.answers.any((a) => result.pool.excludedRecentIds.contains(a.id)),
            isFalse,
          );
        }
      },
    );
    test(
      'repeat distance is strictly greater than cooldown for ids and solutions',
      () {
        final analysis = SequenceRepeatAnalysis(first.puzzles);
        if (analysis.minimumDistance != null) {
          expect(analysis.minimumDistance, greaterThanOrEqualTo(6));
        }
        expect(prototypeSequenceCooldown, 5);
        for (final distance
            in analysis.minimumDistanceByWord.values.whereType<int>()) {
          expect(distance, greaterThan(prototypeSequenceCooldown));
        }
        final last = <String, int>{};
        for (final p in first.puzzles) {
          for (final a in p.puzzle!.answers) {
            if (last.containsKey(a.solution)) {
              expect(
                p.puzzleIndex - last[a.solution]!,
                greaterThan(prototypeSequenceCooldown),
              );
            }
            last[a.solution] = p.puzzleIndex;
          }
        }
      },
    );
    test('bounded search failure stays explicit with full v3 pool', () {
      final result = PuzzleSequenceGenerator(
        prototypeCatalogue,
        const PuzzleSequenceConfig(
          baseSeed: prototypeBaseSeed,
          generation: PuzzleGenerationConfig(maxSearchNodes: 1),
        ),
      ).generateNext(puzzleIndex: 1);
      expect(result.isSuccess, isFalse);
      expect(result.puzzle, isNull);
      expect(result.pool.entries, hasLength(300));
      expect(result.generation, isNotNull);
      expect(result.failureReason, contains(result.generation!.failureReason!));
    });
    test(
      'range access replays missing prefix, yielding identical puzzle indices',
      () {
        final range = PuzzleSequenceGenerator(
          prototypeCatalogue,
          prototypeSequenceConfig,
        ).generateRange(startIndex: 2, count: 1);
        expect(range.isSuccess, isTrue);
        expect(range.puzzles.single.puzzleIndex, 2);
        expect(
          puzzleStructuralSignature(range.puzzles.single.puzzle!),
          puzzleStructuralSignature(first.puzzles[1].puzzle!),
        );
      },
    );
  });
}
