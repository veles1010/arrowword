import 'package:flutter/material.dart';

import 'player_statistics.dart';
import 'puzzle_session.dart';
import 'player_puzzle_tracks.dart';
import 'puzzle_difficulty_selector.dart';
import '../features/puzzle/domain/puzzle_difficulty.dart';
import 'daily_session.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({
    this.session,
    this.tracks,
    this.dailySession,
    this.inShell = false,
    super.key,
  });

  final PuzzleSession? session;
  final PlayerPuzzleTracks? tracks;
  final DailySession? dailySession;
  final bool inShell;
  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late PuzzleDifficulty _difficulty =
      widget.tracks?.lastPlayed ?? PuzzleDifficulty.easy;
  PuzzleSession? get session => widget.session;
  PlayerPuzzleTracks? get tracks => widget.tracks;
  DailySession? get dailySession => widget.dailySession;
  bool get inShell => widget.inShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('İstatistikler'),
      automaticallyImplyLeading: !inShell,
    ),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([?session, ?tracks, ?dailySession]),
        builder: (context, _) {
          final summary =
              tracks?.summary(_difficulty) ??
              PuzzleTrackSummary.fromSession(session!);
          final statistics = PlayerStatistics.fromScores(
            completedThrough: summary.completedThrough,
            scores: summary.scores.values,
          );
          final best = statistics.bestScore;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = 12.0;
                    final cardWidth = constraints.maxWidth >= 560
                        ? (constraints.maxWidth - gap) / 2
                        : constraints.maxWidth;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (tracks != null) ...[
                          PuzzleDifficultySelector(
                            selected: _difficulty,
                            onChanged: (value) =>
                                setState(() => _difficulty = value),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          'Tamamlanan bulmacalar ve kaydedilen en iyi puanlar.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            _StatisticCard(
                              key: const ValueKey('statistics-completed'),
                              width: cardWidth,
                              icon: Icons.task_alt,
                              label: 'Tamamlanan bulmaca',
                              value: '${statistics.completedPuzzleCount}',
                            ),
                            _StatisticCard(
                              key: const ValueKey('statistics-scored'),
                              width: cardWidth,
                              icon: Icons.scoreboard_outlined,
                              label: 'Puanlanan bulmaca',
                              value: '${statistics.scoredPuzzleCount}',
                            ),
                            _StatisticCard(
                              key: const ValueKey('statistics-total'),
                              width: cardWidth,
                              icon: Icons.stars_outlined,
                              label: 'Toplam puan',
                              value: '${statistics.totalScore}',
                            ),
                            _StatisticCard(
                              key: const ValueKey('statistics-average'),
                              width: cardWidth,
                              icon: Icons.calculate_outlined,
                              label: 'Ortalama puan',
                              value:
                                  statistics.averageScore?.toStringAsFixed(1) ??
                                  'Henüz yok',
                            ),
                            _StatisticCard(
                              key: const ValueKey('statistics-best'),
                              width: cardWidth,
                              icon: Icons.emoji_events_outlined,
                              label: 'En iyi puan',
                              value:
                                  statistics.maxScore?.toString() ??
                                  'Henüz yok',
                              detail: best == null
                                  ? null
                                  : 'Bulmaca ${best.puzzleIndex} · ${best.elapsedSeconds} sn',
                            ),
                            _StatisticCard(
                              key: const ValueKey('statistics-hint-free'),
                              width: cardWidth,
                              icon: Icons.lightbulb_outline,
                              label: 'İpuçsuz tamamlanan',
                              value: '${statistics.hintFreeBestScoreCount}',
                            ),
                            _StatisticCard(
                              key: const ValueKey('statistics-error-free'),
                              width: cardWidth,
                              icon: Icons.check_circle_outline,
                              label: 'Hatasız tamamlanan',
                              value: '${statistics.errorFreeBestScoreCount}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Puan istatistikleri her bulmacanın kaydedilen en iyi sonucunu kullanır. '
                          'Puanı olmayan eski tamamlamalar yalnızca tamamlanan bulmaca sayısına eklenir.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (tracks != null)
                          Text(
                            'Puanlar aynı zorluk içinde karşılaştırılır.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (dailySession != null) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Günlük bulmacalar',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              _StatisticCard(
                                width: cardWidth,
                                icon: Icons.today,
                                label: 'Günlük tamamlanan',
                                value:
                                    '${dailySession!.statistics.totalCompletedDaily}',
                              ),
                              _StatisticCard(
                                width: cardWidth,
                                icon: Icons.local_fire_department_outlined,
                                label: 'Güncel seri',
                                value:
                                    '${dailySession!.statistics.currentStreak}',
                              ),
                              _StatisticCard(
                                width: cardWidth,
                                icon: Icons.calendar_month,
                                label: 'En uzun seri',
                                value:
                                    '${dailySession!.statistics.longestStreak}',
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    this.detail,
    super.key,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card.filled(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 4),
              Text(detail!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    ),
  );
}
