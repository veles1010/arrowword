import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/puzzle/ads/rewarded_hint_ad_service.dart';

import 'puzzle_session.dart';
import 'app_shell.dart';
import 'daily_session.dart';
import 'app_settings.dart';
import 'arrowword_theme.dart';
import '../features/puzzle/presentation/puzzle_screen.dart';
import '../features/puzzle/presentation/puzzle_completion.dart';
import '../features/puzzle/domain/puzzle_score.dart';

class ArrowwordApp extends StatelessWidget {
  const ArrowwordApp({
    required this.session,
    this.openPuzzleDirectly = false,
    this.developmentOverride = false,
    this.rewardedAdFactory,
    this.dailySession,
    this.settings,
    super.key,
  });
  final PuzzleSession session;
  final DailySession? dailySession;
  final AppSettings? settings;
  final RewardedHintAdService Function()? rewardedAdFactory;
  final bool openPuzzleDirectly;
  final bool developmentOverride;
  @override
  Widget build(BuildContext context) {
    if (developmentOverride && session.store != null) {
      throw ArgumentError(
        'Development override requires a memory-only session.',
      );
    }
    return ListenableBuilder(
      listenable: settings ?? session,
      builder: (context, _) => MaterialApp(
        title: 'Arrowword',
        debugShowCheckedModeBanner: false,
        navigatorObservers: [puzzleRouteObserver],
        theme: ArrowwordTheme.light(),
        darkTheme: ArrowwordTheme.dark(),
        themeMode: settings?.themeMode ?? ThemeMode.system,
        home:
            developmentOverride ||
                openPuzzleDirectly ||
                !session.current.isSuccess
            ? _PuzzleFlow(
                session: session,
                rewardedAdFactory: rewardedAdFactory,
                developmentOverride: developmentOverride,
              )
            : AppShell(
                session: session,
                settings: settings,
                dailySession: dailySession,
                rewardedAdFactory: rewardedAdFactory,
                puzzleBuilder: (_) => _PuzzleFlow(
                  session: session,
                  rewardedAdFactory: rewardedAdFactory,
                ),
              ),
      ),
    );
  }
}

class _PuzzleFlow extends StatelessWidget {
  const _PuzzleFlow({
    required this.session,
    this.rewardedAdFactory,
    this.developmentOverride = false,
  });
  final PuzzleSession session;
  final RewardedHintAdService Function()? rewardedAdFactory;
  final bool developmentOverride;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) {
      final generation = session.current;
      return generation.isSuccess
          ? PuzzleScreen(
              key: ValueKey(generation.puzzle!.id),
              puzzle: generation.puzzle!,
              rewardedAdFactory: rewardedAdFactory,
              title: developmentOverride
                  ? '${session.difficulty.turkishLabel} · Bulmaca ${generation.puzzleIndex}'
                  : 'Bulmaca ${generation.puzzleIndex}',
              subtitle: developmentOverride
                  ? 'Geliştirme · İlerleme kaydedilmez'
                  : null,
              onNextPuzzle: developmentOverride ? null : session.nextPuzzle,
              initialLetters: session.letters,
              initialRevealedCells: session.revealedCells,
              initialElapsed: session.elapsed,
              initialWrongChecks: session.wrongChecks,
              attemptFinalized:
                  session.completedThrough >= generation.puzzleIndex,
              onAttemptProgress: (letters, revealed, elapsed, checks) {
                if (session.current.puzzleIndex == generation.puzzleIndex) {
                  session.updateAttemptProgress(
                    letters,
                    revealed,
                    elapsed,
                    checks,
                  );
                }
              },
              onElapsedChanged: (elapsed) {
                // Disposal of N happens after the session has already moved to N+1.
                if (session.current.puzzleIndex == generation.puzzleIndex) {
                  session.checkpointElapsed(elapsed);
                }
              },
              scoreResult: () => session.currentScore,
              onCompleted: developmentOverride
                  ? null
                  : session.recognizeCompletion,
              completion: developmentOverride
                  ? PuzzleCompletionPresentation(
                      title: 'Bulmaca tamamlandı!',
                      contentBuilder: (_) {
                        final score = CompletedPuzzleScore.calculate(
                          puzzleIndex: generation.puzzleIndex,
                          elapsedSeconds: session.elapsed.inSeconds,
                          hintsUsed: session.hintsUsed,
                          wrongChecks: session.wrongChecks,
                        );
                        return Text(
                          puzzleResultDetails(
                            score: score.score,
                            elapsedSeconds: score.elapsedSeconds,
                            hintsUsed: score.hintsUsed,
                            wrongChecks: score.wrongChecks,
                          ),
                        );
                      },
                      actionLabel: 'Oturumu Kapat',
                      onFinished: () {
                        SystemNavigator.pop();
                      },
                    )
                  : null,
            )
          : Scaffold(
              appBar: AppBar(title: const Text('Bulmaca')),
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Bulmaca oluşturulamadı. Lütfen tekrar deneyin.',
                    ),
                  ),
                ),
              ),
            );
    },
  );
}
