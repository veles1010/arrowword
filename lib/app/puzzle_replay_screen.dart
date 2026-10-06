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
            '${widget.identifyTrack ? '${widget.session.difficulty.turkishLabel} · ' : ''}Bulmaca ${widget.puzzleIndex}',
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _loading
                  ? const CircularProgressIndicator(
                      semanticsLabel: 'Bulmaca hazırlanıyor',
                    )
                  : const Text(
                      'Bulmaca tekrar oluşturulamadı. Lütfen tekrar deneyin.',
                    ),
            ),
          ),
        ),
      );
    }
    final generation = attempt.generation;
    return PuzzleScreen(
      puzzle: generation.puzzle!,
      title: widget.identifyTrack
          ? '${widget.session.difficulty.turkishLabel} · Bulmaca ${widget.puzzleIndex}'
          : 'Bulmaca ${widget.puzzleIndex} · Tekrar Oyna',
      subtitle: widget.identifyTrack ? 'Tekrar Oyna' : null,
      rewardedAdFactory: widget.rewardedAdFactory,
      monotonicNow: widget.monotonicNow,
      onAttemptProgress: attempt.updateProgress,
      onElapsedChanged: attempt.checkpointElapsed,
      onCompleted: attempt.complete,
      completion: PuzzleCompletionPresentation(
        title: 'Bulmaca tamamlandı!',
        contentBuilder: (_) {
          final result = attempt.result!;
          final details = puzzleResultDetails(
            score: result.score,
            scoreLabel: 'Bu deneme',
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
                const Text(
                  'Yeni rekor!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
            ],
          );
        },
        actionLabel: 'Bulmacalara Dön',
        onFinished: () => Navigator.of(context).pop(),
      ),
    );
  }
}
