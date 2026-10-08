import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/arrowword_visuals.dart';

/// Locale-independent answer keyboard. Ordinary Latin letterforms, geometric
/// keys, and Material pressed feedback; no connection to the platform IME.
class PuzzleKeyboard extends StatelessWidget {
  const PuzzleKeyboard({
    required this.onLetter,
    required this.onBackspace,
    this.enabled = true,
    super.key,
  });

  final ValueChanged<String> onLetter;
  final VoidCallback onBackspace;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visuals = ArrowwordVisuals.of(context);
    final height = math.max(
      44.0,
      MediaQuery.textScalerOf(context).scale(18) + 16,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: visuals.gridBorder)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final row in ['QWERTYUIOP', 'ASDFGHJKL', 'ZXCVBNM'])
                  Padding(
                    padding: EdgeInsets.only(bottom: row == 'ZXCVBNM' ? 0 : 4),
                    child: Row(
                      textDirection: TextDirection.ltr,
                      children: [
                        if (row != 'QWERTYUIOP') const Spacer(),
                        for (final letter in row.split(''))
                          Expanded(
                            flex: 2,
                            child: _key(
                              context,
                              height,
                              ValueKey('keyboard-$letter'),
                              letter,
                              Text(letter),
                              () => onLetter(letter),
                            ),
                          ),
                        if (row == 'ZXCVBNM')
                          Expanded(
                            flex: 3,
                            child: _key(
                              context,
                              height,
                              const ValueKey('keyboard-backspace'),
                              MaterialLocalizations.of(context)
                                  .deleteButtonTooltip,
                              const Icon(Icons.backspace_outlined, size: 22),
                              onBackspace,
                            ),
                          ),
                        if (row != 'QWERTYUIOP') const Spacer(),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _key(
    BuildContext context,
    double height,
    Key key,
    String label,
    Widget child,
    VoidCallback action,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5),
      child: SizedBox(
        height: height,
        child: Semantics(
          label: label,
          button: true,
          enabled: enabled,
          onTap: enabled ? action : null,
          excludeSemantics: true,
          child: Material(
            color: ArrowwordVisuals.of(context).cell,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(color: ArrowwordVisuals.of(context).gridBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: key,
              canRequestFocus: false,
              onTap: enabled ? action : null,
              borderRadius: BorderRadius.circular(6),
              splashColor: scheme.primaryContainer,
              highlightColor: scheme.primary.withValues(alpha: .12),
              child: Center(
                child: DefaultTextStyle(
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: enabled ? scheme.onSurface : scheme.onSurfaceVariant,
                  ),
                  child: IconTheme(
                    data: IconThemeData(color: scheme.onSurfaceVariant),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
