import 'package:flutter/material.dart';

import 'daily_session.dart';
import 'daily_statistics.dart';

class DailyHistoryScreen extends StatelessWidget {
  const DailyHistoryScreen({required this.session, super.key});
  final DailySession session;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Günlük Geçmiş')),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final results = session.results.values.toList()
            ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
          if (results.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Henüz tamamlanan günlük bulmaca yok.'),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatDailyDate(result.dateKey),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('${result.score} puan'),
                      Text(
                        '${formatDailyDuration(result.elapsedSeconds)} · ${result.hintsUsed} ipucu · ${result.wrongChecks} hatalı kontrol',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  );
}
