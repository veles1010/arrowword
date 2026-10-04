import 'package:flutter/material.dart';

import '../features/puzzle/ads/rewarded_hint_ad_service.dart';
import '../features/puzzle/presentation/puzzle_completion.dart';
import '../features/puzzle/presentation/puzzle_screen.dart';
import 'daily_session.dart';

/// Daily owns a separate resumable attempt, never a normal progression session.
class DailyPuzzleScreen extends StatefulWidget {
  const DailyPuzzleScreen({
    required this.session,
    this.rewardedAdFactory,
    this.monotonicNow,
    super.key,
  });

  final DailySession session;
  final RewardedHintAdService Function()? rewardedAdFactory;
  final Duration Function()? monotonicNow;

  @override
  State<DailyPuzzleScreen> createState() => _DailyPuzzleScreenState();
}

class _DailyPuzzleScreenState extends State<DailyPuzzleScreen> {
  DailyPuzzleAttempt? _attempt;
  DailyPuzzleScore? _completed;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.session.refreshDate();
    _completed = widget.session.todayResult;
    if (_completed != null) {
      _loading = false;
    } else {
      // Paint a loading state first. Generation is bounded and synchronous;
      // it never runs while constructing Home or reconstructs sequence history.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>(() {
          if (!mounted) return;
          try {
            _attempt = widget.session.openToday();
            _completed = widget.session.todayResult;
          } catch (_) {
            _error = 'Günün bulmacası oluşturulamadı. Lütfen tekrar deneyin.';
          }
          if (mounted) setState(() => _loading = false);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_completed != null) return DailyResultScreen(result: _completed!);
    final attempt = _attempt;
    if (_loading ||
        _error != null ||
        attempt == null ||
        !attempt.generation.isSuccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('Günün Bulmacası')),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _loading
                  ? const CircularProgressIndicator()
                  : Text(
                      _error ??
                          attempt?.generation.failureReason ??
                          'Günün bulmacası açılamadı.',
                    ),
            ),
          ),
        ),
      );
    }
    return PuzzleScreen(
      key: ValueKey(attempt.generation.puzzle!.id),
      puzzle: attempt.generation.puzzle!,
      title: 'Günün Bulmacası',
      subtitle: attempt.dateKey,
      initialLetters: attempt.letters,
      initialRevealedCells: attempt.revealedCells,
      initialElapsed: attempt.elapsed,
      initialWrongChecks: attempt.wrongChecks,
      rewardedAdFactory: widget.rewardedAdFactory,
      monotonicNow: widget.monotonicNow,
      onAttemptProgress: attempt.updateProgress,
      onElapsedChanged: attempt.checkpointElapsed,
      onCompleted: attempt.complete,
      completion: PuzzleCompletionPresentation(
        title: 'Günün bulmacası tamamlandı!',
        contentBuilder: (_) => Text(_details(attempt.result!)),
        actionLabel: 'Ana Sayfaya Dön',
        onFinished: () => Navigator.of(context).pop(),
      ),
    );
  }
}

String _details(DailyPuzzleScore result) => puzzleResultDetails(
  score: result.score,
  elapsedSeconds: result.elapsedSeconds,
  hintsUsed: result.hintsUsed,
  wrongChecks: result.wrongChecks,
);

/// An immutable completed Daily is a result, not a second scored play attempt.
class DailyResultScreen extends StatelessWidget {
  const DailyResultScreen({required this.result, super.key});
  final DailyPuzzleScore result;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Günün Bulmacası')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Günün bulmacası tamamlandı!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(result.dateKey),
            const SizedBox(height: 20),
            Text(_details(result)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ana Sayfaya Dön'),
            ),
          ],
        ),
      ),
    ),
  );
}
