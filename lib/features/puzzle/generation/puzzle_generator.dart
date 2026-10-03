import 'dart:math';

import '../domain/puzzle.dart';
import 'puzzle_metrics.dart';
import 'puzzle_validator.dart';
import 'src/search_state.dart';
import 'word_entry.dart';

class PuzzleGenerationConfig {
  const PuzzleGenerationConfig({
    this.rows = 10,
    this.columns = 10,
    this.targetAnswerCount = 10,
    this.minAnswersPerDirection = 4,
    this.minCrossings = 9,
    this.maxSearchNodes = 10000,
    this.maxBacktracks = 10000,
    this.maxCandidateChecks = 4000000,
    this.maxCandidatesPerNode = 40,
    this.maxNodesPerAnchor = 200,
  });

  final int rows,
      columns,
      targetAnswerCount,
      minAnswersPerDirection,
      minCrossings;
  final int maxSearchNodes,
      maxBacktracks,
      maxCandidateChecks,
      maxCandidatesPerNode;
  final int maxNodesPerAnchor;
}

class PuzzleGenerationResult {
  PuzzleGenerationResult._({
    required this.puzzle,
    required this.failureReason,
    required this.searchNodes,
    required this.backtracks,
    required this.candidateChecks,
    this.completeSolutionsFound = 0,
    this.anchorsTried = 0,
    this.firstCompleteScore,
    this.candidatePlacementsGenerated = 0,
    this.candidatesRejected = 0,
    this.legalCandidates = 0,
    this.visitedStateHits = 0,
    this.visitedStateMisses = 0,
    this.duplicateCandidates = 0,
    this.boundsRejected = 0,
    this.occupiedCrossingRejected = 0,
    this.spanRejected = 0,
  }) : metrics = puzzle == null ? null : PuzzleMetrics(puzzle);

  final Puzzle? puzzle;
  final String? failureReason;
  final PuzzleMetrics? metrics;
  final int searchNodes, backtracks, candidateChecks;
  final int completeSolutionsFound, anchorsTried;
  final int? firstCompleteScore;
  final int candidatePlacementsGenerated, candidatesRejected, legalCandidates;
  final int visitedStateHits, visitedStateMisses;
  final int duplicateCandidates, boundsRejected, occupiedCrossingRejected;
  final int spanRejected;
  int? get bestCompleteScore => metrics?.qualityScore;
  int? get bestScore => bestCompleteScore;
  bool get isSuccess => puzzle != null;
}

class PuzzleGenerator {
  const PuzzleGenerator();

  PuzzleGenerationResult generate({
    required List<WordEntry> wordBank,
    required int seed,
    PuzzleGenerationConfig config = const PuzzleGenerationConfig(),
  }) {
    PuzzleGenerationResult fail(String reason) => PuzzleGenerationResult._(
      puzzle: null,
      failureReason: reason,
      searchNodes: 0,
      backtracks: 0,
      candidateChecks: 0,
    );
    if (config.rows <= 0 ||
        config.columns <= 0 ||
        config.targetAnswerCount <= 0 ||
        config.minAnswersPerDirection < 0 ||
        config.minCrossings < 0 ||
        config.minAnswersPerDirection * 2 > config.targetAnswerCount ||
        config.maxSearchNodes <= 0 ||
        config.maxBacktracks <= 0 ||
        config.maxCandidateChecks <= 0 ||
        config.maxCandidatesPerNode <= 0 ||
        config.maxNodesPerAnchor <= 0) {
      return fail('Invalid generator configuration.');
    }
    final words = <WordEntry>[];
    final seen = <String>{};
    final ids = <String>{};
    for (final entry in wordBank) {
      final solution = entry.solution.trim().toUpperCase();
      if (!RegExp(r'^[A-Z]{2,}$').hasMatch(solution) ||
          entry.turkishClue.trim().isEmpty) {
        return fail('Invalid word-bank entry: ${entry.solution}.');
      }
      if (!seen.add(solution)) {
        return fail('Duplicate normalized solution: $solution.');
      }
      if (entry.id.trim().isEmpty || !ids.add(entry.id)) {
        return fail('Duplicate or empty content id: ${entry.id}.');
      }
      words.add(entry.normalized());
    }
    words.removeWhere(
      (word) => word.solution.length >= max(config.rows, config.columns),
    );
    if (words.length < config.targetAnswerCount) {
      return fail('Not enough fitting unique words.');
    }
    words.sort((a, b) => a.solution.compareTo(b.solution));
    return _Search(words, seed, config).run();
  }
}

class _Candidate {
  const _Candidate(this.answer, this.score, this.tieBreak);
  final SearchPlacement answer;
  final int score;
  final double tieBreak;
}

class _Search {
  _Search(this.words, this.seed, this.config) : random = Random(seed) {
    catalog = SearchCatalog(words, config.rows, config.columns);
    state = SearchState(catalog);
  }
  late final SearchCatalog catalog;
  late final SearchState state;
  final work = SearchWork();
  final List<WordEntry> words;
  final int seed;
  final PuzzleGenerationConfig config;
  final Random random;
  int nodes = 0, backtracks = 0, visitedHits = 0, visitedMisses = 0;
  int completeSolutions = 0, anchorsTried = 0;
  int? firstCompleteScore;
  Puzzle? bestPuzzle;
  PuzzleMetrics? bestMetrics;
  final Set<String> completeSignatures = {};
  final Set<String> visitedStates = {};
  int anchorStartNode = 0;
  bool get anchorExhausted =>
      nodes - anchorStartNode >= config.maxNodesPerAnchor;
  bool get exhausted =>
      nodes >= config.maxSearchNodes ||
      backtracks >= config.maxBacktracks ||
      work.candidateChecks >= config.maxCandidateChecks;

  Puzzle _puzzle(List<PuzzleAnswer> answers) => Puzzle(
    id: 'generated-$seed',
    label: 'Deneme Bulmacası',
    rowCount: config.rows,
    columnCount: config.columns,
    answers: answers,
  );

  PuzzleGenerationResult run() {
    final anchors = <SearchPlacement>[];
    for (var word = 0; word < words.length; word++) {
      for (final direction in AnswerDirection.values) {
        final horizontal = direction == AnswerDirection.right;
        final axis = horizontal ? config.columns : config.rows;
        if (words[word].solution.length >= axis) continue;
        final start = (axis - words[word].solution.length + 1) ~/ 2;
        anchors.add(
          catalog.placement(
            word,
            horizontal ? 1 : 2,
            horizontal ? config.rows ~/ 2 : start,
            horizontal ? start : config.columns ~/ 2,
          )!,
        );
      }
    }
    anchors.shuffle(random);
    for (final anchor in anchors) {
      if (exhausted) break;
      anchorStartNode = nodes;
      anchorsTried++;
      state.place(anchor);
      _visit();
      state.unplace();
    }
    return PuzzleGenerationResult._(
      puzzle: bestPuzzle,
      failureReason: bestPuzzle != null
          ? null
          : exhausted
          ? 'Search budget exhausted without a valid complete board.'
          : 'No complete board found within the candidate search limits.',
      searchNodes: nodes,
      backtracks: backtracks,
      candidateChecks: work.candidateChecks,
      completeSolutionsFound: completeSolutions,
      anchorsTried: anchorsTried,
      firstCompleteScore: firstCompleteScore,
      candidatePlacementsGenerated: work.candidatePlacementsGenerated,
      candidatesRejected: work.candidatesRejected,
      legalCandidates: work.legalCandidates,
      duplicateCandidates: work.duplicateCandidates,
      boundsRejected: work.boundsRejected,
      occupiedCrossingRejected: work.occupiedCrossingRejected,
      spanRejected: work.spanRejected,
      visitedStateHits: visitedHits,
      visitedStateMisses: visitedMisses,
    );
  }

  void _visit() {
    if (exhausted || anchorExhausted) return;
    nodes++;
    // Different insertion orders can reach the same partial board. Expanding
    // it once leaves more of the finite check budget for different structures.
    if (!visitedStates.add(state.key)) {
      visitedHits++;
      return;
    }
    visitedMisses++;
    final right = state.rightCount;
    final down = state.downCount;
    final remaining = config.targetAnswerCount - state.placed.length;
    if (right + remaining < config.minAnswersPerDirection ||
        down + remaining < config.minAnswersPerDirection) {
      return;
    }
    if (remaining == 0) {
      if (state.crossingCount < config.minCrossings) return;
      _considerComplete(state.placed);
      // On a square logical grid, transposition preserves every placement
      // rule. Compare both orientations instead of letting an arbitrary anchor
      // direction choose landscape geometry for a portrait phone.
      if (config.rows == config.columns) {
        _considerComplete(
          state.placed
              .map(
                (p) => catalog.placement(
                  p.word,
                  3 - p.direction,
                  p.column,
                  p.row,
                )!,
              )
              .toList(),
        );
      }
      return;
    }
    final candidates = _candidates();
    for (final candidate in candidates.take(config.maxCandidatesPerNode)) {
      if (exhausted || anchorExhausted) break;
      state.place(candidate.answer);
      _visit();
      state.unplace();
      if (backtracks < config.maxBacktracks) backtracks++;
    }
  }

  void _considerComplete(List<SearchPlacement> placements) {
    // Deduplicate both orientations before even constructing a domain Puzzle.
    final tokens = placements.map((p) => p.id).toList()..sort();
    if (!completeSignatures.add(tokens.join(','))) return;
    final puzzle = _puzzle(placements.map(catalog.answer).toList());
    final validation = const PuzzleValidator().validate(
      puzzle,
      expectedAnswerCount: config.targetAnswerCount,
    );
    if (!validation.isValid ||
        puzzle.crossingPositions.length < config.minCrossings) {
      return;
    }
    final metrics = PuzzleMetrics(puzzle);
    completeSolutions++;
    firstCompleteScore ??= metrics.qualityScore;
    if (bestMetrics == null || metrics.compareQuality(bestMetrics!) > 0) {
      bestPuzzle = puzzle;
      bestMetrics = metrics;
    }
  }

  List<_Candidate> _candidates() {
    final candidates = <_Candidate>[];
    for (final legal in enumerateCandidates(
      state,
      work,
      config.maxCandidateChecks,
    )) {
      candidates.add(
        _Candidate(
          legal.placement,
          state.placementScore(legal.placement, legal.crossings),
          random.nextDouble(),
        ),
      );
    }
    candidates.sort((a, b) {
      final quality = b.score.compareTo(a.score);
      return quality != 0 ? quality : a.tieBreak.compareTo(b.tieBreak);
    });
    return candidates;
  }
}
