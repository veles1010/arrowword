import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../l10n/generated/app_localizations_tr.dart';

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
  String? scoreLabel,
  AppLocalizations? strings,
  int? bestScore,
}) {
  final minutes = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (elapsedSeconds % 60).toString().padLeft(2, '0');
  final copy = strings ?? AppLocalizationsTr();
  return copy.resultDetails(
    scoreLabel ?? copy.score,
    score,
    bestScore == null ? 'no' : 'yes',
    bestScore ?? 0,
    '$minutes:$seconds',
    hintsUsed,
    wrongChecks,
  );
}
