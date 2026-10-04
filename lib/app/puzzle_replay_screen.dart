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
    super.key,
  });
  final PuzzleSession session;
  final int puzzleIndex;
  final RewardedHintAdService Function()? rewardedAdFactory;
  final Duration Function()? monotonicNow;
  @override
  State<PuzzleReplayScreen> createState() => _PuzzleReplayScreenState();
}

class _PuzzleReplayScreenState extends State<PuzzleReplayScreen> {
  late final PuzzleReplayAttempt attempt;
  @override
  void initState() {
    super.initState();
    attempt = PuzzleReplayAttempt(
      session: widget.session,
      puzzleIndex: widget.puzzleIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final generation = attempt.generation;
    if (!generation.isSuccess) {
      return Scaffold(
        appBar: AppBar(title: Text('Bulmaca ${widget.puzzleIndex}')),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Bulmaca tekrar açılamadı.\n${generation.failureReason}',
              ),
            ),
          ),
        ),
      );
    }
    return PuzzleScreen(
      puzzle: generation.puzzle!,
      title: 'Bulmaca ${widget.puzzleIndex} · Tekrar Oyna',
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
