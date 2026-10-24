import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'rewarded_hint_ad_service.dart';
import 'ads_privacy.dart';

bool get _supported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// One shared readiness Future, including failure; never reinitializes per route.
class HintAdsInitialization {
  HintAdsInitialization(this.initialize);
  final Future<void> Function() initialize;
  Future<void>? _pending;
  Future<void> ensureReady() => _pending ??= Future<void>.sync(initialize);
}

final _initialization = HintAdsInitialization(
  () => MobileAds.instance.initialize().then<void>((_) {}),
);

Future<void> initializeHintAds() async {
  if (!_supported) return;
  await hintAdsPrivacy.ensureReady();
  if (!hintAdsPrivacy.canRequestAds) {
    throw StateError('Ad consent is not ready');
  }
  await _initialization.ensureReady();
}

/// The first frame never waits on ads. Tests inject a local readiness boundary.
void scheduleHintAdsInitialization({HintAdsInitialization? initialization}) {
  if (initialization == null && !_supported) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(
      (initialization?.ensureReady() ?? initializeHintAds()).catchError(
        (Object _) {},
      ),
    );
  });
}

RewardedHintAdService createHintAdService() =>
    _supported ? GoogleRewardedHintAdService() : UnavailableHintAdService();

String rewardedHintAdUnitId({
  required TargetPlatform platform,
  required bool releaseMode,
  String iosUnitId = const String.fromEnvironment(
    'ADMOB_IOS_REWARDED_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-2059856067409159/9548444613',
  ),
}) => platform == TargetPlatform.iOS
    ? (releaseMode ? iosUnitId : 'ca-app-pub-3940256099942544/1712485313')
    : 'ca-app-pub-3940256099942544/5224354917';

/// Debug/profile use sample units; iOS release uses the configured real unit.
class GoogleRewardedHintAdService extends RewardedHintAdService {
  GoogleRewardedHintAdService({
    Future<void> Function()? initialize,
    this.loadAd,
    AdsPrivacyController? privacy,
  }) : _initialize = initialize ?? initializeHintAds,
       _privacy = privacy ?? (initialize == null ? hintAdsPrivacy : null) {
    _consentRevision = _privacy?.revision ?? 0;
    _privacy?.addListener(_privacyChanged);
  }
  final AdsPrivacyController? _privacy;
  late int _consentRevision;
  int _generation = 0;

  void _privacyChanged() {
    final privacy = _privacy!;
    if (privacy.revision != _consentRevision) {
      _consentRevision = privacy.revision;
      _generation++;
      _ad?.dispose();
      _ad = null;
      _loading = false;
      notifyListeners();
    }
    if (privacy.canRequestAds) preload();
  }
  final Future<void> Function() _initialize;
  final Future<void> Function(RewardedAdLoadCallback)? loadAd;
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
    final generation = _generation;
    try {
      await _privacy?.ensureReady();
      if (_privacy != null && !_privacy.canRequestAds) {
        throw StateError('Ad consent is not ready');
      }
      await _initialize();
      if (_disposed || generation != _generation) return;
      final callback = RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (_disposed || generation != _generation) {
            ad.dispose();
            return;
          }
          _ad = ad;
          _loading = false;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          debugPrint('[Ads] Rewarded load failed: ${error.domain} '
              '${error.code}: ${error.message}');
          _loadFailed(generation);
        },
      );
      if (loadAd case final load?) {
        await load(callback);
      } else {
        await RewardedAd.load(
          adUnitId: rewardedHintAdUnitId(
            platform: defaultTargetPlatform,
            releaseMode: kReleaseMode,
          ),
          request: const AdRequest(),
          rewardedAdLoadCallback: callback,
        );
      }
    } catch (error) {
      debugPrint('[Ads] Rewarded initialization failed: $error');
      _loadFailed(generation);
    }
  }

  void _loadFailed(int generation) {
    if (_disposed || generation != _generation) return;
    _loading = false;
    notifyListeners(); // Retry only on a later player request, never a tight loop.
  }

  @override
  Future<HintAdResult> show() async {
    final ad = _ad;
    if (_disposed || ad == null ||
        (_privacy != null && !_privacy.canRequestAds)) {
      return HintAdResult.unavailable;
    }
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
    _privacy?.removeListener(_privacyChanged);
    _ad?.dispose();
    _showing?.dispose();
    if (_completion != null && !_completion!.isCompleted) {
      _completion!.complete(HintAdResult.failed);
    }
    super.dispose();
  }
}

