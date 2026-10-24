import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

abstract interface class AdsConsentGateway {
  Future<void> refresh();
  Future<bool> canRequestAds();
  Future<bool> privacyOptionsRequired();
  Future<void> showPrivacyOptions();
}

class GoogleAdsConsentGateway implements AdsConsentGateway {
  @override
  Future<void> refresh() {
    final completion = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => ConsentForm.loadAndShowConsentFormIfRequired((error) {
        if (error == null) {
          completion.complete();
        } else {
          completion.completeError(StateError(error.message));
        }
      }),
      (error) => completion.completeError(StateError(error.message)),
    );
    return completion.future;
  }

  @override
  Future<bool> canRequestAds() => ConsentInformation.instance.canRequestAds();

  @override
  Future<bool> privacyOptionsRequired() async =>
      await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
      PrivacyOptionsRequirementStatus.required;

  @override
  Future<void> showPrivacyOptions() {
    final completion = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((error) {
      if (error == null) {
        completion.complete();
      } else {
        completion.completeError(StateError(error.message));
      }
    });
    return completion.future;
  }
}

/// Shares consent work across startup and puzzle routes. Eligibility always
/// comes from UMP; an update error can still use UMP's previous-session consent.
class AdsPrivacyController extends ChangeNotifier {
  AdsPrivacyController(this.gateway);
  final AdsConsentGateway gateway;
  Future<void>? _pending;
  bool _allowed = false;
  bool _required = false;
  bool _busy = false;
  int _revision = 0;

  bool get canRequestAds => _allowed && !_busy;
  bool get privacyOptionsRequired => _required;
  bool get isBusy => _busy;
  int get revision => _revision;

  Future<void> ensureReady() {
    if (canRequestAds) return Future<void>.value();
    return _pending ??= _refresh().whenComplete(() {
      _pending = null;
    });
  }

  Future<void> _refresh() async {
    _busy = true;
    try {
      await gateway.refresh();
    } catch (error) {
      debugPrint('[Ads] Consent update failed: $error');
    }
    await _readState();
    _busy = false;
    notifyListeners();
  }

  Future<void> _readState() async {
    try {
      _allowed = await gateway.canRequestAds();
      _required = await gateway.privacyOptionsRequired();
    } catch (error) {
      _allowed = false;
      debugPrint('[Ads] Consent status unavailable: $error');
    }
  }

  Future<void> showPrivacyOptions() {
    if (_busy || !_required) return _pending ?? Future<void>.value();
    return _pending ??= _showPrivacyOptions().whenComplete(() {
      _pending = null;
    });
  }

  Future<void> _showPrivacyOptions() async {
    _busy = true;
    _revision++;
    notifyListeners(); // Discard cached ads before changing consent.
    try {
      await gateway.showPrivacyOptions();
    } finally {
      await _readState();
      _busy = false;
      notifyListeners();
    }
  }
}

final hintAdsPrivacy = AdsPrivacyController(GoogleAdsConsentGateway());
