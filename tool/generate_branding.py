"""Deterministic native branding generation; run with Python + Pillow.

Original source PNGs are read-only. Every raster derives directly from the
approved mark or the clean 1024px master, never from a smaller generated icon.
"""
import hashlib
import json
import math
import re
from functools import lru_cache
from io import BytesIO
from pathlib import Path
from xml.etree import ElementTree as ET

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets/branding/source'
GENERATED = ROOT / 'assets/branding/generated'
ANDROID = ROOT / 'android/app/src/main/res'
IOS = ROOT / 'ios/Runner/Assets.xcassets'
THEME = (ROOT / 'lib/app/arrowword_theme.dart').read_text(encoding='utf-8')
SURFACES = re.search(
    r'surface: dark \? const Color\(0xff([0-9a-f]{6})\) : const Color\(0xff([0-9a-f]{6})\)',
    THEME,
)
assert SURFACES, 'Theme surface tokens changed; review native branding colors.'
DARK = '#' + SURFACES.group(1).upper()
# Splash-only neutral. Flutter's palette is deliberately unchanged.
LIGHT = '#F5F7FB'
FONT = ROOT / 'assets/branding/fonts/VeraBd.ttf'


def save(image, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    encoded = BytesIO()
    image.save(encoded, format='PNG', optimize=False, compress_level=9)
    data = encoded.getvalue()
    # Leave identical resources untouched, including launcher icons. This also
    # avoids reopening unchanged files held briefly by Windows resource readers.
    if not path.exists() or path.read_bytes() != data:
        path.write_bytes(data)


def centered(mark, size, maximum_width):
    ratio = maximum_width / max(mark.size)
    dimensions = tuple(round(value * ratio) for value in mark.size)
    resized = mark.resize(dimensions, Image.Resampling.LANCZOS)
    result = Image.new('RGBA', (size, size))
    result.alpha_composite(resized, ((size - dimensions[0]) // 2,
                                     (size - dimensions[1]) // 2))
    return result


@lru_cache(maxsize=2)
def artwork_radius(alpha, width, height):
    return max(
        math.hypot(index % width + .5 - width / 2,
                   index // width + .5 - height / 2)
        for index, value in enumerate(alpha) if value
    )


def circular(mark, size, radius):
    # Fit actual nontransparent artwork in the guaranteed circular safe zone.
    maximum_radius = artwork_radius(mark.getchannel('A').tobytes(), *mark.size)
    # Additional 2% allowance for Lanczos edge filtering and pixel rounding.
    return centered(mark, size, max(mark.size) * radius / maximum_radius * .98)


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf-8', newline='\n')


def is_blue(r, g, b):
    # Protect arrow gradients, including saturated cyan and deep blue edges.
    saturation = (max(r, g, b) - min(r, g, b)) / max(1, r, g, b)
    return b - r >= 35 and b >= g * .8 and saturation >= .35


def light_variant(original):
    """Change neutral A surfaces only; preserve alpha and all blue pixels.

    Original dark grid cuts become contrasting neutral lines, not an outer
    outline. A surfaces are flat graphite so no original white edge halo remains.
    """
    graphite = tuple(bytes.fromhex(DARK[1:]))
    pixels = bytearray(original.tobytes())
    surfaces = segments = blues = 0
    for offset in range(0, len(pixels), 4):
        r, g, b, alpha = pixels[offset:offset + 4]
        if not alpha:
            continue
        if is_blue(r, g, b):
            blues += 1
            continue
        if max(r, g, b) - min(r, g, b) <= 96:
            # Smoothly map the original neutral shading: bright A surfaces to
            # graphite, dark grid cuts to a contrasting gray. No hard threshold
            # creates isolated white patches at antialiased internal edges.
            detail = max(0.0, min(1.0, (180 - max(r, g, b)) / 70))
            segmentation = tuple(bytes.fromhex('646B75'))
            pixels[offset:offset + 3] = bytes(
                round(base + (line - base) * detail)
                for base, line in zip(graphite, segmentation)
            )
            if detail:
                segments += 1
            else:
                surfaces += 1
    result = Image.frombytes('RGBA', original.size, bytes(pixels))
    assert result.getchannel('A').tobytes() == original.getchannel('A').tobytes()
    return result, {'neutralSurfaces': surfaces, 'segmentation': segments,
                    'protectedBluePixels': blues}


def lockup(mark, color):
    # Compact 256x272pt/dp lockup, rendered at 4x once, not a screen screenshot.
    factor = 4
    result = Image.new('RGBA', (256 * factor, 272 * factor))
    width = 192 * factor
    height = round(width * mark.height / mark.width)
    result.alpha_composite(mark.resize((width, height), Image.Resampling.LANCZOS),
                           ((result.width - width) // 2, 12 * factor))
    font = ImageFont.truetype(str(FONT), 30 * factor,
                             layout_engine=ImageFont.Layout.BASIC)
    draw = ImageDraw.Draw(result)
    bounds = draw.textbbox((0, 0), 'Arrowword', font=font)
    text_width = bounds[2] - bounds[0]
    draw.text(((result.width - text_width) // 2 - bounds[0],
               12 * factor + height + 32 * factor - bounds[1]),
              'Arrowword', font=font, fill=color)
    return result


def safe_circle(image, limit):
    width, height = image.size
    radius = max(math.hypot(index % width + .5 - width / 2,
                            index // width + .5 - height / 2)
                 for index, alpha in enumerate(image.getchannel('A').tobytes())
                 if alpha)
    assert radius <= limit, f'Artwork exceeds circular safe zone: {radius} > {limit}'


def main():
    originals = [SOURCE / 'arrowword_icon_source.png',
                 SOURCE / 'arrowword_mark_transparent.png']
    hashes = {path.name: hashlib.sha256(path.read_bytes()).hexdigest()
              for path in originals}
    original_mark = Image.open(originals[1])
    assert original_mark.mode == 'RGBA'
    assert original_mark.getchannel('A').getextrema() == (0, 255)
    bounds = original_mark.getchannel('A').getbbox()
    mark = original_mark.crop(bounds)  # Remove only completely transparent padding.
    light_master, classification = light_variant(original_mark)
    save(light_master, GENERATED / 'arrowword_splash_mark_light.png')
    save(original_mark, GENERATED / 'arrowword_splash_mark_dark.png')
    light_mark = light_master.crop(bounds)
    lockups = {'light': lockup(light_mark, DARK), 'dark': lockup(mark, '#FFFFFF')}
    for appearance, composition in lockups.items():
        save(composition, GENERATED / f'arrowword_splash_lockup_{appearance}.png')
    layer = centered(mark, 1024, 820)
    clean = Image.new('RGB', (1024, 1024), DARK)
    clean.paste(layer, (0, 0), layer.getchannel('A'))
    save(clean, SOURCE / 'arrowword_icon_source_clean.png')

    for density, scale in [('mdpi', 1), ('hdpi', 1.5), ('xhdpi', 2),
                           ('xxhdpi', 3), ('xxxhdpi', 4)]:
        save(clean.resize((round(48 * scale),) * 2, Image.Resampling.LANCZOS),
             ANDROID / f'mipmap-{density}/ic_launcher.png')
        foreground = circular(mark, round(108 * scale), 32 * scale)
        safe_circle(foreground, 33 * scale)
        save(foreground, ANDROID / f'drawable-{density}/arrowword_foreground.png')
        for appearance, variant in [('light', light_mark), ('dark', mark)]:
            qualifier = f'drawable-{"night-" if appearance == "dark" else ""}{density}'
            splash = circular(variant, round(288 * scale), 94 * scale)
            safe_circle(splash, 96 * scale)
            save(splash, ANDROID / qualifier / 'arrowword_splash.png')
            dimensions = (round(256 * scale), round(272 * scale))
            save(lockups[appearance].resize(dimensions, Image.Resampling.LANCZOS),
                 ANDROID / qualifier / 'arrowword_splash_lockup.png')

    write(ANDROID / 'mipmap-anydpi-v26/ic_launcher.xml', '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/arrowword_graphite" />
    <foreground android:drawable="@drawable/arrowword_foreground" />
</adaptive-icon>
''')
    for qualifier, background in [('values', LIGHT), ('values-night', DARK)]:
        write(ANDROID / qualifier / 'branding.xml', f'''<?xml version="1.0" encoding="utf-8"?>
<!-- Graphite from ArrowwordTheme; light neutral is splash-only. Generated. -->
<resources>
    <color name="arrowword_graphite">{DARK}</color>
    <color name="arrowword_splash_background">{background}</color>
</resources>
''')
    launch = '''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/arrowword_splash_background" />
    <item><bitmap android:gravity="center" android:src="@drawable/arrowword_splash_lockup" /></item>
</layer-list>
'''
    # v21 used to override the base drawable with a Flutter placeholder.
    for qualifier in ['drawable', 'drawable-v21']:
        write(ANDROID / qualifier / 'launch_background.xml', launch)
    for qualifier, parent in [('values-v31', 'Theme.Light.NoTitleBar'),
                               ('values-night-v31', 'Theme.Black.NoTitleBar')]:
        write(ANDROID / qualifier / 'styles.xml', f'''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/{parent}">
        <item name="android:windowBackground">@color/arrowword_splash_background</item>
        <item name="android:windowSplashScreenBackground">@color/arrowword_splash_background</item>
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/arrowword_splash</item>
        <item name="android:windowSplashScreenAnimationDuration">0</item>
    </style>
</resources>
''')

    appicons = IOS / 'AppIcon.appiconset'
    contents = json.loads((appicons / 'Contents.json').read_text())
    for entry in contents['images']:
        size = round(float(entry['size'].split('x')[0]) * float(entry['scale'][:-1]))
        save(clean.resize((size, size), Image.Resampling.LANCZOS),
             appicons / entry['filename'])

    splash_entries = []
    for scale in [1, 2, 3]:
        for appearance in ['light', 'dark']:
            name = f'ArrowwordSplash-{appearance}@{scale}x.png'
            save(lockups[appearance].resize((256 * scale, 272 * scale),
                                            Image.Resampling.LANCZOS),
                 IOS / 'ArrowwordSplash.imageset' / name)
            entry = {'idiom': 'universal', 'filename': name, 'scale': f'{scale}x'}
            if appearance == 'dark':
                entry['appearances'] = [{'appearance': 'luminosity', 'value': 'dark'}]
            splash_entries.append(entry)
    write(IOS / 'ArrowwordSplash.imageset/Contents.json', json.dumps(
        {'images': splash_entries, 'info': {'version': 1, 'author': 'xcode'}}, indent=2) + '\n')
    # Remove only the three superseded files this generator previously produced.
    for scale in [1, 2, 3]:
        (IOS / f'ArrowwordSplash.imageset/ArrowwordSplash@{scale}x.png').unlink(missing_ok=True)
    colors = []
    for color, appearance in [(LIGHT, None), (DARK, 'dark')]:
        channels = [int(color[index:index + 2], 16) / 255 for index in [1, 3, 5]]
        entry = {'idiom': 'universal', 'color': {'color-space': 'srgb',
                 'components': dict(zip(['red', 'green', 'blue'],
                                        [f'{value:.9f}' for value in channels]))}}
        entry['color']['components']['alpha'] = '1.000'
        if appearance:
            entry['appearances'] = [{'appearance': 'luminosity', 'value': appearance}]
        colors.append(entry)
    write(IOS / 'ArrowwordSplashBackground.colorset/Contents.json', json.dumps(
        {'colors': colors, 'info': {'version': 1, 'author': 'xcode'}}, indent=2) + '\n')

    # Validate all catalog slots and resource XML, then prove originals untouched.
    for entry in contents['images']:
        icon = Image.open(appicons / entry['filename'])
        expected = round(float(entry['size'].split('x')[0]) * float(entry['scale'][:-1]))
        assert icon.size == (expected, expected) and icon.mode == 'RGB'
    for path in ANDROID.rglob('*.xml'):
        ET.parse(path)
    storyboard = ROOT / 'ios/Runner/Base.lproj/LaunchScreen.storyboard'
    ET.parse(storyboard)
    assert all(hashlib.sha256(path.read_bytes()).hexdigest() == hashes[path.name]
               for path in originals)
    print(json.dumps({'cleanDimensions': clean.size, 'mode': clean.mode,
                      'alpha': False, 'visibleBounds': clean.getbbox(),
                      'graphite': DARK, 'lightSplash': LIGHT,
                      'sourceMarkBounds': bounds,
                      'cleanMarkBounds': layer.getchannel('A').getbbox(),
                      'iosSlots': len(contents['images']),
                      'lightClassification': classification,
                      'lockupMasterDimensions': lockups['light'].size,
                      'originalsUnchanged': True}, indent=2))


if __name__ == '__main__':
    main()
