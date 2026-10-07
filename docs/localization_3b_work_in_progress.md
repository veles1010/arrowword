# Localization 3B — completion status

Foundation: ae75386; CJK gameplay: e3fa3de. Milestone 3B.2 completes Russian
and Indonesian: eleven production locales and 9,900 clues.

## Implemented

- Complete 131-message UI resources, including restrained About explanation that
  answers are always English. Russian plurals and localized dates/share remain.
- Eleven complete 900-entry clue packs; Russian/Indonesian editorial reports
  document revision counts and every retained borrowing category.
- Stable preferences/autonyms; Settings exposes all complete choices.
- Hans/CN/SG selects Simplified Chinese; Hant/TW/HK/MO/bare zh falls back to English.
  Flutter-required base zh/pt UI resources are not additional gameplay locales.
- id-* and ru-* resolve to Indonesian/Russian; unsupported languages use English.
- Lazy cached packs, atomic UI/clue switching, unchanged attempt state.
- Extended 108-board/eleven-locale coverage and compact Daily/share/input regressions.

## Frozen boundary

All nine previously approved clue packs, answers, clue IDs, catalogue order,
generation, sequence/seed/ID contracts, scores, persistence, Daily identity,
branding, visual tokens and bottom-navigation geometry remain unchanged.
Input safeguards are unchanged: composition is preserved until commit;
unsupported commits are ignored, not mistaken for deletion; ASCII filtering occurs
before uppercasing. Only English A–Z enters answer cells.

## Remaining manual checks

Use Russian, Japanese, Korean and Pinyin keyboards: composition/commit/cancel,
backspace, pasted mixed text and switching to English/Latin. Verify real font
fallback and compact clue readability. No custom keyboard is required or added;
widget tests cannot certify native keyboard ergonomics or glyph shapes.
