import 'package:flutter/material.dart';

import '../features/puzzle/ads/rewarded_hint_ad_service.dart';
import 'daily_session.dart';
import 'daily_statistics.dart';
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
        title: const Text('Günlük'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: daily == null
            ? const Center(
                child: Text('Günlük bulmaca bu oturumda kullanılamıyor.'),
              )
            : ListenableBuilder(
                listenable: daily,
                builder: (context, _) {
                  final result = daily.todayResult;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Günün Bulmacası',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Text(formatDailyDate(daily.dateKey)),
                        const SizedBox(height: 16),
                        if (result != null)
                          Text('Bugün tamamlandı · ${result.score} puan'),
                        if (daily.statistics.currentStreak > 0)
                          Text('${daily.statistics.currentStreak} günlük seri'),
                        const SizedBox(height: 24),
                        FilledButton(
                          key: const ValueKey('daily-landing-action'),
                          onPressed: () => _open(false),
                          child: Text(
                            result != null
                                ? 'Sonucu Gör'
                                : daily.hasCurrentProgress
                                ? 'Devam Et'
                                : 'Oyna',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => _open(true),
                          child: const Text('Günlük Geçmiş'),
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
