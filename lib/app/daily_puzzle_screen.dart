import '../l10n/ui_strings.dart';
import '../l10n/clue_presentation.dart';

import 'package:flutter/material.dart';

import '../features/puzzle/ads/rewarded_hint_ad_service.dart';
import '../features/puzzle/presentation/puzzle_completion.dart';
import '../features/puzzle/presentation/puzzle_screen.dart';
import 'daily_session.dart';
import 'daily_history_screen.dart';
import 'daily_result_share_service.dart';

/// Daily owns a separate resumable attempt, never a normal progression session.
class DailyPuzzleScreen extends StatefulWidget {
  const DailyPuzzleScreen({
    required this.session,
    this.rewardedAdFactory,
    this.monotonicNow,
    this.shareService,
    super.key,
  });

  final DailySession session;
  final RewardedHintAdService Function()? rewardedAdFactory;
  final Duration Function()? monotonicNow;
  final DailyResultShareService? shareService;

  @override
  State<DailyPuzzleScreen> createState() => _DailyPuzzleScreenState();
}

class _DailyPuzzleScreenState extends State<DailyPuzzleScreen> {
  DailyPuzzleAttempt? _attempt;
  DailyPuzzleScore? _completed;
  bool _error = false;
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
            _error = true;
          }
          if (mounted) setState(() => _loading = false);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_completed != null) {
      return DailyResultScreen(
        result: _completed!,
        session: widget.session,
        shareService: widget.shareService,
      );
    }
    final attempt = _attempt;
    if (_loading ||
        _error ||
        attempt == null ||
        !attempt.generation.isSuccess) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.dailyTitle)),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _loading
                  ? CircularProgressIndicator(
                      semanticsLabel: context.l10n.dailyPreparing,
                    )
                  : Text(context.l10n.dailyGenerationFailed),
            ),
          ),
        ),
      );
    }
    return CluePackGate(
      child: PuzzleScreen(
        key: ValueKey(attempt.generation.puzzle!.id),
        puzzle: attempt.generation.puzzle!,
        title: context.l10n.dailyTitle,
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
          title: context.l10n.dailyCompleted,
          contentBuilder: (dialogContext) =>
              Text(_details(dialogContext, attempt.result!)),
          actionLabel: context.l10n.returnHome,
          onFinished: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

String _details(BuildContext context, DailyPuzzleScore result) =>
    puzzleResultDetails(
      strings: context.l10n,
      score: result.score,
      elapsedSeconds: result.elapsedSeconds,
      hintsUsed: result.hintsUsed,
      wrongChecks: result.wrongChecks,
    );

/// An immutable completed Daily is a result, not a second scored play attempt.
class DailyResultScreen extends StatefulWidget {
  const DailyResultScreen({
    required this.result,
    this.session,
    this.shareService,
    super.key,
  });
  final DailyPuzzleScore result;
  final DailySession? session;
  final DailyResultShareService? shareService;

  @override
  State<DailyResultScreen> createState() => _DailyResultScreenState();
}

class _DailyResultScreenState extends State<DailyResultScreen> {
  bool _sharing = false;
  int get _streak => widget.session?.statistics.currentStreak ?? 0;

  Future<void> _share(BuildContext buttonContext) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final box = buttonContext.findRenderObject() as RenderBox?;
    try {
      await (widget.shareService ?? NativeDailyResultShareService()).share(
        dailyResultShareText(
          widget.result,
          streak: _streak,
          strings: context.l10n,
        ),
        origin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.shareError)));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.dailyTitle)),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.dailyCompleted,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(localizedDailyDate(widget.result.dateKey, context.l10n)),
            const SizedBox(height: 20),
            Text(_details(context, widget.result)),
            if (_streak > 0) Text(context.l10n.streakDays(_streak)),
            Builder(
              builder: (buttonContext) => OutlinedButton.icon(
                onPressed: _sharing ? null : () => _share(buttonContext),
                icon: const Icon(Icons.share_outlined),
                label: Text(context.l10n.share),
              ),
            ),
            if (widget.session != null)
              TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) =>
                        DailyHistoryScreen(session: widget.session!),
                  ),
                ),
                child: Text(context.l10n.dailyHistory),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.returnHome),
            ),
          ],
        ),
      ),
    ),
  );
}
