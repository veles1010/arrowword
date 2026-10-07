import '../l10n/ui_strings.dart';
import '../l10n/clue_presentation.dart';

import 'package:flutter/material.dart';

import '../features/puzzle/ads/rewarded_hint_ad_service.dart';
import '../features/puzzle/presentation/puzzle_screen.dart';
import '../features/puzzle/presentation/puzzle_completion.dart';
import 'puzzle_replay_attempt.dart';
import 'puzzle_session.dart';

class PuzzleReplayScreen extends StatefulWidget {
  const PuzzleReplayScreen({
    required this.session,
    required this.puzzleIndex,
    this.rewardedAdFactory,
    this.monotonicNow,
    this.identifyTrack = false,
    super.key,
  });
  final PuzzleSession session;
  final int puzzleIndex;
  final RewardedHintAdService Function()? rewardedAdFactory;
  final Duration Function()? monotonicNow;
  final bool identifyTrack;
  @override
  State<PuzzleReplayScreen> createState() => _PuzzleReplayScreenState();
}

class _PuzzleReplayScreenState extends State<PuzzleReplayScreen> {
  PuzzleReplayAttempt? _attempt;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    // Paint the route/loading state before bounded synchronous reconstruction.
    // Generate only once for this route, never during rebuilds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>(() {
        if (!mounted) return;
        try {
          _attempt = PuzzleReplayAttempt(
            session: widget.session,
            puzzleIndex: widget.puzzleIndex,
          );
        } catch (_) {
          // Internal reconstruction errors must not escape into player UI.
        }
        if (mounted) setState(() => _loading = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final attempt = _attempt;
    if (_loading || attempt == null || !attempt.generation.isSuccess) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.identifyTrack
                ? context.l10n.trackPuzzle(
                    context.difficultyLabel(widget.session.difficulty),
                    widget.puzzleIndex,
                  )
                : context.l10n.puzzleNumber(widget.puzzleIndex),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _loading
                  ? CircularProgressIndicator(
                      semanticsLabel: context.l10n.puzzlePreparing,
                    )
                  : Text(context.l10n.replayGenerationFailed),
            ),
          ),
        ),
      );
    }
    final generation = attempt.generation;
    return CluePackGate(
      child: PuzzleScreen(
        puzzle: generation.puzzle!,
        title: widget.identifyTrack
            ? context.l10n.trackPuzzle(
                context.difficultyLabel(widget.session.difficulty),
                widget.puzzleIndex,
              )
            : context.l10n.replayPuzzle(widget.puzzleIndex),
        subtitle: widget.identifyTrack ? context.l10n.replay : null,
        rewardedAdFactory: widget.rewardedAdFactory,
        monotonicNow: widget.monotonicNow,
        onAttemptProgress: attempt.updateProgress,
        onElapsedChanged: attempt.checkpointElapsed,
        onCompleted: attempt.complete,
        completion: PuzzleCompletionPresentation(
          title: context.l10n.puzzleCompleted,
          contentBuilder: (dialogContext) {
            final result = attempt.result!;
            final details = puzzleResultDetails(
              strings: dialogContext.l10n,
              score: result.score,
              scoreLabel: dialogContext.l10n.thisAttempt,
              bestScore: attempt.bestScore?.score ?? result.score,
              elapsedSeconds: result.elapsedSeconds,
              hintsUsed: result.hintsUsed,
              wrongChecks: result.wrongChecks,
            );
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(details),
                if (attempt.isNewBest)
                  Text(
                    dialogContext.l10n.newRecord,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
              ],
            );
          },
          actionLabel: context.l10n.returnPuzzles,
          onFinished: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
