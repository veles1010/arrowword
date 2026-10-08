import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arrowword/features/puzzle/ads/google_rewarded_hint_ad_service.dart';
import 'package:arrowword/l10n/language_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'readiness shares one initialization across concurrent and later callers',
    () async {
      var calls = 0;
      final ready = Completer<void>();
      final initialization = HintAdsInitialization(() {
        calls++;
        return ready.future;
      });
      final first = initialization.ensureReady();
      expect(identical(first, initialization.ensureReady()), isTrue);
      expect(calls, 1);
      ready.complete();
      await first;
      await initialization.ensureReady();
      expect(calls, 1);
    },
  );

  test(
    'synchronous initialization failure is cached, not repeatedly retried',
    () async {
      var calls = 0;
      final initialization = HintAdsInitialization(() {
        calls++;
        throw StateError('offline');
      });
      await expectLater(initialization.ensureReady(), throwsStateError);
      await expectLater(initialization.ensureReady(), throwsStateError);
      expect(calls, 1);
    },
  );

  testWidgets(
    'first Flutter frame renders while ad initialization is pending',
    (tester) async {
      final ready = Completer<void>();
      var calls = 0;
      final initialization = HintAdsInitialization(() {
        calls++;
        return ready.future;
      });
      scheduleHintAdsInitialization(initialization: initialization);
      scheduleHintAdsInitialization(initialization: initialization);
      expect(calls, 0);
      await tester.pumpWidget(const MaterialApp(home: Text('usable offline')));
      expect(find.text('usable offline'), findsOneWidget);
      expect(calls, 1);
      expect(ready.isCompleted, isFalse);
      ready.complete();
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'startup initialization failure does not remove or crash the app',
    (tester) async {
      final ready = Completer<void>();
      scheduleHintAdsInitialization(
        initialization: HintAdsInitialization(() => ready.future),
      );
      await tester.pumpWidget(const MaterialApp(home: Text('usable offline')));
      ready.completeError(StateError('SDK unavailable'));
      await tester.pump();
      expect(find.text('usable offline'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('rewarded load waits for the same SDK readiness future', (
    tester,
  ) async {
    final ready = Completer<void>();
    var starts = 0, loads = 0;
    final initialization = HintAdsInitialization(() {
      starts++;
      return ready.future;
    });
    final services = List.generate(
      2,
      (_) => GoogleRewardedHintAdService(
        initialize: initialization.ensureReady,
        loadAd: (_) async {
          loads++;
          throw StateError('no network');
        },
      ),
    );
    for (final service in services) {
      service.preload();
    }
    await tester.pump();
    expect(starts, 1);
    expect(loads, 0);
    expect(services.every((s) => s.isLoading), isTrue);
    ready.complete();
    await tester.pump();
    expect(loads, 2);
    expect(starts, 1);
    expect(services.every((s) => !s.isLoading && !s.isReady), isTrue);
    for (final service in services) {
      service.dispose();
    }
  });

  testWidgets('SDK failure prevents all rewarded requests safely', (
    tester,
  ) async {
    var loads = 0;
    final initialization = HintAdsInitialization(
      () async => throw StateError('offline'),
    );
    final service = GoogleRewardedHintAdService(
      initialize: initialization.ensureReady,
      loadAd: (_) async {
        loads++;
      },
    );
    service.preload();
    await tester.pump();
    expect(loads, 0);
    expect(service.isLoading, isFalse);
    expect(service.isReady, isFalse);
    service.dispose();
  });

  testWidgets('disposing while initialization waits prevents a later load', (
    tester,
  ) async {
    final ready = Completer<void>();
    var loads = 0;
    final service = GoogleRewardedHintAdService(
      initialize: () => ready.future,
      loadAd: (_) async {
        loads++;
      },
    );
    service.preload();
    service.dispose();
    ready.complete();
    await tester.pump();
    expect(loads, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('repeated preloads cannot create duplicate pending loads', (
    tester,
  ) async {
    final ready = Completer<void>();
    var loads = 0;
    final initialization = HintAdsInitialization(() => ready.future);
    final service = GoogleRewardedHintAdService(
      initialize: initialization.ensureReady,
      loadAd: (_) async {
        loads++;
      },
    );
    service.preload();
    service.preload();
    ready.complete();
    await tester.pump();
    service.preload();
    expect(loads, 1);
    service.dispose();
  });

  test('iOS bundle declares exactly the complete production languages', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final array = RegExp(
      r'<key>CFBundleLocalizations</key>\s*<array>([\s\S]*?)</array>',
    ).firstMatch(plist)!.group(1)!;
    final languages = RegExp(r'<string>([^<]+)</string>')
        .allMatches(array)
        .map((m) => m.group(1)!)
        .toList();
    expect(languages.toSet(), LanguagePolicy.production.enabled.toSet());
    expect(languages.length, 11);
  });
  test('iOS project regions match production languages plus Base', () {
    final project = File('ios/Runner.xcodeproj/project.pbxproj')
        .readAsStringSync();
    final regions = RegExp(r'knownRegions = \(([\s\S]*?)\);')
        .firstMatch(project)!
        .group(1)!
        .split(',')
        .map((r) => r.trim().replaceAll('"', ''))
        .where((r) => r.isNotEmpty)
        .toSet();
    expect(regions, {...LanguagePolicy.production.enabled, 'Base'});
  });
  test(
    'all UI resources remove working-title copy without losing other keys',
    () {
      final files = Directory('lib/l10n')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.arb'))
          .toList();
      final baseline =
          jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map;
      final keys = baseline.keys
          .where((k) => !(k as String).startsWith('@'))
          .toSet();
      for (final file in files) {
        final arb = jsonDecode(file.readAsStringSync()) as Map;
        expect(arb.containsKey('workingName'), isFalse, reason: file.path);
        expect(
          arb.keys.where((k) => !(k as String).startsWith('@')).toSet(),
          keys,
        );
        expect((arb['appDescription'] as String).isNotEmpty, isTrue);
        expect((arb['answersAlwaysEnglish'] as String).isNotEmpty, isTrue);
      }
      expect(files.length, 13);
    },
  );
}
