import 'package:flutter/foundation.dart';

import 'puzzle.dart';

class PuzzleGame extends ChangeNotifier {
  PuzzleGame(this.puzzle) : _activeAnswer = puzzle.answers.first {
    _selectedPosition = _activeAnswer.positions.first;
  }
  final Puzzle puzzle;
  final Map<GridPosition, String> _letters = {};
  final Set<GridPosition> _revealed = {};
  Set<GridPosition> get revealedCells => Set.unmodifiable(_revealed);
  int get hintsUsed => _revealed.length;
  bool isHint(GridPosition p) => _revealed.contains(p);
  bool get canRevealSelected =>
      puzzle.answersAt(_selectedPosition).isNotEmpty &&
      !isHint(_selectedPosition) &&
      letterAt(_selectedPosition) != _expected(_selectedPosition);
  bool revealSelectedLetter() {
    if (!canRevealSelected) return false;
    _revealed.add(_selectedPosition);
    _letters[_selectedPosition] = _expected(_selectedPosition);
    _showValidation = false;
    notifyListeners();
    return true;
  }

  late PuzzleAnswer _activeAnswer;
  late GridPosition _selectedPosition;
  bool _showValidation = false;
  PuzzleAnswer get activeAnswer => _activeAnswer;
  GridPosition get selectedPosition => _selectedPosition;
  String? letterAt(GridPosition p) => _letters[p];
  Map<GridPosition, String> get enteredLetters => Map.unmodifiable(_letters);
  void restoreLetters(
    Map<GridPosition, String> letters, {
    Set<GridPosition> revealedCells = const {},
  }) {
    _letters.clear();
    _revealed.clear();
    for (final entry in letters.entries) {
      if (puzzle.answersAt(entry.key).isNotEmpty &&
          RegExp(r'^[A-Z]$').hasMatch(entry.value)) {
        _letters[entry.key] = entry.value;
      }
    }
    for (final p in revealedCells) {
      if (puzzle.answersAt(p).isNotEmpty) {
        _revealed.add(p);
        _letters[p] = _expected(p);
      }
    }
    notifyListeners();
  }

  bool isActive(GridPosition p) => _activeAnswer.positions.contains(p);
  bool isSelected(GridPosition p) => p == _selectedPosition;
  bool isIncorrect(GridPosition p) =>
      _showValidation && _letters.containsKey(p) && _letters[p] != _expected(p);
  void tapCell(GridPosition p) {
    final a = puzzle.answersAt(p);
    if (a.isEmpty) return;
    if (p == _selectedPosition && a.length > 1) {
      _activeAnswer = a[(a.indexOf(_activeAnswer) + 1) % a.length];
    } else if (!a.contains(_activeAnswer)) {
      _activeAnswer = a.first;
    }
    _selectedPosition = p;
    notifyListeners();
  }

  void tapClue(PuzzleAnswer a) {
    _activeAnswer = a;
    _selectedPosition = a.positions.first;
    notifyListeners();
  }

  void enterLetter(String s) {
    if (isHint(_selectedPosition)) return;
    final l = s.toUpperCase();
    if (!RegExp(r'^[A-Z]$').hasMatch(l)) return;
    _letters[_selectedPosition] = l;
    _showValidation = false;
    final i = _activeAnswer.positions.indexOf(_selectedPosition);
    if (i < _activeAnswer.length - 1) {
      _selectedPosition = _activeAnswer.positions[i + 1];
    }
    notifyListeners();
  }

  void backspace() {
    if (isHint(_selectedPosition)) return;
    if (_letters.containsKey(_selectedPosition)) {
      _letters.remove(_selectedPosition);
    } else {
      final i = _activeAnswer.positions.indexOf(_selectedPosition);
      if (i > 0) {
        _selectedPosition = _activeAnswer.positions[i - 1];
        if (!isHint(_selectedPosition)) _letters.remove(_selectedPosition);
      }
    }
    _showValidation = false;
    notifyListeners();
  }

  void check() {
    _showValidation = true;
    notifyListeners();
  }

  bool get isComplete => _positions.every((p) => _letters[p] == _expected(p));
  void reset() {
    _letters.removeWhere((p, _) => !isHint(p));
    _showValidation = false;
    _activeAnswer = puzzle.answers.first;
    _selectedPosition = _activeAnswer.positions.first;
    notifyListeners();
  }

  Set<GridPosition> get _positions =>
      puzzle.answers.expand((a) => a.positions).toSet();
  String _expected(GridPosition p) {
    final a = puzzle.answersAt(p).first;
    return a.solution[a.positions.indexOf(p)];
  }
}
