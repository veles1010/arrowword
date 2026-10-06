import 'dart:math' as math;

import '../theme/arrowword_visuals.dart';

import 'package:flutter/material.dart';

import '../features/puzzle/ads/rewarded_hint_ad_service.dart';

import 'puzzle_session.dart';
import 'player_puzzle_tracks.dart';
import 'puzzle_difficulty_selector.dart';
import '../features/puzzle/domain/puzzle_difficulty.dart';
import 'puzzle_replay_screen.dart';

/// Linear progression, with isolated replays of completed historical puzzles.
class PuzzleProgressionScreen extends StatefulWidget {
  const PuzzleProgressionScreen({
    this.session,
    this.tracks,
    this.trackPuzzleBuilder,
    this.trackReplayBuilder,
    required this.puzzleBuilder,
    this.rewardedAdFactory,
    this.inShell = false,
    super.key,
  });

  final PuzzleSession? session;
  final PlayerPuzzleTracks? tracks;
  final Widget Function(PuzzleDifficulty)? trackPuzzleBuilder;
  final Widget Function(PuzzleDifficulty, int)? trackReplayBuilder;
  final WidgetBuilder puzzleBuilder;
  final bool inShell;
  final RewardedHintAdService Function()? rewardedAdFactory;

  @override
  State<PuzzleProgressionScreen> createState() =>
      _PuzzleProgressionScreenState();
}

class _PuzzleProgressionScreenState extends State<PuzzleProgressionScreen> {
  final _scroll = ScrollController();
  int? _focusedIndex;
  late PuzzleDifficulty _difficulty =
      widget.tracks?.lastPlayed ?? PuzzleDifficulty.easy;

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
    listenable: widget.tracks ?? widget.session!,
    builder: (context, _) {
      final session = widget.session;
      final tracks = widget.tracks;
      final summary =
          tracks?.summary(_difficulty) ??
          PuzzleTrackSummary.fromSession(session!);
      final current = summary.index;
      final scores = summary.scores;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Bulmacalar'),
          automaticallyImplyLeading: !widget.inShell,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (tracks != null) ...[
                  PuzzleDifficultySelector(
                    selected: _difficulty,
                    onChanged: (value) {
                      setState(() {
                        _difficulty = value;
                        _focusedIndex = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = (constraints.maxWidth / 88).floor().clamp(
                        3,
                        5,
                      );
                      final scaler = MediaQuery.textScalerOf(context);
                      final tileHeight =
                          72 + scaler.scale(16) + scaler.scale(12);
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
                          final completed = index <= summary.completedThrough;
                          final replayable = completed && index < current;
                          final score = completed ? scores[index] : null;
                          final locked = index > current;
                          final colors = Theme.of(context).colorScheme;
                          final label = locked
                              ? 'Kilitli'
                              : isCurrent
                              ? 'Devam Et'
                              : 'Tamamlandı';
                          return Semantics(
                            label:
                                'Bulmaca $index, $label${isCurrent && completed ? ', tamamlandı' : ''}${score == null ? '' : ', ${score.score} puan'}${replayable ? ', tekrar oyna' : ''}',
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
                                onTap:
                                    replayable ||
                                        (isCurrent &&
                                            (tracks != null ||
                                                session!.current.isSuccess))
                                    ? () => Navigator.of(context).push<void>(
                                        MaterialPageRoute(
                                          builder: tracks != null
                                              ? (_) => isCurrent
                                                    ? widget
                                                          .trackPuzzleBuilder!(
                                                        _difficulty,
                                                      )
                                                    : widget
                                                          .trackReplayBuilder!(
                                                        _difficulty,
                                                        index,
                                                      )
                                              : isCurrent
                                              ? widget.puzzleBuilder
                                              : (_) => PuzzleReplayScreen(
                                                  session: session!,
                                                  puzzleIndex: index,
                                                  rewardedAdFactory:
                                                      widget.rewardedAdFactory,
                                                ),
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
                                            : ArrowwordVisuals.of(context)
                                                  .difficultyAccent(
                                                    _difficulty,
                                                    colors,
                                                  ),
                                        size: 24,
                                      ),
                                      const SizedBox(height: 4),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'Bulmaca $index',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: isCurrent
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                            color: isCurrent
                                                ? colors.onPrimaryContainer
                                                : locked
                                                ? colors.onSurfaceVariant
                                                : colors.onSurface,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (replayable)
                                              const Icon(
                                                Icons.replay,
                                                size: 12,
                                              ),
                                            Text(
                                              label,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (score != null)
                                        Flexible(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              '${score.score} puan',
                                              key: ValueKey(
                                                'puzzle-score-$index',
                                              ),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isCurrent
                                                    ? colors.onPrimaryContainer
                                                    : colors.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
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
              ],
            ),
          ),
        ),
      );
    },
  );
}
