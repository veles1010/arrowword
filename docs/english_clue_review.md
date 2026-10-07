# English clue pack v1 editorial review

## Scope and method

900/900 stable IDs, in exactly the Turkish pack's order: Easy 300, Medium 300,
Hard 300. All answers, approved Turkish clues, catalogue metadata/order, seeds,
IDs and generator rules remain frozen. English definitions were authored from
the answer and the intended Turkish sense, not translated mechanically.

Each of the 900 draft entries received a separate editorial pass for intended
sense/part of speech, natural international English, cell fit, answer-family
leakage, competing answers, track character and grammatical precision. Easy
favours concrete everyday descriptions; Medium adds descriptive distinctions;
Hard uses precise nuances rather than cryptic wordplay or obscure trivia.

## Final measurable results

Words include ordinary apostrophe/hyphen compounds as one word. Characters
include spaces and punctuation. Run `dart run tool/validate_localization.dart`.

| Track | Count | Avg words | Max words | Avg chars | Max chars |
|---|---:|---:|---:|---:|---:|
| Easy | 300 | 4.20 | 6 | 24.84 | 41 |
| Medium | 300 | 5.35 | 7 | 33.91 | 55 |
| Hard | 300 | 5.29 | 8 | 34.92 | 56 |

- Duplicate definitions: 0 (case/spacing-normalized check).
- Direct answer leaks: 0 before and after review.
- Definite derivative leaks/root warnings: 1 before, 0 after. ACTIVE's draft
  reused "activity"; final clue is "Engaged in movement or work".
- Length warnings: 34 before, 2 after (both reviewed below).
- Punctuation warnings: 1 before, 0 after. ACRE's draft used a numerical
  conversion; final definition avoids conversion trivia and punctuation noise.
- Generic filler warnings: 0.
- 273 clues use another catalogue answer as ordinary defining vocabulary.
  These informational cross-references were reviewed, not treated as self-leaks:
  e.g. CHEESE uses milk, CLOCK uses wall, and CITE uses source. Context and
  grammatical role distinguish the intended answer; hiding ordinary defining
  vocabulary would make the clues less clear.

43 distinct clues were manually revised after the first draft: Easy 32, Medium
6, Hard 5. Main revisions shortened Easy descriptions, removed root reuse,
replaced awkward botanical phrasing, clarified ENTAIL's necessary consequence
(rather than a condition), distinguished DEFT from NIMBLE, and improved MUSE's
natural phrasing. WILLOW describes a riverside tree, not "riverside branches".

## Ambiguity and sense decisions

- COLUMN is a newspaper opinion feature in the frozen Turkish catalogue;
  PILLAR is an upright load-bearing support. No structural COLUMN reinterpretation.
- CHOOSE is a verb; CHOICE is the act of selection; OPTION is an available
  alternative before deciding.
- CITE names supporting evidence; QUOTE repeats someone's exact words.
- HINDER concerns task progress; IMPEDE concerns obstructed movement.
- AMBLE stresses slow easy steps; SAUNTER stresses leisurely pleasure.
- ENGINE burns fuel to drive pistons; MOTOR turns electrical energy into rotation.
- SUMMIT is a mountain top, PEAK a graph maximum, APEX a cone's tip, ZENITH
  the height of achievement. DEPTH retains its intellectual, not physical sense.
- BANK is financial, LIGHT illumination, WATCH a wrist timepiece, BARK a tree
  covering, MINT the aromatic leaf, NEST arrangement and STEM arising from a source.
- WAIVE gives up a right; CEDE surrenders territory/control; FORGO gives up a
  benefit; YIELD stops resistance under pressure. Legal cancellation verbs retain
  their separate objects (permission, decision, law, transaction, effect).

## Reviewed retained boundaries

DOLPHIN ("Sleek marine mammal with a beak") and CLIMB ("Go upwards using hands
and feet") have six short words, only 31 characters each. Removing the beak or
movement details harms fairness more than it helps cell fit. These are the only
remaining length warnings; no unresolved morphological/root warnings remain.

Close synonyms and species with alternate common names remain crossing-assisted
as normal vocabulary puzzles are. AMBLE/SAUNTER, DEFT/NIMBLE and COUGAR's alternate
names were reviewed explicitly; their clues preserve the intended nuance without
answer length, spelling hints, regional trivia or own-root reuse.

All 108 production-board locks also resolve every encountered clue in tr/en.
Repeat generation and locked IDs/seeds/signatures pass without catalogue or
selection changes. Current boards use 712 distinct English clue IDs: Easy 236,
Medium 211, Hard 265. The complete catalogue is independently validated at
900/900 regardless of which entries current boards select.
