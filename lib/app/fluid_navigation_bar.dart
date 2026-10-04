import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'dart:math' as math;

const shellLabels = ['Ana Sayfa', 'Bulmacalar', 'Günlük', 'İstatistikler'];
const _icons = [
  Icons.home_rounded,
  Icons.grid_view_rounded,
  Icons.today_rounded,
  Icons.bar_chart_rounded,
];

/// Continuous visual position is local to the bar; only release/tap commits a tab.
class FluidNavigationBar extends StatefulWidget {
  const FluidNavigationBar({
    required this.index,
    required this.onSelected,
    super.key,
  });
  final int index;
  final ValueChanged<int> onSelected;
  @override
  State<FluidNavigationBar> createState() => _FluidNavigationBarState();
}

class _FluidNavigationBarState extends State<FluidNavigationBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _position = AnimationController.unbounded(
    vsync: this,
    value: widget.index.toDouble(),
  );
  double _dragStart = 0, _distance = 0;
  int? _settlingTo;
  @override
  void didUpdateWidget(FluidNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) _settle(widget.index);
  }

  void _settle(int index) {
    // Parent commit acknowledgment must not restart the same settle animation.
    if (_position.isAnimating && _settlingTo == index) return;
    _settlingTo = index;
    if (MediaQuery.disableAnimationsOf(context)) {
      _position.value = index.toDouble();
    } else {
      _position.animateTo(
        index.toDouble(),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _select(int index) {
    _settle(index);
    widget.onSelected(index);
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scaler = MediaQuery.textScalerOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          6,
          12,
          MediaQuery.paddingOf(context).bottom > 0 ? 4 : 8,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: dark
                ? colors.surfaceContainerLow
                : colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: .55),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: .04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth / shellLabels.length;
                // Measure labels once per layout, never on drag animation frames.
                var labelHeight = 0.0;
                for (final label in shellLabels) {
                  final painter = TextPainter(
                    text: TextSpan(
                      text: label,
                      style: DefaultTextStyle.of(context).style.copyWith(
                        fontSize: 12,
                        height: 1.15,
                        fontWeight: FontWeight.w500,
                        fontVariations: const [FontVariation('wght', 600)],
                      ),
                    ),
                    textScaler: scaler,
                    textDirection: Directionality.of(context),
                  )..layout(maxWidth: math.max(1, width - 8));
                  labelHeight = math.max(labelHeight, painter.height);
                  painter.dispose();
                }
                final height = math.max(64.0, 44 + labelHeight);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  // Flutter's horizontal gesture arena requires touch slop/intent;
                  // vertical scrolling and taps never become bar drags.
                  dragStartBehavior: DragStartBehavior.down,
                  onHorizontalDragStart: (_) {
                    _position.stop();
                    _dragStart = _position.value;
                    _distance = 0;
                  },
                  onHorizontalDragUpdate: (details) {
                    _distance += details.delta.dx;
                    _position.value = (_dragStart + _distance / width).clamp(
                      0.0,
                      3.0,
                    );
                  },
                  // Nearest position, not velocity, wins: slow and fast gestures agree.
                  onHorizontalDragEnd: (_) =>
                      _select(_position.value.round().clamp(0, 3)),
                  onHorizontalDragCancel: () => _settle(widget.index),
                  child: SizedBox(
                    height: height,
                    child: AnimatedBuilder(
                      animation: _position,
                      builder: (context, _) {
                        final position = _position.value.clamp(0.0, 3.0);
                        return Stack(
                          children: [
                            Positioned(
                              left: position * width + 4,
                              top: 4,
                              bottom: 4,
                              width: width - 8,
                              child: DecoratedBox(
                                key: const ValueKey('navigation-pill'),
                                decoration: BoxDecoration(
                                  color: Color.alphaBlend(
                                    colors.primary.withValues(
                                      alpha: dark ? .12 : .07,
                                    ),
                                    dark
                                        ? colors.surfaceContainerLow
                                        : colors.surfaceContainerLowest,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                            Row(
                              children: List.generate(4, (i) {
                                final proximity = (1 - (position - i).abs())
                                    .clamp(0.0, 1.0);
                                final foreground = Color.lerp(
                                  colors.onSurfaceVariant,
                                  colors.onPrimaryContainer,
                                  proximity,
                                )!;
                                return Expanded(
                                  child: Semantics(
                                    label: shellLabels[i],
                                    button: true,
                                    selected: widget.index == i,
                                    onTap: () => _select(i),
                                    excludeSemantics: true,
                                    child: GestureDetector(
                                      key: ValueKey('navigation-$i'),
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => _select(i),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Transform.scale(
                                            scale: 1 + .035 * proximity,
                                            child: Icon(
                                              _icons[i],
                                              color: foreground,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            child: Text(
                                              shellLabels[i],
                                              textAlign: TextAlign.center,
                                              softWrap: true,
                                              style: TextStyle(
                                                fontSize: 12,
                                                height: 1.15,
                                                color: foreground,
                                                fontWeight: FontWeight.w500,
                                                fontVariations: [
                                                  FontVariation(
                                                    'wght',
                                                    400 + 200 * proximity,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
