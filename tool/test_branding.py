"""Pixel-level branding invariants; Python/Pillow only, no runtime dependency."""
import hashlib
import json
import subprocess
import sys
import unittest

from PIL import Image
import generate_branding as branding


def load(path):
    # Close decoder handles before deterministic regeneration (important on Windows).
    with Image.open(path) as image:
        return image.copy()


class BrandingTests(unittest.TestCase):
    def test_icon_master(self):
        icon = load(branding.SOURCE / 'arrowword_icon_source_clean.png')
        self.assertEqual(icon.size, (1024, 1024))
        self.assertEqual(icon.mode, 'RGB')
        for point in [(0, 0), (1023, 0), (0, 1023), (1023, 1023)]:
            self.assertEqual(icon.getpixel(point), (24, 25, 28))

    def test_variant_geometry_blue_and_transparency(self):
        original = load(branding.SOURCE / 'arrowword_mark_transparent.png')
        light = load(branding.GENERATED / 'arrowword_splash_mark_light.png')
        dark = load(branding.GENERATED / 'arrowword_splash_mark_dark.png')
        self.assertEqual(dark.tobytes(), original.tobytes())
        self.assertEqual(light.getchannel('A').tobytes(), original.getchannel('A').tobytes())
        self.assertEqual(light.getchannel('A').getextrema(), (0, 255))
        self.assertEqual(dark.getchannel('A').getextrema(), (0, 255))
        blue_count = white_count = 0
        source = original.tobytes()
        remapped = light.tobytes()
        for offset in range(0, len(source), 4):
            r, g, b, alpha = source[offset:offset + 4]
            if alpha and branding.is_blue(r, g, b):
                self.assertEqual(remapped[offset:offset + 4], source[offset:offset + 4])
                blue_count += 1
            if alpha and min(r, g, b) > 220 and max(r, g, b) - min(r, g, b) < 20:
                self.assertEqual(tuple(remapped[offset:offset + 3]), (24, 25, 28))
                white_count += 1
            if not alpha:
                self.assertEqual(remapped[offset:offset + 4], source[offset:offset + 4])
        self.assertGreater(blue_count, 100000)
        self.assertGreater(white_count, 100000)

    def test_native_safe_bounds_and_appearance_resources(self):
        for density, scale in [('mdpi', 1), ('hdpi', 1.5), ('xhdpi', 2),
                               ('xxhdpi', 3), ('xxxhdpi', 4)]:
            foreground = load(branding.ANDROID / f'drawable-{density}/arrowword_foreground.png')
            branding.safe_circle(foreground, 33 * scale)
            for qualifier in [f'drawable-{density}', f'drawable-night-{density}']:
                splash = load(branding.ANDROID / qualifier / 'arrowword_splash.png')
                self.assertEqual(splash.size, (round(288 * scale),) * 2)
                branding.safe_circle(splash, 96 * scale)
                lockup = load(branding.ANDROID / qualifier / 'arrowword_splash_lockup.png')
                self.assertEqual(lockup.size, (round(256 * scale), round(272 * scale)))

    def test_backgrounds_and_ios_appearances(self):
        self.assertEqual(branding.DARK, '#18191C')
        self.assertEqual(branding.LIGHT, '#F5F7FB')
        for qualifier, color in [('values', '#F5F7FB'), ('values-night', '#18191C')]:
            self.assertIn(f'arrowword_splash_background">{color}',
                          (branding.ANDROID / qualifier / 'branding.xml').read_text())
        contents = json.loads((branding.IOS / 'ArrowwordSplash.imageset/Contents.json').read_text())
        self.assertEqual(len(contents['images']), 6)
        self.assertEqual(sum('appearances' in entry for entry in contents['images']), 3)
        for entry in contents['images']:
            scale = int(entry['scale'][0])
            image = load(branding.IOS / 'ArrowwordSplash.imageset' / entry['filename'])
            self.assertEqual(image.size, (256 * scale, 272 * scale))
            self.assertEqual(image.mode, 'RGBA')
        colors = json.loads((branding.IOS / 'ArrowwordSplashBackground.colorset/Contents.json').read_text())
        for entry, expected in zip(colors['colors'], [(245, 247, 251), (24, 25, 28)]):
            rgb = tuple(round(float(entry['color']['components'][key]) * 255)
                        for key in ['red', 'green', 'blue'])
            self.assertEqual(rgb, expected)

    def test_wordmark_is_separate_and_proportionate(self):
        for appearance, expected in [('light', (24, 25, 28)), ('dark', (255, 255, 255))]:
            lockup = load(branding.GENERATED / f'arrowword_splash_lockup_{appearance}.png')
            self.assertEqual(lockup.size, (1024, 1088))
            # Text sits below mark; the generous gap is entirely transparent.
            self.assertIsNone(lockup.crop((0, 812, 1024, 884)).getchannel('A').getbbox())
            text = lockup.crop((0, 900, 1024, 1088))
            self.assertIsNotNone(text.getchannel('A').getbbox())
            text_pixels = text.tobytes()
            opaque = [tuple(text_pixels[i:i + 3]) for i in range(0, len(text_pixels), 4)
                      if text_pixels[i + 3] == 255]
            self.assertTrue(opaque)
            self.assertTrue(all(color == expected for color in opaque))

    def test_all_icons_remain_complete(self):
        contents = json.loads((branding.IOS / 'AppIcon.appiconset/Contents.json').read_text())
        self.assertEqual(len(contents['images']), 19)
        for entry in contents['images']:
            size = round(float(entry['size'].split('x')[0]) * int(entry['scale'][0]))
            icon = load(branding.IOS / 'AppIcon.appiconset' / entry['filename'])
            self.assertEqual(icon.size, (size, size))
            self.assertEqual(icon.mode, 'RGB')

    def test_two_generation_runs_are_byte_identical(self):
        paths = sorted(path for root in [branding.SOURCE, branding.GENERATED,
                                         branding.ANDROID, branding.IOS]
                       for path in root.rglob('*') if path.is_file())
        snapshot = {path: hashlib.sha256(path.read_bytes()).digest() for path in paths}
        for _ in range(2):
            subprocess.run([sys.executable, str(branding.ROOT / 'tool/generate_branding.py')],
                           check=True, stdout=subprocess.DEVNULL)
            self.assertEqual(snapshot, {path: hashlib.sha256(path.read_bytes()).digest()
                                        for path in paths})


if __name__ == '__main__':
    unittest.main()
