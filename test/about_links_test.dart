import 'dart:async';

import 'package:arrowword/app/about_screen.dart';
import 'package:arrowword/app/arrowword_theme.dart';
import 'package:arrowword/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<PackageInfo> _info() async => PackageInfo(
  appName: 'Arrowword',
  packageName: 'com.veles.arrowword.arrowword',
  version: '2.3.4',
  buildNumber: '99',
);

Future<void> _open(
  WidgetTester tester, {
  Future<bool> Function(Uri)? launcher,
  Locale locale = const Locale('en'),
  bool dark = false,
  double scale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: dark ? ArrowwordTheme.dark() : ArrowwordTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: AboutScreen(
        loadInfo: _info,
        openLink: launcher ?? (_) async => true,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const privacy = ValueKey('about-privacy-policy');
  const support = ValueKey('about-support');
  testWidgets('About keeps name/version and launches the exact privacy URL', (
    tester,
  ) async {
    final urls = <Uri>[];
    await _open(
      tester,
      launcher: (uri) async {
        urls.add(uri);
        return true;
      },
    );
    expect(find.text('Arrowword'), findsOneWidget);
    expect(find.textContaining('2.3.4'), findsOneWidget);
    expect(find.textContaining('99'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    await tester.tap(find.byKey(privacy));
    await tester.pumpAndSettle();
    expect(urls.map((u) => u.toString()), [
      'https://veles1010.github.io/arrowword/privacy-policy.html',
    ]);
  });
  testWidgets('Support launches its exact HTTPS URL', (tester) async {
    final urls = <Uri>[];
    await _open(
      tester,
      launcher: (uri) async {
        urls.add(uri);
        return true;
      },
    );
    await tester.tap(find.byKey(support));
    await tester.pumpAndSettle();
    expect(urls.map((u) => u.toString()), [
      'https://veles1010.github.io/arrowword/support.html',
    ]);
  });
  testWidgets('false launch result shows brief feedback and stays on About', (
    tester,
  ) async {
    await _open(tester, launcher: (_) async => false);
    await tester.tap(find.byKey(privacy));
    await tester.pumpAndSettle();
    expect(find.text('Unable to open the link.'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byType(AboutScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('platform launch exception is caught and localized', (
    tester,
  ) async {
    await _open(
      tester,
      locale: const Locale('tr'),
      launcher: (_) async =>
          throw PlatformException(code: 'browser_unavailable'),
    );
    await tester.tap(find.byKey(support));
    await tester.pumpAndSettle();
    expect(find.text('Bağlantı açılamadı.'), findsOneWidget);
    expect(find.byType(AboutScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('successful launch has no failure message', (tester) async {
    await _open(tester);
    await tester.tap(find.byKey(support));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });
  testWidgets('late failure after About disposal is safe', (tester) async {
    final pending = Completer<bool>();
    await _open(tester, launcher: (_) => pending.future);
    await tester.tap(find.byKey(privacy));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    pending.complete(false);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
  testWidgets('Material link row is keyboard accessible', (tester) async {
    final urls = <Uri>[];
    await _open(
      tester,
      launcher: (uri) async {
        urls.add(uri);
        return true;
      },
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(urls, [AboutScreen.privacyPolicyUrl]);
  });

  const translations = [
    (Locale('tr'), "Gizlilik Politikası", "Destek", "Bağlantı açılamadı."),
    (Locale('en'), "Privacy Policy", "Support", "Unable to open the link."),
    (
      Locale('es'),
      "Política de privacidad",
      "Ayuda",
      "No se pudo abrir el enlace.",
    ),
    (
      Locale('de'),
      "Datenschutzerklärung",
      "Support",
      "Der Link konnte nicht geöffnet werden.",
    ),
    (
      Locale('fr'),
      "Politique de confidentialité",
      "Assistance",
      "Impossible d’ouvrir le lien.",
    ),
    (
      Locale('pt', 'BR'),
      "Política de privacidade",
      "Suporte",
      "Não foi possível abrir o link.",
    ),
    (Locale('ja'), "プライバシーポリシー", "サポート", "リンクを開けませんでした。"),
    (Locale('ko'), "개인정보 처리방침", "고객 지원", "링크를 열 수 없습니다."),
    (
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      "隐私政策",
      "帮助与支持",
      "无法打开链接。",
    ),
    (
      Locale('id'),
      "Kebijakan Privasi",
      "Bantuan",
      "Tautan tidak dapat dibuka.",
    ),
    (
      Locale('ru'),
      "Политика конфиденциальности",
      "Поддержка",
      "Не удалось открыть ссылку.",
    ),
  ];
  for (final (locale, privacyLabel, supportLabel, error) in translations) {
    testWidgets('$locale labels and failure feedback are localized', (
      tester,
    ) async {
      final copy = await AppLocalizations.delegate.load(locale);
      expect(copy.privacyPolicy, privacyLabel);
      expect(copy.support, supportLabel);
      expect(copy.unableToOpenLink, error);
      await _open(tester, locale: locale, launcher: (_) async => false);
      expect(find.text(privacyLabel), findsOneWidget);
      expect(find.text(supportLabel), findsOneWidget);
      await tester.ensureVisible(find.byKey(support));
      await tester.tap(find.byKey(support));
      await tester.pumpAndSettle();
      expect(find.text(error), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  for (final dark in [false, true]) {
    testWidgets('compact About links are accessible at 1.5 scale, dark=$dark', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      await _open(tester, dark: dark, scale: 1.5, locale: const Locale('de'));
      for (final key in [privacy, support]) {
        final row = find.byKey(key);
        await tester.ensureVisible(row);
        await tester.pumpAndSettle();
        expect(row.hitTestable(), findsOneWidget);
        expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
        expect(
          tester
              .getSemantics(row)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
        );
      }
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }
}
