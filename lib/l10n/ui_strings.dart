import 'package:flutter/material.dart';

import '../features/puzzle/domain/puzzle_difficulty.dart';
import 'generated/app_localizations.dart';
import 'generated/app_localizations_tr.dart';

/// Turkish fallback also keeps standalone/embedded screens usable without a root delegate.
extension UiStrings on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? AppLocalizationsTr();
  String difficultyLabel(PuzzleDifficulty difficulty) => switch (difficulty) {
    PuzzleDifficulty.easy => l10n.easy,
    PuzzleDifficulty.medium => l10n.medium,
    PuzzleDifficulty.hard => l10n.hard,
  };
}

String localizedDailyDate(String key, AppLocalizations strings) {
  final date = DateTime.parse(key);
  final months = [
    strings.month1,
    strings.month2,
    strings.month3,
    strings.month4,
    strings.month5,
    strings.month6,
    strings.month7,
    strings.month8,
    strings.month9,
    strings.month10,
    strings.month11,
    strings.month12,
  ];
  return strings.dateDisplay(date.day, months[date.month - 1], date.year);
}
