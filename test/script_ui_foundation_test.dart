import 'dart:convert';
import 'dart:io';

import 'package:arrowword/app/app_settings.dart';
import 'package:arrowword/app/fluid_navigation_bar.dart';
import 'package:arrowword/app/settings_screen.dart';
import 'package:arrowword/l10n/app_language.dart';
import 'package:arrowword/l10n/generated/app_localizations.dart';
import 'package:arrowword/l10n/language_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _LanguageStore implements LanguagePreferenceStore {
  _LanguageStore(this.value);
  String value;
  int writes = 0;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    this.value = value;
    writes++;
  }
}

void main() {
  const fixtures = [
    ('ja', 'ホーム', '広告でヒント'),
    ('ko', '홈', '광고로 힌트'),
    ('zh-Hans', '首页', '广告提示'),
    ('id', 'Beranda', 'Petunjuk via iklan'),
    ('ru', 'Главная', 'Буква за рекламу'),
  ];
  final reference =
      jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map;
  for (final (tag, home, hint) in fixtures) {
    final locale = tag == 'zh-Hans'
        ? const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans')
        : Locale(tag);
    test(
      '$tag UI foundation has all 130 messages and correct script',
      () async {
        final arb = jsonDecode(
          File('lib/l10n/app_${tag.replaceAll('-', '_')}.arb')
              .readAsStringSync(),
        ) as Map;
        expect(arb.keys.toSet(), reference.keys.toSet());
        expect(
          arb.keys.where((key) => !(key as String).startsWith('@')),
          hasLength(130),
        );
        final copy = await AppLocalizations.delegate.load(locale);
        expect(copy.home, home);
        expect(copy.rewardHint, hint);
        expect(copy.puzzleNumber(36), contains('36'));
        expect(copy.completedCount(2), contains('2'));
        expect(copy.dateDisplay(4, copy.month10, 2026), contains('2026'));
        expect(copy.hintLocked, isNot('Revealed with a hint, locked'));
        expect(
          LanguagePolicy.production.enabled.contains(tag),
          ['ja', 'ko', 'zh-Hans'].contains(tag),
        );
      },
    );
    test(
      '$tag internal preference persists without premature enablement',
      () async {
        final store = _LanguageStore(tag),
            language = await AppLanguage.restore(_LanguageStore(tag));
        expect(language.preference.id, tag);
        language.dispose();
        final controller = AppLanguage(store);
        await controller.setPreference(AppLanguagePreference.parse(tag));
        expect(store.value, tag);
        expect(store.writes, 1);
        controller.dispose();
      },
    );
    for (final scale in [1.3, 1.5]) {
      testWidgets('$tag compact UI foundation at scale $scale', (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final settings = AppSettings(MemorySettingsStore());
        final language = AppLanguage(
          _LanguageStore(tag),
          AppLanguagePreference.parse(tag),
        );
        addTearDown(settings.dispose);
        addTearDown(language.dispose);
        Future<void> pump(Widget child) async {
          await tester.pumpWidget(
            MaterialApp(
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: child,
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        await pump(
          Scaffold(
            bottomNavigationBar: FluidNavigationBar(
              index: 0,
              onSelected: (_) {},
            ),
          ),
        );
        expect(find.text(home), findsOneWidget);
        expect(find.bySemanticsLabel(home), findsOneWidget);
        expect(tester.takeException(), isNull);
        await pump(SettingsScreen(settings: settings, language: language));
        final strings = AppLocalizations.of(
          tester.element(find.byType(SettingsScreen)),
        )!;
        expect(find.text(strings.language), findsOneWidget);
        // Complete CJK preferences are selectable; unfinished ru/id remain safe.
        expect(
          find.text(
            LanguagePolicy.production.enabled.contains(tag)
                ? language.preference.autonym
                : strings.systemDefault,
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text(strings.appInformation));
        await tester.tap(find.text(strings.appInformation));
        await tester.pumpAndSettle();
        expect(find.text('Arrowword'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  test('Russian plural forms distinguish one, few and many', () async {
    final copy = await AppLocalizations.delegate.load(const Locale('ru'));
    expect(copy.scorePoints(1), '1 очко');
    expect(copy.scorePoints(2), '2 очка');
    expect(copy.scorePoints(5), '5 очков');
    expect(copy.scorePoints(21), '21 очко');
  });
}
