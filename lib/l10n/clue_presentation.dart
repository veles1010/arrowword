import 'package:flutter/material.dart';

import '../features/puzzle/domain/puzzle.dart';
import '../features/puzzle/localization/clue_pack.dart';
import 'ui_strings.dart';
import 'clue_pack_cache.dart';

class CluePresentation extends InheritedWidget {
  const CluePresentation({
    this.resolver,
    this.cache,
    required this.locale,
    required super.child,
    super.key,
  });
  final LocalizedClueResolver? resolver;
  final CluePackCache? cache;
  final String locale;
  static String text(BuildContext context, PuzzleAnswer answer) {
    final presentation = context
        .dependOnInheritedWidgetOfExactType<CluePresentation>();
    // Non-catalogue fixtures and standalone screens retain their approved legacy clue.
    if (presentation == null || answer.clueId == null) {
      return answer.turkishClue;
    }
    try {
      final resolver = presentation.resolver;
      if (resolver == null) {
        throw ClueIntegrityException(answer.clueId!, presentation.locale);
      }
      return resolver.resolve(answer.clueId!, presentation.locale);
    } on ClueIntegrityException {
      assert(false, 'Incomplete production clue pack: ${answer.clueId}');
      return context.l10n.clueUnavailable;
    }
  }

  @override
  bool updateShouldNotify(CluePresentation oldWidget) =>
      resolver != oldWidget.resolver ||
      cache != oldWidget.cache ||
      locale != oldWidget.locale;
}

/// Paint loading before constructing gameplay/timers. The FutureBuilder and
/// child structure stay stable when language changes, preserving the game State.
class CluePackGate extends StatelessWidget {
  const CluePackGate({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final source = context
        .dependOnInheritedWidgetOfExactType<CluePresentation>();
    if (source?.cache == null || source?.resolver != null) return child;
    final cache = source!.cache!;
    return FutureBuilder<LoadedCluePack>(
      future: cache.loadFor(source.locale),
      initialData: cache.readyFor(source.locale),
      builder: (context, snapshot) {
        final loaded = snapshot.data;
        final loading = loaded?.locale != source.locale;
        final pending = Scaffold(
          appBar: AppBar(title: Text(context.l10n.puzzle)),
          body: Center(
            child: snapshot.hasError
                ? Text(context.l10n.clueUnavailable)
                : CircularProgressIndicator(
                    semanticsLabel: context.l10n.puzzlePreparing,
                  ),
          ),
        );
        // Keep the gameplay State while hiding old clues during a pack switch.
        return Stack(
          fit: StackFit.expand,
          children: [
            if (loaded != null)
              Offstage(
                offstage: loading,
                child: ClueLoadingScope(
                  loading: loading,
                  child: CluePresentation(
                    resolver: loaded.resolver,
                    locale: loaded.locale,
                    child: child,
                  ),
                ),
              ),
            if (loading) pending,
          ],
        );
      },
    );
  }
}

class ClueLoadingScope extends InheritedWidget {
  const ClueLoadingScope({
    required this.loading,
    required super.child,
    super.key,
  });
  final bool loading;
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ClueLoadingScope>()?.loading ??
      false;
  @override
  bool updateShouldNotify(ClueLoadingScope oldWidget) =>
      loading != oldWidget.loading;
}
