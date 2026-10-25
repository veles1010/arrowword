# Arrowword iOS ads

- AdMob app: `ca-app-pub-2059856067409159~7305424657`.
- Rewarded hint: `ca-app-pub-2059856067409159/9548444613`.
- Debug and profile always use Google's iOS sample rewarded unit. Release uses
  the real iOS unit, optionally overridden with `ADMOB_IOS_REWARDED_AD_UNIT_ID`.
- Android production configuration is documented in [android-ads.md](android-ads.md).
  Debug/profile use sample units on both mobile platforms.
- No purchases, banner ads or interstitial ads were added.

## Consent

UMP updates consent information at startup and shows any required forms before
Mobile Ads initializes or a rewarded ad is loaded. Errors use UMP's current
eligibility rather than assuming consent. Ads remain optional for gameplay.
Required privacy options appear in Settings and changing them discards cached ads.

In AdMob Privacy & messaging, configure and publish the appropriate messages
for **Arrowword iOS**, including European regulations and the IDFA explanation
if requesting ATT permission. UMP handles the ATT flow; no second ATT plugin or
manual duplicate tracking prompt is used. The iOS usage description and
AppTrackingTransparency framework link are included. Denying ATT does not itself
prevent ads without IDFA when UMP permits ad requests.

Before distribution, verify the messages on a physical device, privacy policy,
store privacy disclosures, app-ads.txt and AdMob store association. Do not test
by interacting with real ads on your own device.

## Mac validation

```sh
flutter pub get
flutter gen-l10n
dart format lib/features/puzzle/ads lib/app/settings_screen.dart test/ads_privacy_test.dart
flutter analyze
flutter test
flutter run --debug -d 00008110-00067D8114B8801E
```

The Runner target uses development team `9MW8PJUR63`, matching the existing
Kelimo/Ezan setup. The bundle identifier remains `com.veles.arrowword.arrowword`.
If Xcode requests account access, sign in with the same Apple developer account.

References (checked 2026-10-24):
- https://developers.google.com/admob/flutter/privacy
- https://developers.google.com/admob/ios/privacy/idfa
- https://developers.google.com/admob/ios/privacy/strategies

The Info.plist SKAdNetwork list is taken from Google's privacy strategies page.
Native builds, Flutter analysis, and Flutter tests require the Mac/Flutter SDK;
they have not been run in the editing environment.
