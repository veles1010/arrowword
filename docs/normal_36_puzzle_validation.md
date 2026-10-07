# Normal main-game V1: 36 puzzles per difficulty

Validated 2026-10-06 against unchanged committed catalogues, clues, ordering, seeds,
IDs, budgets, cooldown and selection policies. **108/108 succeeded; all 108 were
independently generated again with the same prefix and matched IDs, seeds, full
structural signatures and clue lists.** Both passes receive strict generated-board
validation: 10 answers, connected graph, unique answers, valid clue positions,
bounds, opposite-direction agreeing crossings, at least four answers per direction,
minimum nine crossings, zero phantom adjacencies/unexplained runs and cooldown
violations. No structural rule was relaxed and no index exception was introduced.

## 36-board summaries

Values with three terms are minimum / average / maximum.

| Metric | Kolay | Orta | Zor |
|---|---:|---:|---:|
| Success | 36/36 | 36/36 | 36/36 |
| Unique catalogue words / coverage | 236/300 / 78.67% | 211/300 / 70.33% | 265/300 / 88.33% |
| Crossings | 10 / 11.61 / 13 | 11 / 11.78 / 13 | 9 / 11.58 / 13 |
| Leaves | 0 / 1.50 / 2 | 1 / 1.56 / 3 | 0 / 1.33 / 3 |
| Mean visible rows x columns | 9.78 x 8.61 | 9.75 x 8.72 | 9.53 x 8.61 |
| 10-column boards | 3 | 1 | 0 |
| Quality | 3010 / 3902.19 / 4553 | 3504 / 3952.47 / 4549 | 2781 / 3917.58 / 4723 |
| Attempts | 1 / 3.08 / 5 | 1 / 3.47 / 5 | 1 / 2.92 / 5 |
| Generation ms | 446 / 1322.72 / 2524 | 418 / 1653.31 / 2690 | 598 / 1290.61 / 2033 |
| First-pass generation total ms | 47618 | 59519 | 46462 |
| Phantom / unexplained / cooldown violations | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 |

Timings measure the first generation call only, not validation or repeat calls.
Sequential CLI run; no timing assertions/stopping rules. Total first-pass generation
was 153.60 seconds. No first-pass request exceeded three seconds.

## Notable unchanged layouts

- easy: ten-column indexes 23, 28, 31; minimum quality at 28 (10x10, 10 crossings, 2 leaves, score 3010); slowest 11 at 2524 ms.
- medium: ten-column indexes 11; minimum quality at 11 (10x10, 11 crossings, 1 leaves, score 3504); slowest 24 at 2690 ms.
- hard: ten-column indexes none; minimum quality at 19 (10x9, 9 crossings, 2 leaves, score 2781); slowest 30 at 2033 ms.

Wide boards and Hard 19's minimally integrated tree remain playtest outliers,
not reasons to change frozen generation. End-range boards are not special-cased.
Easy's legacy cognate clues (e.g. PANDA/PILOT/ROBOT/ZEBRA) retain their established
content policy; the Medium/Hard descriptive-clue gate is not imposed on Easy.
All three tracks receive the same strict board validator.

## Frozen end-range locks

Full ID/answer/direction/start/clue-coordinate signatures are stored verbatim in
`test/fixtures/normal_end_range_locks.dart`, captured before product UI changes.
They are compared against fresh sequential generation in automated tests.

| Index | Easy seed | Medium seed | Hard seed |
|---|---:|---:|---:|
| 31 | 4156542839 | 1113808900 | 2307866015 |
| 32 | 4199572346 | 6272470 | 627464958 |
| 33 | 2046430165 | 2927346251 | 2425241634 |
| 34 | 671223049 | 1578376928 | 1742187016 |
| 35 | 402308163 | 3863757169 | 837372819 |
| 36 | 3263019000 | 2696277285 | 2848272179 |

IDs retain `generated-v3-000031..000036`,
`generated-medium-v1-000031..000036`, and `generated-hard-v1-000031..000036`.
Existing Easy/Medium/Hard early-index fixtures remain in the suite.

## Product and persistence boundary

- Central `normalPuzzleCount = 36`, total 108. Daily remains independent.
- All 36 tiles are lazy-rendered from metadata, not pre-generated. Future tiles
  remain locked; the selected difficulty shows completed count / 36.
- Finishing 36 stores current index 36, completedThrough 36, solved letters and
  immutable result normally. Its historical prefix still ends at 35, as required
  for a solved current puzzle. No fake current index 37 and no schema migration.
- All completed tiles including 36 allow isolated best-score replay. Home offers
  Bulmacaları Gör; no automatic switch to another track.
- A valid pre-contract save above 36 stays intact. Metadata caps the UI count at
  36 and does not expose/generate its out-of-range current puzzle. Normal open is
  rejected. Replay restores only board 36 from the verified first 35 compact entries;
  the current/historical entry for 36 must agree. Earlier replay also uses this
  verified compact prefix, never replaying generation 1..N.
- Out-of-range current letters/hints/time/checks are never applied to board 36.
  Only a successfully improved replay result writes archived data: all original
  current index/identity/letters/hints/stats/completedThrough/history fields are
  retained and only the best-score map is updated. Existing schema 5 is unchanged.
  Older compact-history schemas upgrade to already-established schema 5 only if
  a new replay score actually needs saving. Archives with no verifiable compact
  prefix fail safely without clearing their payload.
- Historical scored records remain in score aggregates; displayed completed count
  caps at 36 and out-of-range score details are labeled Eski kayıt. No invented scores.
- Debug/profile app override accepts only 1..36 and remains memory-only. Tooling
  may still use lower-level generators beyond the product range.

Reproduce: `dart run tool/inspect_tracks.dart --all-normal --repeat`.

Manual review: Easy around 31, Medium around 2 and Hard around 1; scroll to 36,
check each summary and neutral locks, exercise ordinary Next, and inspect final
completion/replay using isolated test data (never edit a real player save).
Bottom navigation/colors/generator/content/Daily/scoring/ads remain frozen.
