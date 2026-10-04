import 'package:flutter/material.dart';

/// A play context owns its result and destination; the board only presents them.
/// Normal progression uses PuzzleScreen's existing completion/Next behavior.
class PuzzleCompletionPresentation {
  const PuzzleCompletionPresentation({
    required this.title,
    required this.contentBuilder,
    required this.actionLabel,
    required this.onFinished,
  });

  final String title;
  final WidgetBuilder contentBuilder;
  final String actionLabel;
  final VoidCallback onFinished;
}

String puzzleResultDetails({
  required int score,
  required int elapsedSeconds,
  required int hintsUsed,
  required int wrongChecks,
  String scoreLabel = 'Puan',
  int? bestScore,
}) {
  final minutes = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (elapsedSeconds % 60).toString().padLeft(2, '0');
  return '$scoreLabel: $score\n'
      '${bestScore == null ? '' : 'En iyi: $bestScore\n'}'
      'Süre: $minutes:$seconds\nİpucu: $hintsUsed\nHatalı kontrol: $wrongChecks';
}
