import 'package:arrowword/features/puzzle/content/word_catalogue.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/data/prototype_word_bank.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_generator.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_metrics.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_validator.dart';
import 'package:arrowword/features/puzzle/generation/word_entry.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

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

  group('ten-puzzle sequence', () {
    late PuzzleSequenceResult first, second;
    setUpAll(() {
      first = PuzzleSequenceGenerator(
        prototypeCatalogue,
        prototypeSequenceConfig,
      ).generateRange();
      second = PuzzleSequenceGenerator(
        WordCatalogue(version: 1, entries: prototypeWordBank.reversed.toList()),
        prototypeSequenceConfig,
      ).generateRange();
    });
    test('full structure repeats exactly despite catalogue reordering', () {
      expect(first.isSuccess, isTrue, reason: first.failure?.failureReason);
      expect(second.isSuccess, isTrue, reason: second.failure?.failureReason);
      expect(first.puzzles, hasLength(10));
      for (var i = 0; i < 10; i++) {
        final a = first.puzzles[i], b = second.puzzles[i];
        expect(a.puzzleIndex, b.puzzleIndex);
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
    test(
      'all ten enforce strict validity, unique answers, bounds and minima',
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
        expect(analysis.minimumDistance, 4);
        expect(analysis.indicesByWord.length, 54);
        expect(analysis.repeatedWordCount, 41);
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
    test(
      'strict cooldowns 5 and 4 fail transparently at index 5, not relaxed',
      () {
        for (final k in [5, 4]) {
          final result =
              PuzzleSequenceGenerator(
                prototypeCatalogue,
                PuzzleSequenceConfig(
                  baseSeed: prototypeBaseSeed,
                  cooldownPuzzles: k,
                ),
              ).generateNext(
                puzzleIndex: 5,
                history: first.puzzles
                    .take(4)
                    .map((p) => p.toHistory())
                    .toList(),
              );
          expect(result.isSuccess, isFalse);
          expect(result.puzzle, isNull);
          expect(result.puzzleIndex, 5);
          expect(result.seed, 212570333);
          expect(result.pool.entries, hasLength(20));
          expect(result.pool.excludedRecentIds, hasLength(40));
          expect(result.generation, isNotNull);
          expect(
            result.failureReason,
            contains(result.generation!.failureReason!),
          );
        }
      },
    );
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
