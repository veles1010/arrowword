import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../theme/arrowword_visuals.dart';

import '../domain/puzzle.dart';
import '../domain/puzzle_game.dart';
import '../domain/puzzle_score.dart';
import '../ads/rewarded_hint_ad_service.dart';
import 'board_size.dart';
import 'clue_text.dart';
import 'active_play_timer.dart';
import 'puzzle_completion.dart';

final puzzleRouteObserver = RouteObserver<ModalRoute<dynamic>>();

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({
    required this.puzzle,
    this.title = 'Bulmaca',
    this.subtitle,
    this.onNextPuzzle,
    this.initialLetters = const {},
    this.onLettersChanged,
    this.onCompleted,
    this.initialRevealedCells = const {},
    this.onProgressChanged,
    this.rewardedAdFactory,
    this.initialElapsed = Duration.zero,
    this.initialWrongChecks = 0,
    this.attemptFinalized = false,
    this.onAttemptProgress,
    this.onElapsedChanged,
    this.scoreResult,
    this.monotonicNow,
    this.completion,
    super.key,
  });
  final Puzzle puzzle;
  final Duration initialElapsed;
  final int initialWrongChecks;
  final bool attemptFinalized;
  final Duration Function()? monotonicNow;
  final void Function(
    Map<GridPosition, String>,
    Set<GridPosition>,
    Duration,
    int,
  )?
  onAttemptProgress;
  final ValueChanged<Duration>? onElapsedChanged;
  final CompletedPuzzleScore? Function()? scoreResult;
  final PuzzleCompletionPresentation? completion;
  final RewardedHintAdService Function()? rewardedAdFactory;
  final String title;
  final String? subtitle;
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

class _PuzzleScreenState extends State<PuzzleScreen>
    with WidgetsBindingObserver, RouteAware {
  static const s = '\u200B';
  late final PuzzleGame game;
  late final TextEditingController input;
  late final FocusNode focus;
  bool shown = false;
  bool _finishingCompletion = false;
  late final RewardedHintAdService ads;
  bool requestingHint = false;
  late final ActivePlayTimer timer;
  late Map<GridPosition, String> _lastLetters;
  late Set<GridPosition> _lastRevealed;
  late int _lastChecks;
  bool _appActive = true;
  bool _routeVisible = true;
  ModalRoute<dynamic>? _route;
  @override
  void initState() {
    super.initState();
    ads = widget.rewardedAdFactory?.call() ?? UnavailableHintAdService();
    ads.addListener(_adChanged);
    ads.preload();
    game = PuzzleGame(widget.puzzle, wrongChecks: widget.initialWrongChecks)
      ..restoreLetters(
        widget.initialLetters,
        revealedCells: widget.initialRevealedCells,
      );
    game.addListener(_changed);
    _lastLetters = game.enteredLetters;
    _lastRevealed = game.revealedCells;
    _lastChecks = game.wrongChecks;
    timer = ActivePlayTimer(
      initialElapsed: widget.initialElapsed,
      monotonicNow: widget.monotonicNow,
    );
    _appActive =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
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
    timer.pause();
    widget.onElapsedChanged?.call(timer.elapsed);
    puzzleRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    ads.removeListener(_adChanged);
    ads.dispose();
    game.dispose();
    input.dispose();
    focus.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      puzzleRouteObserver.unsubscribe(this);
      _route = route;
      if (route != null) puzzleRouteObserver.subscribe(this, route);
    }
    _syncTimer();
  }

  void _syncTimer() {
    if (_appActive &&
        _routeVisible &&
        !requestingHint &&
        !shown &&
        !game.isComplete &&
        !widget.attemptFinalized) {
      timer.resume();
    } else {
      timer.pause();
      widget.onElapsedChanged?.call(timer.elapsed);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    _syncTimer();
  }

  @override
  void didPush() {
    _routeVisible = true;
    _syncTimer();
  }

  @override
  void didPopNext() {
    _routeVisible = true;
    _syncTimer();
  }

  @override
  void didPushNext() {
    _routeVisible = false;
    _syncTimer();
  }

  @override
  void didPop() {
    _routeVisible = false;
    _syncTimer();
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
    _syncTimer();
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
    _syncTimer();
  }

  void _adUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reklam şu anda hazır değil. Lütfen tekrar deneyin.'),
      ),
    );
  }

  void _changed() {
    if (game.isComplete) timer.pause();
    if (!mapEquals(_lastLetters, game.enteredLetters) ||
        !setEquals(_lastRevealed, game.revealedCells) ||
        _lastChecks != game.wrongChecks ||
        (game.isComplete && !shown)) {
      widget.onAttemptProgress?.call(
        game.enteredLetters,
        game.revealedCells,
        timer.elapsed,
        game.wrongChecks,
      );
      _lastLetters = game.enteredLetters;
      _lastRevealed = game.revealedCells;
      _lastChecks = game.wrongChecks;
    }
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
            builder: (c) => PopScope<void>(
              canPop: widget.completion == null,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop && widget.completion != null) _finishCompletion(c);
              },
              child: AlertDialog(
                scrollable: true,
                title: Text(widget.completion?.title ?? 'Bulmaca tamamlandı!'),
                content:
                    widget.completion?.contentBuilder(c) ??
                    _completionContent(),
                actions: widget.completion != null
                    ? [
                        FilledButton(
                          onPressed: () => _finishCompletion(c),
                          child: Text(widget.completion!.actionLabel),
                        ),
                      ]
                    : [
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
            ),
          );
        }
      });
    }
  }

  void _finishCompletion(BuildContext dialogContext) {
    if (_finishingCompletion) return;
    _finishingCompletion = true;
    Navigator.pop(dialogContext);
    widget.completion!.onFinished();
  }

  Widget _completionContent() {
    final score = widget.scoreResult?.call();
    if (score == null) {
      return Text(
        widget.scoreResult == null
            ? 'Tüm harfler doğru.'
            : 'Bu bulmaca puanlama sistemi eklenmeden önce tamamlandı.',
      );
    }
    return Text(
      puzzleResultDetails(
        score: score.score,
        elapsedSeconds: score.elapsedSeconds,
        hintsUsed: score.hintsUsed,
        wrongChecks: score.wrongChecks,
      ),
    );
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
      backgroundColor: ArrowwordVisuals.of(c).puzzlePage,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        toolbarHeight: widget.subtitle == null
            ? null
            : (MediaQuery.textScalerOf(c).scale(20) * 1.2 +
                      MediaQuery.textScalerOf(c).scale(11) * 1.2 +
                      8)
                  .clamp(56, 96),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (widget.subtitle != null)
              Text(
                widget.subtitle!,
                maxLines: 1,
                style: Theme.of(c).textTheme.labelSmall,
              ),
          ],
        ),
      ),
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
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
    final visuals = ArrowwordVisuals.of(c);
    if (cell.type == PuzzleCellType.blocked) {
      return ColoredBox(color: visuals.unused);
    }
    if (cell.type == PuzzleCellType.clue) {
      final a = cell.clues.first;
      return InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: visuals.clue,
            border: Border.all(color: visuals.gridBorder),
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
                    color: cs.onTertiaryContainer,
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
    final hinted = game.isHint(p);
    final edge = BorderSide(
      color: bad
          ? cs.error
          : selected
          ? cs.primary
          : game.isActive(p)
          ? visuals.activeBorder
          : visuals.gridBorder,
      width: selected
          ? 2.5
          : game.isActive(p)
          ? 1.5
          : 1,
    );
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
              ? hinted
                    ? visuals.hintActive
                    : visuals.active
              : hinted
              ? cs.primaryContainer
              : visuals.cell,
          border: Border(
            top: edge,
            left: edge,
            right: edge,
            bottom: hinted
                ? BorderSide(
                    color: bad
                        ? cs.error
                        : selected
                        ? cs.onPrimary
                        : cs.primary,
                    width: 3,
                  )
                : edge,
          ),
        ),
        child: Semantics(
          label: hinted ? 'İpucuyla açıldı, kilitli' : null,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              game.letterAt(p) ?? '',
              style: Theme.of(c).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                decoration: hinted ? TextDecoration.underline : null,
                decorationThickness: hinted ? 2 : null,
                color: bad
                    ? cs.onErrorContainer
                    : selected
                    ? cs.onPrimary
                    : game.isActive(p)
                    ? cs.onSecondaryContainer
                    : cs.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
