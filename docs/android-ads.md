# Arrowword Android ads

- AdMob app: `ca-app-pub-2059856067409159~6267053038`.
- Rewarded hint: `ca-app-pub-2059856067409159/6285655323`.
- Package: `com.veles.arrowword.arrowword`.
- The main Android manifest declares the real app ID and Internet permission.
- Debug/profile always use Google's sample rewarded unit. Release uses the real
  Android unit, optionally overridden with `ADMOB_ANDROID_REWARDED_AD_UNIT_ID`.
- A completed rewarded ad reveals one letter. No purchases or other ad formats.

## Before production

Publish European regulations messages in AdMob Privacy & messaging for
**Arrowword Android**, using the privacy policy at
https://veles1010.github.io/arrowword/privacy-policy.html.
The existing shared UMP controller gates SDK initialization and ad loading on
`canRequestAds`; required privacy options are available in Settings.
Android does not use the iOS IDFA/ATT message.

Verify the privacy policy, Google Play Data safety/ads declarations, app-ads.txt,
and supported public store association. A successful debug sample does not prove
production ad serving readiness. Keep closed testing active while production
access is under review.

## Validation

```sh
flutter pub get
dart format lib/features/puzzle/ads/google_rewarded_hint_ad_service.dart test/ads_privacy_test.dart
flutter analyze
flutter test test/ads_privacy_test.dart test/ad_initialization_test.dart
flutter devices
```

Run `flutter run --debug -d <android-device-id>` and check normal/daily puzzles,
rewarded completion and dismissal, progress restoration, and tablet layout.
Before building the signed AAB, use the existing upload keystore and a version
code greater than every previously uploaded Google Play artifact. Do not generate
a replacement upload key or reuse the iOS build number without checking Play.

Native Android/Flutter validation cannot run in the editing environment; run it
locally before distributing this change.
