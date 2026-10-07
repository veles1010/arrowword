# Localization 3B — work in progress

Baseline: ae75386. This is not a completed eleven-locale release.

## Implemented foundation

- Complete 130-message UI resources for ja, ko, zh-Hans, id and ru. Russian count
  messages include one/few/many forms; localized dates/share/semantics are included.
- Flutter-required base zh UI resource mirrors Simplified Chinese. Production
  resolution never selects ambiguous zh or Traditional Chinese.
- Stable preference IDs and autonyms; prepared availability records explicitly
  have no complete clue packs. Settings does not expose these choices yet.
- Script-aware Chinese policy tested with a hypothetical complete registry:
  explicit Hans or CN/SG selects Simplified; Hant/TW/HK/MO/bare zh uses English.
- Root Locale construction preserves scriptCode rather than treating Hans as a
  country code. Restored incomplete preferences do not crash the Settings dropdown.
- Narrow input bug fix: non-Latin commits were incorrectly treated as backspace.
  Composition is now left intact until commit; unsupported commits are ignored.
  ASCII filtering happens before uppercasing, preventing Unicode expansions from
  entering A-Z cells. Lowercase Latin and last-Latin-character paste remain supported.
- Domain and simulated IME tests for Japanese/Korean/Chinese/Russian, plus compact
  UI-only foundation tests at 360x640, scales 1.3/1.5. These do not prove real font
  fallback, native IME ergonomics or localized gameplay-clue rendering.

## Required remaining work

1. Independently author and editorially review all five 900-entry clue packs from
   frozen English sense data. No new clue packs have been created in this pass.
2. Extend shared audits for scripts, loanword/transliteration revelation, unexpected
   English, Simplified-vs-Traditional checks and script-appropriate length metrics.
3. Create the five requested substantive clue-review documents with actual counts,
   revisions and resolved warnings; do not invent editorial coverage.
4. After validation, move prepared locales into the production-complete registry,
   register assets and expose all eleven autonyms. Update current hardcoded
   six-locale expectations without weakening legacy coverage.
5. Exercise cache and atomic switching across the five real new packs; resolve
   Daily and all 108 deterministic boards in all eleven locales.
6. Complete gameplay/results/share/compact script tests and real-device checks.
7. Update release-facing README claims to eleven locales / 9,900 clues only then.

## Frozen boundary

All six existing clue packs and ARB translations, catalogue data, generator,
sequence/seed/ID contracts, scores, schemas, Daily identity, branding, visual tokens,
and bottom-navigation geometry are unchanged. Existing gameplay locales remain
tr/en/es/de/fr/pt-BR; new UI availability is not gameplay completeness.

## Manual input follow-up

Use actual Japanese IME, Korean, Pinyin and Cyrillic keyboards. Verify composition,
commit/cancel, backspace, pasted mixed text and switching to Latin. Current OS
keyboard choice is not forced to Latin; a dedicated A-Z input milestone is
recommended for product ergonomics, not implemented here.
