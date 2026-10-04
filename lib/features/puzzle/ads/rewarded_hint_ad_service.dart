import 'package:flutter/foundation.dart';

enum HintAdResult { earned, dismissed, failed, unavailable }

abstract class RewardedHintAdService extends ChangeNotifier {
  bool get isReady;
  bool get isLoading;
  void preload();
  Future<HintAdResult> show();
}

/// Safe default for unsupported platforms and tests without ad injection.
class UnavailableHintAdService extends RewardedHintAdService {
  @override
  bool get isReady => false;
  @override
  bool get isLoading => false;
  @override
  void preload() {}
  @override
  Future<HintAdResult> show() async => HintAdResult.unavailable;
}

class FakeRewardedHintAdService extends RewardedHintAdService {
  FakeRewardedHintAdService({
    this.ready = true,
    this.loading = false,
    this.result = HintAdResult.earned,
  });
  bool ready;
  bool loading;
  final HintAdResult result;
  int shows = 0;
  @override
  bool get isReady => ready;
  @override
  bool get isLoading => loading;
  @override
  void preload() {}
  @override
  Future<HintAdResult> show() async {
    if (!ready) return HintAdResult.unavailable;
    shows++;
    return result;
  }
}
