# Medium / Hard v1 validation — 2026-10-06

Both 30-puzzle sequences passed strict 10x10/10-answer validation, at least four
answers per direction, connected graph, zero phantom adjacencies/unexplained runs,
and strict five-puzzle cooldown. No Easy generation or quality policy changed.

The banks each contain 300 authored new 4–7-letter answers, no duplicates or
cross-track/Easy overlap, no exact duplicate or English-leaking clues. Positional
partner gate: at least 100 neighbors per word. Matching letter positions can form
legal two-word crosses within 10x10; full boards receive the independent validator.
Lexical near-clue heuristic found no pairs at Jaccard >=0.65 after stop-word removal.
This is not proof of semantic uniqueness; human review remains necessary.

| Content metric | Medium | Hard |
|---|---:|---:|
| Length 4 / 5 / 6 / 7 | 45 / 87 / 124 / 44 | 104 / 94 / 66 / 36 |
| WordDifficulty metadata | 300 medium | 294 hard / 6 medium |
| Partners min / avg / max | 157 / 259.15 / 297 | 119 / 249.19 / 292 |

The six medium-metadata Hard entries (FRAME, RANGE, SCALE, PEAK, STEM, NEST)
use contextual/figurative senses. Metadata does not filter the track provider.

| 30-puzzle metric | Medium | Hard |
|---|---:|---:|
| Unique answers / coverage | 201 / 67.00% | 244 / 81.33% |
| Usage min / avg / max (including unused) | 0 / 1.00 / 4 | 0 / 1.00 / 3 |
| Repeat spacing min / avg / max | 6 / 12.68 / 29 | 6 / 16.36 / 28 |
| Crossings min / avg / max | 11 / 11.80 / 13 | 9 / 11.60 / 13 |
| Leaves min / avg / max | 1 / 1.57 / 3 | 0 / 1.27 / 3 |
| Average visible rows x columns | 9.80 x 8.70 | 9.50 x 8.57 |
| 10-column boards | 1 | 0 |
| Quality min / avg / max | 3504 / 3961.87 / 4549 | 2781 / 3935.13 / 4723 |
| Attempts avg / max | 3.20 / 5 | 2.50 / 5 |
| Generation ms min / avg / max | 367 / 1510.33 / 2448 | 553 / 1136.57 / 1987 |
| Summed generation ms | 45310 | 34097 |

Times are locally observed generator diagnostics from concurrent command-line runs,
not stopping conditions or correctness assertions. The final metadata adjustment
does not affect generation; deterministic first-board locks and full 30-board
regressions verify the final banks.

## Compatibility policies

Catalogue/sequence versions are independently 1. Medium uses MED1 (0x4D454431),
Hard HAR1 (0x48415231), with the unchanged uint32 avalanche. IDs are
generated-medium-v1-000001 / generated-hard-v1-000001, etc. Word IDs are
medium-<solution> / hard-<solution>. Histories and schema-5 saves use isolated
track namespaces; no Easy IDs or state are renamed.

| Index | Medium seed | Hard seed |
|---|---:|---:|
| 1 | 553741480 | 1117217477 |
| 2 | 2558657560 | 1469360122 |
| 3 | 1892685967 | 963478886 |
| 10 | 3481664712 | 1938332644 |

No search tuning: 10000 nodes/backtracks, 4000000 checks per generator attempt,
200 nodes/anchor, 40 branches, minimum 9 crossings, 4 per direction; unchanged
bounded support and board/sequence comparators. Failures never relax run integrity.

## Pre-freeze semantic audit

All 600 pairs were subsequently reviewed. See
[difficulty_content_review.md](difficulty_content_review.md) for the complete
clue-change inventory, representative examples, remaining borderline meanings,
outlier assessment and newer sequential timing measurements. Only clues changed:
answers, IDs, seeds, ordering and the 30-board structural/coverage results below
remain unchanged. The timing table above is the original milestone measurement.

## Review before difficulty UI

Medium 11 is the sole wide board (10x10, 11 crossings, score 3504).
Hard 19 is valid but weakly integrated (10x9, 9 crossings, score 2781).
Do not optimize only these seeds; playtest both and the general curriculum.
Medium coverage is 67%, below the Easy balancing experiment, with many six-letter
words and more support attempts. Hard reaches 81.33%. Keep these tradeoffs visible.

Review synonym clusters (e.g. ASSERT/AFFIRM, REFUTE/REBUT and ASTUTE/SHREWD),
regional terminology, polysemous clues, natural Turkish phrasing and learner-level
difficulty. No automated test can certify every clue has exactly one semantic
reading. No trivia, cryptic transformations, inflection padding, production UI,
new scoring rules or gameplay restrictions were added.

Reproduce: dart run tool/inspect_tracks.dart medium 30
and dart run tool/inspect_tracks.dart hard 30.

