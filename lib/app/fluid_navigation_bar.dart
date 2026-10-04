import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

const shellLabels = ['Ana Sayfa', 'Bulmacalar', 'Günlük', 'İstatistikler'];
const _icons = [
  Icons.home_outlined,
  Icons.grid_view_outlined,
  Icons.today_outlined,
  Icons.bar_chart_outlined,
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
  @override
  void didUpdateWidget(FluidNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) _settle(widget.index);
  }

  void _settle(int index) {
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
    final height = 48 + MediaQuery.textScalerOf(context).scale(12) * 2;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: .08),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth / shellLabels.length;
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
                              left: position * width,
                              top: 0,
                              bottom: 0,
                              width: width,
                              child: DecoratedBox(
                                key: const ValueKey('navigation-pill'),
                                decoration: BoxDecoration(
                                  color: colors.primaryContainer,
                                  borderRadius: BorderRadius.circular(16),
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
                                            scale: 1 + .06 * proximity,
                                            child: Icon(
                                              _icons[i],
                                              color: foreground,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            shellLabels[i],
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: foreground,
                                              fontWeight: proximity > .5
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
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
