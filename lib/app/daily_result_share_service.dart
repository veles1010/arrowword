import 'dart:ui';

import 'package:share_plus/share_plus.dart';

import 'daily_progress_store.dart';
import 'daily_statistics.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/generated/app_localizations_tr.dart';
import '../l10n/ui_strings.dart';

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

String dailyResultShareText(
  DailyPuzzleScore result, {
  required int streak,
  AppLocalizations? strings,
}) {
  final copy = strings ?? AppLocalizationsTr();
  return copy.dailyShare(
    localizedDailyDate(result.dateKey, copy),
    result.score,
    formatDailyDuration(result.elapsedSeconds),
    result.hintsUsed,
    result.wrongChecks,
    streak > 0 ? 'yes' : 'no',
    streak,
  );
}
