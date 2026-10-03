import '../domain/puzzle.dart';

class LetterRun {
  LetterRun(this.direction, List<GridPosition> positions)
    : positions = List.unmodifiable(positions);

  final AnswerDirection direction;
  final List<GridPosition> positions;
}

class PuzzleValidation {
  PuzzleValidation({
    required List<String> errors,
    required this.phantomAdjacencyCount,
    required List<LetterRun> horizontalRuns,
    required List<LetterRun> verticalRuns,
    required this.unexplainedRunCount,
  }) : errors = List.unmodifiable(errors),
       horizontalRuns = List.unmodifiable(horizontalRuns),
       verticalRuns = List.unmodifiable(verticalRuns);

  final List<String> errors;
  final int phantomAdjacencyCount;
  final List<LetterRun> horizontalRuns;
  final List<LetterRun> verticalRuns;
  final int unexplainedRunCount;
  bool get hasValidLetterAdjacency => phantomAdjacencyCount == 0;
  bool get hasValidRuns => unexplainedRunCount == 0;
  bool get isValid => errors.isEmpty;
}

/// Strict generated-board validation. The historical manual fixture is not
/// required to satisfy this stronger visual contract.
class PuzzleValidator {
  const PuzzleValidator();

  PuzzleValidation validate(Puzzle puzzle, {int? expectedAnswerCount}) {
    final errors = <String>[];
    final owners = <GridPosition, List<PuzzleAnswer>>{};
    final letters = <GridPosition, String>{};
    final clues = <GridPosition>{};
    final ids = <String>{};
    final solutions = <String>{};
    if (puzzle.rowCount <= 0 || puzzle.columnCount <= 0) {
      errors.add('Grid dimensions must be positive.');
    }
    if (puzzle.answers.isEmpty) errors.add('No answers.');
    if (expectedAnswerCount != null &&
        puzzle.answers.length != expectedAnswerCount) {
      errors.add('Unexpected answer count.');
    }
    for (final answer in puzzle.answers) {
      if (!ids.add(answer.id) || answer.id.isEmpty) {
        errors.add('Duplicate or empty id.');
      }
      if (!solutions.add(answer.solution)) errors.add('Duplicate solution.');
      if (!RegExp(r'^[A-Z]{2,}$').hasMatch(answer.solution) ||
          answer.turkishClue.trim().isEmpty) {
        errors.add('Invalid solution or clue: ${answer.id}.');
      }
      final expectedClue = answer.direction == AnswerDirection.right
          ? GridPosition(answer.start.row, answer.start.column - 1)
          : GridPosition(answer.start.row - 1, answer.start.column);
      if (answer.cluePosition != expectedClue) {
        errors.add('Non-adjacent clue: ${answer.id}.');
      }
      if (!puzzle.contains(answer.cluePosition)) {
        errors.add('Clue outside grid: ${answer.id}.');
      }
      if (!clues.add(answer.cluePosition)) {
        errors.add('Duplicate clue position.');
      }
      final positions = answer.positions;
      for (var index = 0; index < positions.length; index++) {
        final position = positions[index];
        if (!puzzle.contains(position)) {
          errors.add('Letter outside grid: ${answer.id}.');
        }
        final existing = owners.putIfAbsent(position, () => []);
        if (existing.any((other) => other.direction == answer.direction)) {
          errors.add('Same-direction overlap.');
        }
        if (letters.containsKey(position) &&
            letters[position] != answer.solution[index]) {
          errors.add('Conflicting crossing.');
        }
        existing.add(answer);
        letters[position] = answer.solution[index];
      }
    }
    if (clues.any(letters.containsKey)) errors.add('Clue overlaps letter.');
    if (!puzzle.isAnswerGraphConnected) {
      errors.add('Disconnected answer graph.');
    }

    var phantomCount = 0;
    final horizontalRuns = <LetterRun>[];
    final verticalRuns = <LetterRun>[];
    for (final direction in AnswerDirection.values) {
      for (final position in letters.keys) {
        final next = _step(position, direction, 1);
        if (letters.containsKey(next) &&
            !owners[position]!.any(
              (answer) =>
                  answer.direction == direction &&
                  owners[next]!.contains(answer),
            )) {
          phantomCount++;
        }
        if (letters.containsKey(_step(position, direction, -1))) continue;
        final run = <GridPosition>[];
        var current = position;
        while (letters.containsKey(current)) {
          run.add(current);
          current = _step(current, direction, 1);
        }
        if (run.length >= 2) {
          (direction == AnswerDirection.right ? horizontalRuns : verticalRuns)
              .add(LetterRun(direction, run));
        }
      }
    }
    var unexplained = 0;
    for (final run in [...horizontalRuns, ...verticalRuns]) {
      if (!puzzle.answers.any(
        (answer) =>
            answer.direction == run.direction &&
            answer.start == run.positions.first &&
            answer.length == run.positions.length,
      )) {
        unexplained++;
      }
    }
    for (final answer in puzzle.answers.where((answer) => answer.length > 0)) {
      if (letters.containsKey(
        _step(answer.positions.last, answer.direction, 1),
      )) {
        errors.add('False answer extension: ${answer.id}.');
      }
    }
    if (phantomCount > 0) {
      errors.add('$phantomCount unexplained letter adjacencies.');
    }
    if (unexplained > 0) errors.add('$unexplained unexplained maximal runs.');
    return PuzzleValidation(
      errors: errors,
      phantomAdjacencyCount: phantomCount,
      horizontalRuns: horizontalRuns,
      verticalRuns: verticalRuns,
      unexplainedRunCount: unexplained,
    );
  }
}

GridPosition _step(
  GridPosition position,
  AnswerDirection direction,
  int distance,
) => direction == AnswerDirection.right
    ? GridPosition(position.row, position.column + distance)
    : GridPosition(position.row + distance, position.column);
