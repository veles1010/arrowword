import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'puzzle_session.dart';

/// Read-only linear progression; only the current puzzle can be opened.
class PuzzleProgressionScreen extends StatefulWidget {
  const PuzzleProgressionScreen({
    required this.session,
    required this.puzzleBuilder,
    super.key,
  });

  final PuzzleSession session;
  final WidgetBuilder puzzleBuilder;

  @override
  State<PuzzleProgressionScreen> createState() =>
      _PuzzleProgressionScreenState();
}

class _PuzzleProgressionScreenState extends State<PuzzleProgressionScreen> {
  final _scroll = ScrollController();
  int? _focusedIndex;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _findCurrent(int index, int columns, double tileHeight, double height) {
    if (_focusedIndex == index) return;
    _focusedIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final row = (index - 1) ~/ columns;
      final offset = row * (tileHeight + 8) - (height - tileHeight) / 2;
      _scroll.jumpTo(offset.clamp(0.0, _scroll.position.maxScrollExtent));
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.session,
    builder: (context, _) {
      final session = widget.session;
      final current = session.current.puzzleIndex;
      return Scaffold(
        appBar: AppBar(title: const Text('Bulmacalar')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = (constraints.maxWidth / 88).floor().clamp(3, 5);
                final scaler = MediaQuery.textScalerOf(context);
                final tileHeight = 72 + scaler.scale(16) + scaler.scale(12);
                _findCurrent(
                  current,
                  columns,
                  tileHeight,
                  constraints.maxHeight,
                );
                return GridView.builder(
                  controller: _scroll,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisExtent: tileHeight,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: math.min(current + 5, 0xffffffff),
                  itemBuilder: (context, offset) {
                    final index = offset + 1;
                    final isCurrent = index == current;
                    final completed = index <= session.completedThrough;
                    final locked = index > current;
                    final colors = Theme.of(context).colorScheme;
                    final label = locked
                        ? 'Kilitli'
                        : isCurrent
                        ? 'Devam Et'
                        : 'Tamamlandı';
                    return Semantics(
                      label:
                          'Bulmaca $index, $label${isCurrent && completed ? ', tamamlandı' : ''}',
                      child: Material(
                        color: isCurrent
                            ? colors.primaryContainer
                            : colors.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isCurrent
                                ? colors.primary
                                : colors.outlineVariant,
                            width: isCurrent ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: ValueKey('puzzle-tile-$index'),
                          onTap: isCurrent && session.current.isSuccess
                              ? () => Navigator.of(context).push<void>(
                                  MaterialPageRoute(
                                    builder: widget.puzzleBuilder,
                                  ),
                                )
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  locked
                                      ? Icons.lock_outline
                                      : completed
                                      ? Icons.check_circle_outline
                                      : Icons.play_arrow,
                                  color: isCurrent
                                      ? colors.onPrimaryContainer
                                      : locked
                                      ? colors.outline
                                      : colors.primary,
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Bulmaca $index',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  label,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );
    },
  );
}
