import '../l10n/ui_strings.dart';

import 'package:flutter/material.dart';

import '../features/puzzle/ads/rewarded_hint_ad_service.dart';
import 'daily_session.dart';
import 'daily_puzzle_screen.dart';
import 'daily_history_screen.dart';

class DailyLandingScreen extends StatefulWidget {
  const DailyLandingScreen({this.session, this.rewardedAdFactory, super.key});
  final DailySession? session;
  final RewardedHintAdService Function()? rewardedAdFactory;
  @override
  State<DailyLandingScreen> createState() => _DailyLandingScreenState();
}

class _DailyLandingScreenState extends State<DailyLandingScreen> {
  Future<void> _open(bool history) async {
    final daily = widget.session;
    if (daily == null) return;
    daily.refreshDate();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => history
            ? DailyHistoryScreen(session: daily)
            : DailyPuzzleScreen(
                session: daily,
                rewardedAdFactory: widget.rewardedAdFactory,
              ),
      ),
    );
    if (mounted) {
      daily.refreshDate();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final daily = widget.session;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.daily),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: daily == null
            ? Center(child: Text(context.l10n.dailyUnavailable))
            : ListenableBuilder(
                listenable: daily,
                builder: (context, _) {
                  final result = daily.todayResult;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          context.l10n.dailyTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(localizedDailyDate(daily.dateKey, context.l10n)),
                        const SizedBox(height: 16),
                        if (result != null)
                          Text(context.l10n.todayCompleted(result.score)),
                        if (daily.statistics.currentStreak > 0)
                          Text(
                            context.l10n.streakDays(
                              daily.statistics.currentStreak,
                            ),
                          ),
                        const SizedBox(height: 24),
                        FilledButton(
                          key: const ValueKey('daily-landing-action'),
                          onPressed: () => _open(false),
                          child: Text(
                            result != null
                                ? context.l10n.seeResult
                                : daily.hasCurrentProgress
                                ? context.l10n.continueGame
                                : context.l10n.play,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => _open(true),
                          child: Text(context.l10n.dailyHistory),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
