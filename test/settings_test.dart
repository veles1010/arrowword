import 'package:arrowword/app/app_settings.dart';
import 'package:arrowword/app/about_screen.dart';
import 'package:arrowword/app/settings_screen.dart';
import 'package:arrowword/app/app.dart';
import 'package:arrowword/app/arrowword_theme.dart';
import 'package:arrowword/app/daily_puzzle_screen.dart';
import 'package:arrowword/app/daily_progress_store.dart';
import 'package:arrowword/app/puzzle_session.dart';
import 'package:arrowword/app/puzzle_progression_screen.dart';
import 'package:arrowword/features/puzzle/daily/daily_puzzle.dart';
import 'package:arrowword/features/puzzle/presentation/puzzle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _BadStore implements SettingsStore {
  @override
  Future<String?> readTheme() async =>
      throw const FormatException('Wrong type');
  @override
  Future<void> writeTheme(String value) async =>
      throw StateError('Storage unavailable');
}

void main() {
  for (final synchronous in [true, false]) {
    testWidgets('About safely handles package info failure sync=$synchronous', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AboutScreen(
            loadInfo: () {
              if (synchronous) throw StateError('INTERNAL_PACKAGE_FAILURE');
              return Future<PackageInfo>.error(
                StateError('INTERNAL_PACKAGE_FAILURE'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Arrowword'), findsOneWidget);
      expect(find.text('Sürüm bilgisi alınamadı.'), findsOneWidget);
      expect(find.textContaining('INTERNAL_PACKAGE'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  test('malformed storage and write failures are safe', () async {
    final s = await AppSettings.restore(_BadStore());
    expect(s.themeMode, ThemeMode.system);
    s.setTheme(ThemeMode.dark);
    await s.flush;
    expect(s.themeMode, ThemeMode.dark);
    s.dispose();
  });
  test('default System and unknown value fallback', () async {
    for (final value in [null, 'invalid', 'DARK']) {
      final store = MemorySettingsStore(value);
      final settings = await AppSettings.restore(store);
      expect(settings.themeMode, ThemeMode.system);
      expect(store.writes, 0);
      settings.dispose();
    }
  });
  for (final mode in [ThemeMode.light, ThemeMode.dark, ThemeMode.system]) {
    test(
      '${mode.name} persists and restores without duplicate writes',
      () async {
        final store = MemorySettingsStore();
        final settings = AppSettings(
          store,
          mode == ThemeMode.system ? ThemeMode.dark : ThemeMode.system,
        );
        settings.setTheme(mode);
        settings.setTheme(mode);
        await settings.flush;
        final restored = await AppSettings.restore(store);
        expect(restored.themeMode, mode);
        expect(store.writes, 1);
        settings.dispose();
        restored.dispose();
      },
    );
  }
  test('queued rapid changes retain latest preference', () async {
    final store = MemorySettingsStore();
    final s = AppSettings(store);
    s.setTheme(ThemeMode.light);
    s.setTheme(ThemeMode.dark);
    await s.flush;
    expect((await AppSettings.restore(store)).themeMode, ThemeMode.dark);
    s.dispose();
  });
  testWidgets('compact Settings supports accessible choices', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = AppSettings(MemorySettingsStore());
    addTearDown(s.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: SettingsScreen(settings: s),
        ),
      ),
    );
    for (final label in ['Koyu', 'Açık', 'Sistem']) {
      await tester.tap(find.byType(DropdownButtonFormField<ThemeMode>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(
        s.themeMode,
        label == 'Koyu'
            ? ThemeMode.dark
            : label == 'Açık'
            ? ThemeMode.light
            : ThemeMode.system,
      );
    }
    expect(find.text('Tema'), findsOneWidget);
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel(RegExp('Tema')), findsWidgets);
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });
  testWidgets('About loads real provider data once and scales safely', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(1.5),
          ),
          child: AboutScreen(
            loadInfo: () async {
              calls++;
              return PackageInfo(
                appName: 'test',
                packageName: 'test',
                version: '2.3.4',
                buildNumber: '99',
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sürüm 2.3.4 · Yapı 99'), findsOneWidget);
    expect(calls, 1);
    expect(tester.takeException(), isNull);
  });
  late PuzzleSession session;
  setUpAll(() => session = PuzzleSession());
  tearDownAll(() => session.dispose());
  testWidgets('theme updates immediately on Home and keeps session', (
    tester,
  ) async {
    final s = AppSettings(MemorySettingsStore());
    addTearDown(s.dispose);
    await tester.pumpWidget(ArrowwordApp(session: session, settings: s));
    expect(find.byTooltip('Ayarlar'), findsOneWidget);
    final identity = session.current.puzzle!.id;
    s.setTheme(ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Başla'))).brightness,
      Brightness.dark,
    );
    expect(session.current.puzzle!.id, identity);
    await tester.tap(find.byTooltip('Ayarlar'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
  test(
    'settings changes do not mutate normal attempt or Daily preference keys',
    () async {
      final before = session.current.puzzle!.id;
      final letters = Map.of(session.letters);
      final s = AppSettings(MemorySettingsStore());
      s.setTheme(ThemeMode.dark);
      await s.flush;
      expect(session.current.puzzle!.id, before);
      expect(session.letters, letters);
      expect(SharedPreferencesSettingsStore.key, 'arrowword.settings.theme');
      expect(
        SharedPreferencesSettingsStore.key,
        isNot(SharedPreferencesDailyProgressStore.key),
      );
      s.dispose();
    },
  );
  for (final screen in ['puzzle', 'progression', 'result']) {
    testWidgets('compact dark $screen is overflow free', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final Widget child = screen == 'puzzle'
          ? PuzzleScreen(puzzle: session.current.puzzle!)
          : screen == 'progression'
          ? PuzzleProgressionScreen(
              session: session,
              puzzleBuilder: (_) => const SizedBox(),
            )
          : DailyResultScreen(
              result: DailyPuzzleScore.calculate(
                dateKey: '2026-10-04',
                dailyPuzzleId: dailyPuzzleId('2026-10-04'),
                elapsedSeconds: 80,
                hintsUsed: 0,
                wrongChecks: 0,
              ),
            );
      await tester.pumpWidget(
        MaterialApp(
          theme: ArrowwordTheme.dark(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: child,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
