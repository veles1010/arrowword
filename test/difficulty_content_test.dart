import 'package:arrowword/app/development_puzzle.dart';
import 'package:arrowword/app/puzzle_track.dart';
import 'package:arrowword/app/puzzle_progress_store.dart';
import 'package:arrowword/features/puzzle/content/track_catalogue_audit.dart';
import 'package:arrowword/features/puzzle/content/word_catalogue.dart';
import 'package:arrowword/features/puzzle/data/difficulty_puzzles.dart';
import 'package:arrowword/features/puzzle/data/prototype_puzzle.dart';
import 'package:arrowword/features/puzzle/domain/puzzle_difficulty.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_metrics.dart';
import 'package:arrowword/features/puzzle/generation/puzzle_validator.dart';
import 'package:arrowword/features/puzzle/generation/word_entry.dart';
import 'package:arrowword/features/puzzle/sequence/puzzle_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/inspect_tracks.dart' as inspection;

// Locked v1 content structure after independent catalogue validation.
const firstSignatures = <String, String>{
  'medium': 'medium-agree:AGREE:1:3,3:2,3|medium-arch:ARCH:0:4,5:4,4|medium-bronze:BRONZE:0:1,3:1,2|medium-heron:HERON:0:7,2:7,1|medium-humble:HUMBLE:1:4,8:3,8|medium-iron:IRON:0:5,2:5,1|medium-jade:JADE:0:9,5:9,4|medium-mango:MANGO:1:3,5:2,5|medium-palm:PALM:0:3,2:3,1|medium-zinc:ZINC:1:1,7:0,7',
  'hard': 'hard-emblem:EMBLEM:0:2,2:2,1|hard-flit:FLIT:0:8,1:8,0|hard-levy:LEVY:0:9,5:9,4|hard-muse:MUSE:1:2,3:1,3|hard-myth:MYTH:1:2,7:1,7|hard-nest:NEST:1:5,4:4,4|hard-snag:SNAG:0:7,4:7,3|hard-trace:TRACE:1:5,6:4,6|hard-zeal:ZEAL:1:5,2:4,2|hard-zenith:ZENITH:0:5,2:5,1',
};

void main() {
  final cases = {
    PuzzleDifficulty.medium: (
      mediumCatalogue,
      mediumSequenceConfig,
      [553741480, 2558657560, 1892685967, 3481664712],
    ),
    PuzzleDifficulty.hard: (
      hardCatalogue,
      hardSequenceConfig,
      [1117217477, 1469360122, 963478886, 1938332644],
    ),
  };
  final first = <PuzzleDifficulty, SequencePuzzleResult>{};
  setUpAll(() {
    for (final entry in cases.entries) {
      first[entry.key] = PuzzleSequenceGenerator(
        entry.value.$1,
        entry.value.$2,
      ).generateNext(puzzleIndex: 1);
    }
  });

  for (final entry in cases.entries) {
    final difficulty = entry.key,
        catalogue = entry.value.$1,
        config = entry.value.$2;
    test(
      '${difficulty.id} has 300 valid new answers, fair clue shape and partners',
      () {
        final other = difficulty == PuzzleDifficulty.medium
            ? hardCatalogue
            : mediumCatalogue;
        final audit = TrackCatalogueAudit(
          catalogue,
          forbidden: [...prototypeCatalogue.entries, ...other.entries],
        );
        expect(catalogue.version, 1);
        expect(catalogue.entries, hasLength(300));
        expect(
          catalogue.entries.map((w) => w.solution).toSet(),
          hasLength(300),
        );
        expect(catalogue.isValid, isTrue, reason: '${catalogue.issues}');
        expect(audit.issues, isEmpty);
        expect(audit.nearDuplicateClues, isEmpty);
        expect(audit.minimumPartners, greaterThanOrEqualTo(100));
        for (final word in catalogue.entries) {
          expect(word.solution, matches(r'^[A-Z]{4,7}$'));
          expect(word.id, '${difficulty.id}-${word.solution.toLowerCase()}');
          expect(word.turkishClue.trim(), isNotEmpty);
          expect(word.turkishClue.split(' ').length, greaterThanOrEqualTo(2));
          expect(audit.positionOpportunities[word.id], greaterThan(100));
        }
      },
    );
    for (var offset = 0; offset < 4; offset++) {
      final index = [1, 2, 3, 10][offset];
      test('${difficulty.id} seed $index is a v1 compatibility lock', () {
        expect(
          derivePuzzleSeed(config.baseSeed, index),
          entry.value.$3[offset],
        );
      });
    }
    test(
      '${difficulty.id} Puzzle 1 deterministic ID/signature and strict validity',
      () {
        final original = first[difficulty]!;
        final repeated = PuzzleSequenceGenerator(
          catalogue,
          config,
        ).generateNext(puzzleIndex: 1);
        expect(original.isSuccess, isTrue, reason: original.failureReason);
        expect(repeated.isSuccess, isTrue, reason: repeated.failureReason);
        expect(original.puzzle!.id, 'generated-${difficulty.id}-v1-000001');
        expect(
          puzzleStructuralSignature(original.puzzle!),
          firstSignatures[difficulty.id],
        );
        expect(
          puzzleStructuralSignature(repeated.puzzle!),
          puzzleStructuralSignature(original.puzzle!),
        );
        final v = const PuzzleValidator().validate(
          original.puzzle!,
          expectedAnswerCount: 10,
        );
        expect(v.errors, isEmpty);
        expect(v.phantomAdjacencyCount, 0);
        expect(v.unexplainedRunCount, 0);
        expect(original.puzzle!.isAnswerGraphConnected, isTrue);
      },
    );
    test(
      '${difficulty.id} rejects the other track history before generation',
      () {
        final other = difficulty == PuzzleDifficulty.medium
            ? PuzzleDifficulty.hard
            : PuzzleDifficulty.medium;
        final result = PuzzleSequenceGenerator(
          catalogue,
          config,
        ).generateNext(puzzleIndex: 2, history: [first[other]!.toHistory()]);
        expect(result.isSuccess, isFalse);
        expect(result.failureReason, isNotNull);
      },
    );
    test(
      '${difficulty.id} uses unchanged search, balance, cooldown and budgets',
      () {
        final easy = prototypeSequenceConfig;
        expect(config.cooldownPuzzles, easy.cooldownPuzzles);
        expect(config.usageBalancingEnabled, easy.usageBalancingEnabled);
        expect(config.boundedSupportEnabled, easy.boundedSupportEnabled);
        expect(
          config.successfulSupportAttempts,
          easy.successfulSupportAttempts,
        );
        final g = config.generation, e = easy.generation;
        expect(
          [
            g.rows,
            g.columns,
            g.targetAnswerCount,
            g.minAnswersPerDirection,
            g.minCrossings,
            g.maxSearchNodes,
            g.maxBacktracks,
            g.maxCandidateChecks,
            g.maxCandidatesPerNode,
            g.maxNodesPerAnchor,
          ],
          [
            e.rows,
            e.columns,
            e.targetAnswerCount,
            e.minAnswersPerDirection,
            e.minCrossings,
            e.maxSearchNodes,
            e.maxBacktracks,
            e.maxCandidateChecks,
            e.maxCandidatesPerNode,
            e.maxNodesPerAnchor,
          ],
        );
      },
    );
    test('${difficulty.id} 30-puzzle strict-valid independent balanced sequence', () {
      final report = inspection.inspectTrack(
        difficulty.id,
        PuzzleSequenceGenerator(catalogue, config),
      );
      expect(report['count'], 30);
      expect(report['strictValid'], isTrue);
      expect(report['phantomAdjacencies'], 0);
      expect(report['unexplainedRuns'], 0);
      expect(report['cooldownViolations'], 0);
      final spacing = report['repeatDistance'] as Map;
      expect(spacing['min'], greaterThanOrEqualTo(6));
      final puzzles = report['puzzles'] as List<Map<String, Object>>;
      final lengths = report['lengthCoverage'] as Map;
      expect(
        lengths.values.fold<int>(
          0,
          (sum, row) => sum + ((row as Map)['unique'] as int),
        ),
        report['unique'],
      );
      expect(
        lengths.values.fold<int>(
          0,
          (sum, row) => sum + ((row as Map)['selections'] as int),
        ),
        300,
      );
      for (final puzzle in puzzles) {
        expect(
          puzzle['id'],
          'generated-${difficulty.id}-v1-${(puzzle['index'] as int).toString().padLeft(6, '0')}',
        );
        expect(puzzle['rows'] as int, lessThanOrEqualTo(10));
        expect(puzzle['columns'] as int, lessThanOrEqualTo(10));
        expect(puzzle['leaves'] as int, lessThanOrEqualTo(3));
      }
    }, timeout: const Timeout(Duration(minutes: 4)));

    test(
      '${difficulty.id} real provider/dev launch cannot mutate player stores',
      () async {
        final store = MemoryPuzzleProgressStore('normal player bytes');
        final track = PuzzleTrack(
          configuration: PuzzleTrackConfiguration.forDifficulty(difficulty),
          store: store,
        );
        expect(track.isAvailable, isTrue);
        final session = await track.open(developmentIndex: 1);
        addTearDown(session.dispose);
        expect(session.difficulty, difficulty);
        expect(
          session.current.puzzle!.id,
          'generated-${difficulty.id}-v1-000001',
        );
        expect(session.store, isNull);
        session.updateLetters({
          session.current.puzzle!.answers.first.start: 'Z',
        });
        await session.flush;
        expect(store.record, 'normal player bytes');
        expect(store.writes, 0);
      },
    );
    test(
      '${difficulty.id} schema-5 restore is deterministic in its isolated namespace',
      () async {
        final store = MemoryPuzzleProgressStore();
        final session = await PuzzleTrack(
          configuration: PuzzleTrackConfiguration.forDifficulty(difficulty),
          store: store,
        ).open();
        addTearDown(session.dispose);
        final cell = session.current.puzzle!.answers.first.start;
        session.updateAttemptProgress(
          {cell: 'Z'},
          {},
          const Duration(seconds: 19),
          2,
        );
        await session.flush;
        expect(PuzzleProgress.decode(store.record!).schemaVersion, 5);
        final restored = await PuzzleTrack(
          configuration: PuzzleTrackConfiguration.forDifficulty(difficulty),
          store: store,
        ).open();
        addTearDown(restored.dispose);
        expect(restored.current.puzzle!.id, session.current.puzzle!.id);
        expect(
          puzzleStructuralSignature(restored.current.puzzle!),
          puzzleStructuralSignature(session.current.puzzle!),
        );
        expect(restored.letters, {cell: 'Z'});
        expect(restored.elapsed, const Duration(seconds: 19));
        expect(restored.wrongChecks, 2);
      },
    );
  }

  test('catalogue gate catches leakage, duplicate clues, overlap and isolated words', () {
    final duplicate = WordCatalogue(
      version: 1,
      entries: [
        const WordEntry('SHORE', 'SHORE kıyısı'),
        const WordEntry('CABLE', 'SHORE kıyısı'),
      ],
    );
    final audit = TrackCatalogueAudit(
      duplicate,
      expectedCount: 2,
      minimumPartners: 0,
      forbidden: [const WordEntry('SHORE', 'başka ipucu')],
    );
    expect(audit.isValid, isFalse);
    expect(audit.issues.join(' '), contains('Duplicate clue'));
    expect(audit.issues.join(' '), contains('Answer leakage'));
    expect(audit.issues.join(' '), contains('Overlapping answer'));
    final isolated = TrackCatalogueAudit(
      WordCatalogue(
        version: 1,
        entries: [
          const WordEntry('ABCD', 'Birinci test sözcüğü'),
          const WordEntry('WXYZ', 'İkinci test sözcüğü'),
        ],
      ),
      expectedCount: 2,
      minimumPartners: 1,
    );
    expect(isolated.isValid, isFalse);
    expect(crossingPositionOpportunities('LEVEL', 'LEVER'), 7);
  });
  test('word metadata remains separate: Medium 300 medium; Hard 294 hard / 6 medium', () {
    expect(mediumCatalogue.health.difficultyCounts[WordDifficulty.medium], 300);
    expect(hardCatalogue.health.difficultyCounts[WordDifficulty.hard], 294);
    expect(hardCatalogue.health.difficultyCounts[WordDifficulty.medium], 6);
  });
  test(
    'audited Medium senses distinguish columns, stairs and flame torches',
    () {
      String clue(String answer) => mediumCatalogue.entries
          .singleWhere((w) => w.solution == answer)
          .turkishClue;
      // Content fixtures, not a claim that regex can certify semantic fairness.
      expect(clue('COLUMN'), contains('Gazetede'));
      expect(clue('PILLAR'), contains('yapıyı destekleyen'));
      expect(clue('STAIR'), contains('tek basamak'));
      expect(clue('TORCH'), contains('alev'));
    },
  );
  test('audited Hard senses separate source citation from exact quotation', () {
    String clue(String answer) => hardCatalogue.entries
        .singleWhere((w) => w.solution == answer)
        .turkishClue;
    expect(clue('CITE'), contains('kaynağı'));
    expect(clue('QUOTE'), contains('değiştirmeden'));
    expect(clue('VERSE'), isNot(contains('ölçülü')));
    expect(clue('STEM'), contains('doğması'));
    expect(clue('RAPT'), contains('dikkat kesilmiş'));
  });
  test(
    'development selection defaults Easy and ignores difficulty without index',
    () {
      expect(developmentPuzzleDifficulty(), PuzzleDifficulty.easy);
      expect(developmentPuzzleDifficulty('medium'), PuzzleDifficulty.medium);
      expect(developmentPuzzleDifficulty('hard'), PuzzleDifficulty.hard);
      expect(
        developmentTrackConfiguration(null, 'hard'),
        same(PuzzleTrackConfiguration.easy),
      );
      expect(
        developmentTrackConfiguration(null, 'invalid'),
        same(PuzzleTrackConfiguration.easy),
      );
      expect(
        developmentTrackConfiguration(1),
        same(PuzzleTrackConfiguration.easy),
      );
      expect(
        developmentTrackConfiguration(1, 'medium'),
        same(PuzzleTrackConfiguration.medium),
      );
      expect(() => developmentPuzzleDifficulty('Orta'), throwsArgumentError);
    },
  );
}
