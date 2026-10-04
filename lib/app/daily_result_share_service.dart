import 'dart:ui';

import 'package:share_plus/share_plus.dart';

import 'daily_progress_store.dart';
import 'daily_statistics.dart';

abstract class DailyResultShareService {
  Future<void> share(String text, {Rect? origin});
}

class NativeDailyResultShareService implements DailyResultShareService {
  @override
  Future<void> share(String text, {Rect? origin}) async {
    await SharePlus.instance.share(
      ShareParams(text: text, sharePositionOrigin: origin),
    );
  }
}

String dailyResultShareText(DailyPuzzleScore result, {required int streak}) =>
    'Arrowword — Günün Bulmacası\n${formatDailyDate(result.dateKey)}\n\n'
    'Puan: ${result.score}\nSüre: ${formatDailyDuration(result.elapsedSeconds)}\n'
    'İpucu: ${result.hintsUsed}\nHatalı kontrol: ${result.wrongChecks}'
    '${streak > 0 ? '\nSeri: $streak gün' : ''}';
