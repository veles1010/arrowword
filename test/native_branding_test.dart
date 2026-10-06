import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

List<int> pngMetadata(String path) {
  final bytes = File(path).readAsBytesSync();
  final data = ByteData.sublistView(bytes);
  expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
  return [data.getUint32(16), data.getUint32(20), bytes[25]];
}

void main() {
  const android = 'android/app/src/main/res';
  const ios = 'ios/Runner/Assets.xcassets';

  test('clean production master is square opaque RGB, originals retained', () {
    expect(
      pngMetadata('assets/branding/source/arrowword_icon_source_clean.png'),
      [1024, 1024, 2],
    );
    expect(pngMetadata('assets/branding/source/arrowword_icon_source.png'), [
      1254,
      1254,
      2,
    ]);
    expect(
      pngMetadata('assets/branding/source/arrowword_mark_transparent.png'),
      [1254, 1254, 6],
    );
  });

  test('every existing iOS icon slot has the correct opaque raster', () {
    final catalog = jsonDecode(
      File('$ios/AppIcon.appiconset/Contents.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final entry in catalog['images'] as List) {
      final size =
          (double.parse((entry['size'] as String).split('x').first) *
                  double.parse((entry['scale'] as String).replaceAll('x', '')))
              .round();
      expect(pngMetadata('$ios/AppIcon.appiconset/${entry['filename']}'), [
        size,
        size,
        2,
      ]);
    }
  });

  test(
    'Android launcher retains legacy icons plus transparent adaptive layers',
    () {
      for (final density in {
        'mdpi': 1.0,
        'hdpi': 1.5,
        'xhdpi': 2.0,
        'xxhdpi': 3.0,
        'xxxhdpi': 4.0,
      }.entries) {
        final legacy = (48 * density.value).round();
        final foreground = (108 * density.value).round();
        expect(pngMetadata('$android/mipmap-${density.key}/ic_launcher.png'), [
          legacy,
          legacy,
          2,
        ]);
        expect(
          pngMetadata(
            '$android/drawable-${density.key}/arrowword_foreground.png',
          ),
          [foreground, foreground, 6],
        );
      }
      final icon = File('$android/mipmap-anydpi-v26/ic_launcher.xml')
          .readAsStringSync();
      expect(icon, contains('@drawable/arrowword_foreground'));
      expect(icon, contains('@color/arrowword_graphite'));
      expect(
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
        contains('android:icon="@mipmap/ic_launcher"'),
      );
    },
  );

  test('native splash references branded light and dark assets without placeholders', () {
    for (final qualifier in ['values-v31', 'values-night-v31']) {
      final styles = File('$android/$qualifier/styles.xml').readAsStringSync();
      expect(styles, contains('android:windowSplashScreenAnimatedIcon'));
      expect(styles, contains('@drawable/arrowword_splash'));
    }
    final storyboard = File('ios/Runner/Base.lproj/LaunchScreen.storyboard')
        .readAsStringSync();
    expect(storyboard, contains('image="ArrowwordSplash"'));
    expect(storyboard, contains('name="ArrowwordSplashBackground"'));
    expect(storyboard, isNot(contains('LaunchImage')));
    final colors = jsonDecode(
      File('$ios/ArrowwordSplashBackground.colorset/Contents.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(colors['colors'], hasLength(2));
    expect(Directory('$ios/LaunchImage.imageset').existsSync(), isFalse);
  });
  test(
    'splash variants are transparent and use separate day/night resources',
    () {
      for (final appearance in ['light', 'dark']) {
        expect(
          pngMetadata(
            'assets/branding/generated/arrowword_splash_mark_$appearance.png',
          ),
          [1254, 1254, 6],
        );
        expect(
          pngMetadata(
            'assets/branding/generated/arrowword_splash_lockup_$appearance.png',
          ),
          [1024, 1088, 6],
        );
      }
      expect(
        File('$android/values/branding.xml').readAsStringSync(),
        contains('#F5F7FB'),
      );
      expect(
        File('$android/values-night/branding.xml').readAsStringSync(),
        contains('#18191C'),
      );
      expect(
        pngMetadata('$android/drawable-night-mdpi/arrowword_splash_lockup.png'),
        [256, 272, 6],
      );
      expect(
        File('$android/drawable/launch_background.xml').readAsStringSync(),
        contains('@drawable/arrowword_splash_lockup'),
      );
    },
  );
  test('iOS lockup catalogue includes three light and three dark rasters', () {
    final catalog = jsonDecode(
      File('$ios/ArrowwordSplash.imageset/Contents.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final images = catalog['images'] as List;
    expect(images, hasLength(6));
    expect(images.where((entry) => entry['appearances'] != null), hasLength(3));
    for (final entry in images) {
      final scale = int.parse((entry['scale'] as String)[0]);
      expect(
        pngMetadata('$ios/ArrowwordSplash.imageset/${entry['filename']}'),
        [256 * scale, 272 * scale, 6],
      );
    }
  });
}
