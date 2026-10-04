import 'package:flutter/material.dart';

import '../domain/puzzle.dart';
import '../domain/puzzle_game.dart';
import '../ads/rewarded_hint_ad_service.dart';
import 'board_size.dart';
import 'clue_text.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({
    required this.puzzle,
    this.title = 'Bulmaca Prototipi',
    this.onNextPuzzle,
    this.initialLetters = const {},
    this.onLettersChanged,
    this.onCompleted,
    this.initialRevealedCells = const {},
    this.onProgressChanged,
    this.rewardedAdFactory,
    super.key,
  });
  final Puzzle puzzle;
  final RewardedHintAdService Function()? rewardedAdFactory;
  final String title;
  final VoidCallback? onNextPuzzle;
  final Map<GridPosition, String> initialLetters;
  final ValueChanged<Map<GridPosition, String>>? onLettersChanged;
  final VoidCallback? onCompleted;
  final Set<GridPosition> initialRevealedCells;
  final void Function(Map<GridPosition, String>, Set<GridPosition>)?
  onProgressChanged;
  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  static const s = '\u200B';
  late final PuzzleGame game;
  late final TextEditingController input;
  late final FocusNode focus;
  bool shown = false;
  late final RewardedHintAdService ads;
  bool requestingHint = false;
  @override
  void initState() {
    super.initState();
    ads = widget.rewardedAdFactory?.call() ?? UnavailableHintAdService();
    ads.addListener(_adChanged);
    ads.preload();
    game = PuzzleGame(widget.puzzle)
      ..restoreLetters(
        widget.initialLetters,
        revealedCells: widget.initialRevealedCells,
      );
    game.addListener(_changed);
    input = TextEditingController(text: s);
    focus = FocusNode();
    if (game.isComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _changed();
      });
    }
  }

  @override
  void dispose() {
    ads.removeListener(_adChanged);
    ads.dispose();
    game.dispose();
    input.dispose();
    focus.dispose();
    super.dispose();
  }

  void _adChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _requestHint() async {
    final position = game.selectedPosition;
    if (requestingHint || !game.canRevealAt(position)) return;
    if (!ads.isReady) {
      _adUnavailable();
      ads.preload();
      return;
    }
    setState(() => requestingHint = true);
    focus.unfocus();
    HintAdResult result;
    try {
      result = await ads.show();
    } catch (_) {
      result = HintAdResult.failed;
    }
    if (!mounted) return;
    setState(() => requestingHint = false);
    if (result == HintAdResult.earned) {
      // Selection can change during an ad; grant only to the captured target.
      game.revealLetter(position);
    } else if (result != HintAdResult.dismissed) {
      _adUnavailable();
    }
  }

  void _adUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reklam şu anda hazır değil. Lütfen tekrar deneyin.'),
      ),
    );
  }

  void _changed() {
    widget.onProgressChanged?.call(game.enteredLetters, game.revealedCells);
    widget.onLettersChanged?.call(game.enteredLetters);
    if (mounted) {
      setState(() {});
    }
    if (game.isComplete && !shown) {
      widget.onCompleted?.call();
      shown = true;
      focus.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (c) => AlertDialog(
              title: const Text('Bulmaca tamamlandı!'),
              content: const Text('Tüm harfler doğru.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('Kapat'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(c);
                    if (widget.onNextPuzzle != null) {
                      widget.onNextPuzzle!();
                      return;
                    }
                    shown = false;
                    game.reset();
                    focus.requestFocus();
                  },
                  child: Text(
                    widget.onNextPuzzle == null
                        ? 'Yeniden Başlat'
                        : 'Sonraki Bulmaca',
                  ),
                ),
              ],
            ),
          );
        }
      });
    }
  }

  void _input(String t) {
    final x = t.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    x.isEmpty ? game.backspace() : game.enterLetter(x.substring(x.length - 1));
    input.value = const TextEditingValue(
      text: s,
      selection: TextSelection.collapsed(offset: 1),
    );
  }

  @override
  Widget build(BuildContext c) {
    final a = game.activeAnswer;
    final bounds = widget.puzzle.displayBounds;
    final keyboardOpen = MediaQuery.viewInsetsOf(c).bottom > 0;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, contentConstraints) {
            final compact = keyboardOpen || contentConstraints.maxHeight < 480;
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: compact ? 4 : 10,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(c).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: compact ? 4 : 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            a.direction == AnswerDirection.right
                                ? Icons.arrow_forward
                                : Icons.arrow_downward,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${a.turkishClue} (${a.length})',
                              key: const ValueKey('active-clue'),
                              style: Theme.of(c).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (c, b) {
                      // Expanded receives the height left after the real clue,
                      // controls and input heights. Scaffold already removed the
                      // keyboard and app bar; do not subtract their heights again.
                      final board = BoardSize.fit(
                        availableWidth: b.maxWidth - 20,
                        availableHeight: b.maxHeight,
                        rows: bounds.rowCount,
                        columns: bounds.columnCount,
                      );
                      return Center(
                        child: SizedBox(
                          key: const ValueKey('puzzle-board'),
                          width: board.width,
                          height: board.height,
                          child: GridView.builder(
                            padding: EdgeInsets.zero,
                            primary: false,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: bounds.columnCount,
                                  mainAxisExtent: board.cellSize,
                                ),
                            itemCount: bounds.rowCount * bounds.columnCount,
                            itemBuilder: (c, i) {
                              final displayPosition = GridPosition(
                                i ~/ bounds.columnCount,
                                i % bounds.columnCount,
                              );
                              final p = bounds.toLogical(displayPosition);
                              final cell = widget.puzzle.cellAt(p);
                              return _Cell(
                                key: ValueKey('cell-${p.row}-${p.column}'),
                                cell: cell,
                                p: p,
                                game: game,
                                onTap: () {
                                  cell.type == PuzzleCellType.clue
                                      ? game.tapClue(cell.clues.first)
                                      : game.tapCell(p);
                                  focus.requestFocus();
                                },
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: compact ? 4 : 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: game.reset,
                          child: const Text('Temizle'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          onPressed:
                              game.canRevealSelected &&
                                  !ads.isLoading &&
                                  !requestingHint
                              ? _requestHint
                              : null,
                          child: Text(
                            ads.isLoading
                                ? 'Reklam hazırlanıyor'
                                : 'Reklamla Harf Aç',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: game.check,
                          child: const Text('Kontrol Et'),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 1,
                  height: 1,
                  child: TextField(
                    controller: input,
                    focusNode: focus,
                    onChanged: _input,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    super.key,
    required this.cell,
    required this.p,
    required this.game,
    required this.onTap,
  });
  final PuzzleCell cell;
  final GridPosition p;
  final PuzzleGame game;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) {
    final cs = Theme.of(c).colorScheme;
    if (cell.type == PuzzleCellType.blocked) {
      return ColoredBox(color: cs.surface.withValues(alpha: 0.35));
    }
    if (cell.type == PuzzleCellType.clue) {
      final a = cell.clues.first;
      return InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: cs.tertiaryContainer,
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Semantics(
            label:
                '${a.turkishClue}, ${a.length} harf, ${a.direction == AnswerDirection.right ? 'sağa' : 'aşağı'}',
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  bottom: 10,
                  child: ClueText(a.turkishClue),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Icon(
                    a.direction == AnswerDirection.right
                        ? Icons.arrow_forward
                        : Icons.arrow_downward,
                    size: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final selected = game.isSelected(p);
    final bad = game.isIncorrect(p);
    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bad
              ? cs.errorContainer
              : selected
              ? cs.primary
              : game.isActive(p)
              ? cs.secondaryContainer
              : cs.surfaceContainerLowest,
          border: Border.all(
            color: selected
                ? cs.primary
                : game.isActive(p)
                ? cs.secondary
                : cs.outlineVariant.withValues(alpha: 0.7),
            width: selected
                ? 2.5
                : game.isActive(p)
                ? 1.5
                : 1,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            game.letterAt(p) ?? '',
            style: Theme.of(c).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              decoration: game.isHint(p) ? TextDecoration.underline : null,
              color: bad
                  ? cs.onErrorContainer
                  : selected
                  ? cs.onPrimary
                  : cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
