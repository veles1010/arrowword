import 'package:flutter/foundation.dart';

import '../features/puzzle/data/prototype_puzzle.dart';
import '../features/puzzle/sequence/puzzle_sequence.dart';

/// Session-only progression, retaining every successfully generated index.
class PuzzleSession extends ChangeNotifier {
  PuzzleSession({PuzzleSequenceGenerator? generator, int startIndex = 1})
    : _generator =
          generator ??
          PuzzleSequenceGenerator(prototypeCatalogue, prototypeSequenceConfig) {
    if (startIndex < 1 || startIndex > 0xffffffff) {
      throw ArgumentError.value(startIndex, 'startIndex');
    }
    for (var index = 1; index <= startIndex; index++) {
      _generate(index);
      if (!current.isSuccess) break;
    }
  }
  final PuzzleSequenceGenerator _generator;
  final List<PuzzleHistoryEntry> _history = [];
  late SequencePuzzleResult current;
  List<PuzzleHistoryEntry> get history => List.unmodifiable(_history);
  void _generate(int index) {
    current = _generator.generateNext(puzzleIndex: index, history: history);
    if (current.isSuccess) _history.add(current.toHistory());
  }

  void nextPuzzle() {
    if (!current.isSuccess) return;
    _generate(current.puzzleIndex + 1);
    notifyListeners();
  }
}
