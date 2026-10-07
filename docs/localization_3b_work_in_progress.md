# Localization 3B — work in progress

Foundation baseline: ae75386; Milestone 3B.1 baseline: 43e3660.
Japanese, Korean and Simplified Chinese are now complete (900 clues each), with
editorial reports and production activation. This is a nine-locale release, not
the eventual eleven-locale release. Russian and Indonesian remain gated.

## Implemented foundation

- Complete 130-message UI resources for ja, ko, zh-Hans, id and ru. Russian count
  messages include one/few/many forms; localized dates/share/semantics are included.
- Flutter-required base zh UI resource mirrors Simplified Chinese. Production
  resolution never selects ambiguous zh or Traditional Chinese.
- Stable preference IDs/autonyms; CJK choices are available. Prepared availability
  records remain incomplete only for ru/id, which Settings never exposes.
- Script-aware Chinese policy tested in the production registry:
  explicit Hans or CN/SG selects Simplified; Hant/TW/HK/MO/bare zh uses English.
- Root Locale construction preserves scriptCode rather than treating Hans as a
  country code. Restored incomplete preferences do not crash the Settings dropdown.
- Narrow input bug fix: non-Latin commits were incorrectly treated as backspace.
  Composition is now left intact until commit; unsupported commits are ignored.
  ASCII filtering happens before uppercasing, preventing Unicode expansions from
  entering A-Z cells. Lowercase Latin and last-Latin-character paste remain supported.
- Domain and simulated IME tests for Japanese/Korean/Chinese/Russian, plus compact
  UI-only foundation tests at 360x640, scales 1.3/1.5. These do not prove real font
  fallback or native IME ergonomics. CJK gameplay/rendered-clue tests are now added.

## Required remaining work

1. Author/review the ru/id 900-entry packs directly from frozen English content.
2. Extend existing audits for Cyrillic transliteration and Indonesian borrowing.
3. Create Russian/Indonesian editorial reports with actual revision/warning counts.
4. Activate ru/id only after validation; then expose eleven autonyms.
5. Extend the existing nine-locale cache/Daily/108-board tests to eleven locales.
6. Perform real-device font/IME checks; no custom keyboard in this milestone.
7. Claim eleven locales / 9,900 clues only after those two packs are complete.

## Frozen boundary

All six existing clue packs and ARB translations, catalogue data, generator,
sequence/seed/ID contracts, scores, schemas, Daily identity, branding, visual tokens,
and bottom-navigation geometry are unchanged. Existing gameplay locales remain
tr/en/es/de/fr/pt-BR/ja/ko/zh-Hans. ru/id UI availability is not gameplay completeness.

## Manual input follow-up

Use actual Japanese IME, Korean, Pinyin and Cyrillic keyboards. Verify composition,
commit/cancel, backspace, pasted mixed text and switching to Latin. Current OS
keyboard choice is not forced to Latin; a dedicated A-Z input milestone is
recommended for product ergonomics, not implemented here.
