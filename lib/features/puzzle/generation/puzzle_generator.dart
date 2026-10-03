import 'dart:math';

import '../domain/puzzle.dart';
import 'puzzle_metrics.dart';
import 'puzzle_validator.dart';
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
  }) : metrics = puzzle == null ? null : PuzzleMetrics(puzzle);

  final Puzzle? puzzle;
  final String? failureReason;
  final PuzzleMetrics? metrics;
  final int searchNodes, backtracks, candidateChecks;
  final int completeSolutionsFound, anchorsTried;
  final int? firstCompleteScore;
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
    for (final entry in wordBank) {
      final solution = entry.solution.trim().toUpperCase();
      if (!RegExp(r'^[A-Z]{2,}$').hasMatch(solution) ||
          entry.turkishClue.trim().isEmpty) {
        return fail('Invalid word-bank entry: ${entry.solution}.');
      }
      if (!seen.add(solution)) {
        return fail('Duplicate normalized solution: $solution.');
      }
      words.add(WordEntry(solution, entry.turkishClue.trim()));
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
  final PuzzleAnswer answer;
  final int score;
  final double tieBreak;
}

class _Search {
  _Search(this.words, this.seed, this.config) : random = Random(seed);
  final List<WordEntry> words;
  final int seed;
  final PuzzleGenerationConfig config;
  final Random random;
  int nodes = 0, backtracks = 0, checks = 0;
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
      checks >= config.maxCandidateChecks;

  Puzzle _puzzle(List<PuzzleAnswer> answers) => Puzzle(
    id: 'generated-$seed',
    label: 'Deneme Bulmacası',
    rowCount: config.rows,
    columnCount: config.columns,
    answers: answers,
  );

  PuzzleGenerationResult run() {
    final anchors = <PuzzleAnswer>[];
    for (final word in words) {
      for (final direction in AnswerDirection.values) {
        final horizontal = direction == AnswerDirection.right;
        final axis = horizontal ? config.columns : config.rows;
        if (word.solution.length >= axis) continue;
        final start = (axis - word.solution.length + 1) ~/ 2;
        anchors.add(
          _answer(
            word,
            direction,
            horizontal ? config.rows ~/ 2 : start,
            horizontal ? start : config.columns ~/ 2,
          ),
        );
      }
    }
    anchors.shuffle(random);
    for (final anchor in anchors) {
      if (exhausted) break;
      anchorStartNode = nodes;
      anchorsTried++;
      _visit([anchor]);
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
      candidateChecks: checks,
      completeSolutionsFound: completeSolutions,
      anchorsTried: anchorsTried,
      firstCompleteScore: firstCompleteScore,
    );
  }

  void _visit(List<PuzzleAnswer> answers) {
    if (exhausted || anchorExhausted) return;
    nodes++;
    final puzzle = _puzzle(answers);
    // Different insertion orders can reach the same partial board. Expanding
    // it once leaves more of the finite check budget for different structures.
    if (!visitedStates.add(puzzleStructuralSignature(puzzle))) return;
    final right = answers
        .where((a) => a.direction == AnswerDirection.right)
        .length;
    final down = answers.length - right;
    final remaining = config.targetAnswerCount - answers.length;
    if (right + remaining < config.minAnswersPerDirection ||
        down + remaining < config.minAnswersPerDirection) {
      return;
    }
    if (remaining == 0) {
      _considerComplete(puzzle);
      // On a square logical grid, transposition preserves every placement
      // rule. Compare both orientations instead of letting an arbitrary anchor
      // direction choose landscape geometry for a portrait phone.
      if (config.rows == config.columns) {
        _considerComplete(
          _puzzle(
            puzzle.answers
                .map(
                  (answer) => PuzzleAnswer(
                    id: answer.id,
                    solution: answer.solution,
                    turkishClue: answer.turkishClue,
                    start: GridPosition(answer.start.column, answer.start.row),
                    cluePosition: GridPosition(
                      answer.cluePosition.column,
                      answer.cluePosition.row,
                    ),
                    direction: answer.direction == AnswerDirection.right
                        ? AnswerDirection.down
                        : AnswerDirection.right,
                  ),
                )
                .toList(),
          ),
        );
      }
      return;
    }
    final candidates = _candidates(puzzle);
    for (final candidate in candidates.take(config.maxCandidatesPerNode)) {
      if (exhausted || anchorExhausted) break;
      _visit([...answers, candidate.answer]);
      if (backtracks < config.maxBacktracks) backtracks++;
    }
  }

  void _considerComplete(Puzzle puzzle) {
    final validation = const PuzzleValidator().validate(
      puzzle,
      expectedAnswerCount: config.targetAnswerCount,
    );
    if (!validation.isValid ||
        puzzle.crossingPositions.length < config.minCrossings) {
      return;
    }
    final metrics = PuzzleMetrics(puzzle);
    if (!completeSignatures.add(metrics.structuralSignature)) return;
    completeSolutions++;
    firstCompleteScore ??= metrics.qualityScore;
    if (bestMetrics == null || metrics.compareQuality(bestMetrics!) > 0) {
      bestPuzzle = puzzle;
      bestMetrics = metrics;
    }
  }

  List<_Candidate> _candidates(Puzzle puzzle) {
    final board = _Board(puzzle);
    final used = puzzle.answers.map((a) => a.solution).toSet();
    final seen = <String>{};
    final candidates = <_Candidate>[];
    // Iteration is over sorted words and ordered answer/position lists, never
    // a hash-set traversal. Randomness only breaks ties between legal choices.
    for (final word in words.where((word) => !used.contains(word.solution))) {
      for (final existing in puzzle.answers) {
        final direction = existing.direction == AnswerDirection.right
            ? AnswerDirection.down
            : AnswerDirection.right;
        final positions = existing.positions;
        for (var oldIndex = 0; oldIndex < existing.length; oldIndex++) {
          for (var newIndex = 0; newIndex < word.solution.length; newIndex++) {
            if (existing.solution[oldIndex] != word.solution[newIndex]) {
              continue;
            }
            final cross = positions[oldIndex];
            final answer = _answer(
              word,
              direction,
              cross.row - (direction == AnswerDirection.down ? newIndex : 0),
              cross.column -
                  (direction == AnswerDirection.right ? newIndex : 0),
            );
            final signature =
                '${word.solution}:${direction.index}:${answer.start.row}:${answer.start.column}';
            if (!seen.add(signature)) continue;
            if (checks >= config.maxCandidateChecks) return candidates;
            checks++;
            if (!board.canPlace(answer)) continue;
            final next = _puzzle([...puzzle.answers, answer]);
            candidates.add(
              _Candidate(
                answer,
                _placementScore(next, answer),
                random.nextDouble(),
              ),
            );
          }
        }
      }
    }
    candidates.sort((a, b) {
      final quality = b.score.compareTo(a.score);
      return quality != 0 ? quality : a.tieBreak.compareTo(b.tieBreak);
    });
    return candidates;
  }
}

// A cheap search-order heuristic, separate from the full-board comparator.
// Extra crossings dominate; compact area, narrower bounds and direction
// balance steer exploration without evaluating leaf removal for each candidate.
int _placementScore(Puzzle puzzle, PuzzleAnswer added) {
  final crossings = added.positions
      .where((p) => puzzle.answersAt(p).length > 1)
      .length;
  final bounds = puzzle.displayBounds;
  final right = puzzle.answers
      .where((a) => a.direction == AnswerDirection.right)
      .length;
  return 400 * crossings -
      2 * bounds.rowCount * bounds.columnCount -
      12 * bounds.columnCount -
      8 * (2 * right - puzzle.answers.length).abs();
}

PuzzleAnswer _answer(
  WordEntry word,
  AnswerDirection direction,
  int row,
  int column,
) => PuzzleAnswer(
  id: word.solution.toLowerCase(),
  solution: word.solution,
  turkishClue: word.turkishClue,
  direction: direction,
  start: GridPosition(row, column),
  cluePosition: direction == AnswerDirection.right
      ? GridPosition(row, column - 1)
      : GridPosition(row - 1, column),
);

/// Incremental checks for a board whose existing placements are already legal.
class _Board {
  _Board(this.puzzle) {
    for (final answer in puzzle.answers) {
      clues.add(answer.cluePosition);
      final positions = answer.positions;
      for (var i = 0; i < positions.length; i++) {
        letters[positions[i]] = answer.solution[i];
        directions.putIfAbsent(positions[i], () => {}).add(answer.direction);
      }
    }
  }
  final Puzzle puzzle;
  final Map<GridPosition, String> letters = {};
  final Map<GridPosition, Set<AnswerDirection>> directions = {};
  final Set<GridPosition> clues = {};

  bool canPlace(PuzzleAnswer answer) {
    final clue = answer.cluePosition;
    final positions = answer.positions;
    if (!puzzle.contains(clue) ||
        clues.contains(clue) ||
        letters.containsKey(clue) ||
        !positions.every(puzzle.contains)) {
      return false;
    }
    final horizontal = answer.direction == AnswerDirection.right;
    final last = positions.last;
    final after = horizontal
        ? GridPosition(last.row, last.column + 1)
        : GridPosition(last.row + 1, last.column);
    if (letters.containsKey(after)) return false;
    var crossings = 0;
    for (var i = 0; i < positions.length; i++) {
      final position = positions[i];
      if (clues.contains(position)) return false;
      if (letters.containsKey(position)) {
        if (letters[position] != answer.solution[i] ||
            directions[position]!.contains(answer.direction)) {
          return false;
        }
        crossings++;
      } else {
        // A new non-crossing letter has no perpendicular owner, so either
        // perpendicular letter neighbor would create an unexplained run.
        final beforeSide = horizontal
            ? GridPosition(position.row - 1, position.column)
            : GridPosition(position.row, position.column - 1);
        final afterSide = horizontal
            ? GridPosition(position.row + 1, position.column)
            : GridPosition(position.row, position.column + 1);
        if (letters.containsKey(beforeSide) || letters.containsKey(afterSide)) {
          return false;
        }
      }
    }
    return crossings > 0;
  }
}
