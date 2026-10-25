import 'dart:async';

import 'package:arrowword/features/puzzle/ads/ad_privacy_options_tile.dart';
import 'package:arrowword/features/puzzle/ads/ads_privacy.dart';
import 'package:arrowword/features/puzzle/ads/google_rewarded_hint_ad_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Consent implements AdsConsentGateway {
  bool allowed = false;
  bool required = false;
  bool failRefresh = false;
  int refreshes = 0;
  int forms = 0;
  Completer<void>? refreshGate;
  Completer<void>? formGate;

  @override
  Future<void> refresh() async {
    refreshes++;
    await refreshGate?.future;
    if (failRefresh) throw StateError('offline');
  }

  @override
  Future<bool> canRequestAds() async => allowed;

  @override
  Future<bool> privacyOptionsRequired() async => required;

  @override
  Future<void> showPrivacyOptions() async {
    forms++;
    await formGate?.future;
  }
}

void main() {
  test('concurrent callers share consent and can retry after a denial', () async {
    final gateway = _Consent()..refreshGate = Completer<void>();
    final privacy = AdsPrivacyController(gateway);
    addTearDown(privacy.dispose);
    final first = privacy.ensureReady();
    expect(identical(first, privacy.ensureReady()), isTrue);
    expect(privacy.canRequestAds, isFalse);
    gateway.refreshGate!.complete();
    await first;
    expect(gateway.refreshes, 1);
    expect(privacy.canRequestAds, isFalse);
    gateway.allowed = true;
    await privacy.ensureReady();
    expect(gateway.refreshes, 2);
    expect(privacy.canRequestAds, isTrue);
  });

  test('update error uses UMP eligibility from a previous session', () async {
    final gateway = _Consent()
      ..allowed = true
      ..failRefresh = true;
    final privacy = AdsPrivacyController(gateway);
    addTearDown(privacy.dispose);
    await privacy.ensureReady();
    expect(privacy.canRequestAds, isTrue);
  });

  test('privacy form blocks ads, shares pending work and rereads consent', () async {
    final gateway = _Consent()
      ..allowed = true
      ..required = true
      ..formGate = Completer<void>();
    final privacy = AdsPrivacyController(gateway);
    addTearDown(privacy.dispose);
    await privacy.ensureReady();
    final form = privacy.showPrivacyOptions();
    expect(privacy.canRequestAds, isFalse);
    expect(privacy.revision, 1);
    expect(identical(form, privacy.ensureReady()), isTrue);
    gateway.allowed = false;
    gateway.formGate!.complete();
    await form;
    expect(gateway.forms, 1);
    expect(gateway.refreshes, 1);
    expect(privacy.isBusy, isFalse);
    expect(privacy.canRequestAds, isFalse);
  });

  testWidgets('no ad request or SDK startup without consent eligibility', (tester) async {
    final privacy = AdsPrivacyController(_Consent());
    var starts = 0;
    var loads = 0;
    final service = GoogleRewardedHintAdService(
      privacy: privacy,
      initialize: () async { starts++; },
      loadAd: (_) async { loads++; },
    );
    service.preload();
    await tester.pump();
    expect(starts, 0);
    expect(loads, 0);
    expect(service.isLoading, isFalse);
    service.dispose();
    privacy.dispose();
  });

  testWidgets('privacy entry appears only when required by UMP', (tester) async {
    final gateway = _Consent()..allowed = true;
    final privacy = AdsPrivacyController(gateway);
    await privacy.ensureReady();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AdPrivacyOptionsTile(controller: privacy)),
    ));
    expect(find.byKey(const ValueKey('ad-privacy-options')), findsNothing);
    gateway.required = true;
    gateway.allowed = false;
    // Force a fresh eligibility check as if consent had not been obtained yet.
    final requiredPrivacy = AdsPrivacyController(gateway);
    await requiredPrivacy.ensureReady();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AdPrivacyOptionsTile(controller: requiredPrivacy)),
    ));
    expect(find.byKey(const ValueKey('ad-privacy-options')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    privacy.dispose();
    requiredPrivacy.dispose();
  });

  test('debug/profile use samples and mobile release uses production units', () {
    expect(rewardedHintAdUnitId(
      platform: TargetPlatform.iOS, releaseMode: false, iosUnitId: 'real',
    ), 'ca-app-pub-3940256099942544/1712485313');
    expect(rewardedHintAdUnitId(
      platform: TargetPlatform.iOS, releaseMode: true,
    ), 'ca-app-pub-2059856067409159/9548444613');
    expect(rewardedHintAdUnitId(
      platform: TargetPlatform.android, releaseMode: true,
    ), 'ca-app-pub-2059856067409159/6285655323');
    expect(rewardedHintAdUnitId(
      platform: TargetPlatform.android, releaseMode: false,
      androidUnitId: 'real-android',
    ), 'ca-app-pub-3940256099942544/5224354917');
    expect(rewardedHintAdUnitId(
      platform: TargetPlatform.android, releaseMode: true,
      androidUnitId: 'override-android',
    ), 'override-android');
    expect(rewardedHintAdUnitId(
      platform: TargetPlatform.iOS, releaseMode: true, iosUnitId: 'override-ios',
    ), 'override-ios');
  });
}
