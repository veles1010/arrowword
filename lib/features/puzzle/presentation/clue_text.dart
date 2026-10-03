import 'package:flutter/material.dart';

/// Keeps words intact; the external active-clue panel supplies the full text
/// when the minimum readable size cannot fit inside a cell.
class ClueText extends StatelessWidget {
  const ClueText(this.clue, {super.key});

  final String clue;
  static const minFontSize = 10.0;
  static const maxFontSize = 14.0;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final baseStyle = DefaultTextStyle.of(context).style
        .copyWith(height: 1.1, fontWeight: FontWeight.w600);
    final words = clue.trim().split(RegExp(r'\s+'));
    final singleLine = words.join(' ');
    final candidates = [
      singleLine,
      for (var split = 1; split < words.length; split++)
        '${words.take(split).join(' ')}\n${words.skip(split).join(' ')}',
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        var fittedText = singleLine;
        var fontSize = minFontSize;
        var fits = false;
        for (var size = maxFontSize; size >= minFontSize; size -= 0.5) {
          for (final candidate in candidates) {
            final painter = TextPainter(
              text: TextSpan(
                text: candidate,
                style: baseStyle.copyWith(fontSize: size),
              ),
              textDirection: direction,
              textScaler: scaler,
            )..layout();
            final candidateFits =
                painter.width <= constraints.maxWidth &&
                painter.height <= constraints.maxHeight;
            painter.dispose();
            if (candidateFits) {
              fittedText = candidate;
              fontSize = size;
              fits = true;
              break;
            }
          }
          if (fits) break;
        }
        return ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              fittedText,
              style: baseStyle.copyWith(fontSize: fontSize),
              softWrap: false,
              maxLines: fits && fittedText.contains('\n') ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}
