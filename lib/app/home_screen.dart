import 'package:flutter/material.dart';

import '../features/puzzle/ads/rewarded_hint_ad_service.dart';

import 'puzzle_session.dart';
import '../features/puzzle/domain/normal_puzzle_contract.dart';
import 'player_puzzle_tracks.dart';
import 'puzzle_progression_screen.dart';
import 'daily_session.dart';
import 'daily_puzzle_screen.dart';
import 'statistics_screen.dart';
import 'daily_history_screen.dart';
import 'daily_statistics.dart';
import 'app_settings.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    this.session,
    this.tracks,
    this.onChooseDifficulty,
    required this.puzzleBuilder,
    this.rewardedAdFactory,
    this.dailySession,
    this.settings,
    this.inShell = false,
    super.key,
  });
  final PuzzleSession? session;
  final PlayerPuzzleTracks? tracks;
  final VoidCallback? onChooseDifficulty;
  final DailySession? dailySession;
  final AppSettings? settings;
  final bool inShell;
  final WidgetBuilder puzzleBuilder;
  final RewardedHintAdService Function()? rewardedAdFactory;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    widget.dailySession?.refreshDate();
    WidgetsBinding.instance.addObserver(this);
  }

  void _returnedHome() {
    if (!mounted) return;
    final tracks = widget.tracks;
    if (tracks != null) tracks.refresh(tracks.lastPlayed);
    widget.dailySession?.refreshDate();
    setState(() {});
  }

  Future<void> _openStatistics() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => StatisticsScreen(
          session: widget.session,
          tracks: widget.tracks,
          dailySession: widget.dailySession,
        ),
      ),
    );
    _returnedHome();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.dailySession?.refreshDate();
  }

  Future<void> _openDaily() async {
    final daily = widget.dailySession;
    if (daily == null) return;
    daily.refreshDate();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => DailyPuzzleScreen(
          session: daily,
          rewardedAdFactory: widget.rewardedAdFactory,
        ),
      ),
    );
    _returnedHome();
  }

  Future<void> _openPuzzle() async {
    await Navigator.of(context)
        .push<void>(MaterialPageRoute(builder: widget.puzzleBuilder));
    // Letter changes do not notify the whole session. Refresh the CTA on return.
    _returnedHome();
  }

  Future<void> _openProgression() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PuzzleProgressionScreen(
          session: widget.session,
          puzzleBuilder: widget.puzzleBuilder,
          rewardedAdFactory: widget.rewardedAdFactory,
        ),
      ),
    );
    _returnedHome();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      if (widget.session != null) widget.session!,
      if (widget.tracks != null) widget.tracks!,
      if (widget.dailySession != null) widget.dailySession!,
    ]),
    builder: (context, _) {
      final tracks = widget.tracks;
      final summary =
          tracks?.summary(tracks.lastPlayed) ??
          PuzzleTrackSummary.fromSession(widget.session!);
      final fresh = summary.isFresh;
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !widget.inShell,
          title: const Text('Arrowword'),
          actions: [
            if (widget.settings != null)
              IconButton(
                tooltip: 'Ayarlar',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) =>
                          SettingsScreen(settings: widget.settings!),
                    ),
                  );
                  _returnedHome();
                },
              ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        summary.isComplete
                            ? (tracks?.lastPlayed ?? widget.session!.difficulty)
                                  .turkishLabel
                            : '${tracks == null ? '' : '${tracks.lastPlayed.turkishLabel} · '}Bulmaca ${summary.displayIndex}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        summary.isComplete
                            ? '${summary.completedCount} / $normalPuzzleCount tamamlandı'
                            : summary.completedCount == 0
                            ? 'Henüz tamamlanan bulmaca yok'
                            : '${summary.completedCount} bulmaca tamamlandı',
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed:
                            tracks != null || widget.session!.current.isSuccess
                            ? summary.isComplete
                                  ? (widget.onChooseDifficulty ??
                                        _openProgression)
                                  : _openPuzzle
                            : null,
                        child: Text(
                          summary.isComplete
                              ? 'Bulmacaları Gör'
                              : fresh
                              ? 'Başla'
                              : 'Devam Et',
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.onChooseDifficulty != null)
                        TextButton(
                          onPressed: widget.onChooseDifficulty,
                          child: const Text('Zorluk Seç'),
                        ),
                      if (!widget.inShell)
                        TextButton(
                          onPressed: _openProgression,
                          child: const Text('Bulmacalar'),
                        ),
                      if (!widget.inShell)
                        TextButton(
                          onPressed: _openStatistics,
                          child: const Text('İstatistikler'),
                        ),
                      if (widget.dailySession != null) ...[
                        const SizedBox(height: 12),
                        _dailyCard(context, widget.dailySession!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _dailyCard(BuildContext context, DailySession daily) {
    final result = daily.todayResult;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Günün Bulmacası',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                result != null
                    ? 'Bugün tamamlandı · ${result.score} puan'
                    : formatDailyDate(daily.dateKey),
              ),
              if (daily.statistics.currentStreak > 0)
                Text('${daily.statistics.currentStreak} günlük seri'),
              if (!widget.inShell)
                TextButton(
                  onPressed: () async {
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => DailyHistoryScreen(session: daily),
                      ),
                    );
                    _returnedHome();
                  },
                  child: const Text('Günlük Geçmiş'),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const ValueKey('daily-action'),
                  onPressed: _openDaily,
                  child: Text(
                    result != null
                        ? 'Sonucu Gör'
                        : daily.hasCurrentProgress
                        ? 'Devam Et'
                        : 'Oyna',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
