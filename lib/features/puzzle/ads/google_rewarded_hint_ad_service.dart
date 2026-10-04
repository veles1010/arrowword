import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'rewarded_hint_ad_service.dart';

bool get _supported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

Future<void>? _initialization;
Future<void> initializeHintAds() async {
  if (!_supported) return;
  await (_initialization ??= MobileAds.instance.initialize().then<void>(
    (_) {},
  ));
}

RewardedHintAdService createHintAdService() =>
    _supported ? GoogleRewardedHintAdService() : UnavailableHintAdService();

/// TEST ONLY: sample units must be replaced and consent configured before release.
class GoogleRewardedHintAdService extends RewardedHintAdService {
  RewardedAd? _ad;
  RewardedAd? _showing;
  Completer<HintAdResult>? _completion;
  bool _loading = false;
  bool _disposed = false;
  @override
  bool get isReady => _ad != null;
  @override
  bool get isLoading => _loading;
  @override
  void preload() {
    if (_disposed || _loading || _ad != null || _showing != null) return;
    _loading = true;
    notifyListeners();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      await initializeHintAds();
      if (_disposed) return;
      await RewardedAd.load(
        adUnitId: defaultTargetPlatform == TargetPlatform.android
            ? 'ca-app-pub-3940256099942544/5224354917'
            : 'ca-app-pub-3940256099942544/1712485313',
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (_disposed) {
              ad.dispose();
              return;
            }
            _ad = ad;
            _loading = false;
            notifyListeners();
          },
          onAdFailedToLoad: (_) => _loadFailed(),
        ),
      );
    } catch (_) {
      _loadFailed();
    }
  }

  void _loadFailed() {
    if (_disposed) return;
    _loading = false;
    notifyListeners(); // Retry only on a later player request, never a tight loop.
  }

  @override
  Future<HintAdResult> show() async {
    final ad = _ad;
    if (_disposed || ad == null) return HintAdResult.unavailable;
    _ad = null; // A consumed instance must never be reused.
    _showing = ad;
    final completion = Completer<HintAdResult>();
    _completion = completion;
    var earned = false;
    void finish(HintAdResult result) {
      if (completion.isCompleted) return;
      completion.complete(result);
      ad.dispose();
      _showing = null;
      _completion = null;
      if (!_disposed) preload();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) =>
          finish(earned ? HintAdResult.earned : HintAdResult.dismissed),
      onAdFailedToShowFullScreenContent: (_, _) => finish(HintAdResult.failed),
    );
    notifyListeners();
    try {
      await ad.show(
        onUserEarnedReward: (_, _) {
          if (!completion.isCompleted && !_disposed) earned = true;
        },
      );
    } catch (_) {
      finish(HintAdResult.failed);
    }
    return completion.future;
  }

  @override
  void dispose() {
    _disposed = true;
    _ad?.dispose();
    _showing?.dispose();
    if (_completion != null && !_completion!.isCompleted) {
      _completion!.complete(HintAdResult.failed);
    }
    super.dispose();
  }
}
