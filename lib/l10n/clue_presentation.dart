import 'package:flutter/material.dart';

import '../features/puzzle/domain/puzzle.dart';
import '../features/puzzle/localization/clue_pack.dart';
import 'ui_strings.dart';

class CluePresentation extends InheritedWidget {
  const CluePresentation({
    required this.resolver,
    required this.locale,
    required super.child,
    super.key,
  });
  final LocalizedClueResolver resolver;
  final String locale;
  static String text(BuildContext context, PuzzleAnswer answer) {
    final presentation = context
        .dependOnInheritedWidgetOfExactType<CluePresentation>();
    // Non-catalogue fixtures and standalone screens retain their approved legacy clue.
    if (presentation == null || answer.clueId == null) {
      return answer.turkishClue;
    }
    try {
      return presentation.resolver.resolve(answer.clueId!, presentation.locale);
    } on ClueIntegrityException {
      assert(false, 'Incomplete production clue pack: ${answer.clueId}');
      return context.l10n.clueUnavailable;
    }
  }

  @override
  bool updateShouldNotify(CluePresentation oldWidget) =>
      resolver != oldWidget.resolver || locale != oldWidget.locale;
}
