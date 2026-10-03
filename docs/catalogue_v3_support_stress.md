# Bounded-support v3 comparison

Same 300 records, base seed 20261003, cooldown 5, compatibility version 3.
The catalogue Git blob remains dea109b8856ab8232068399b323fc94ed544772c.
Generator, budgets, scoring, validator, manual fixture and renderer are unchanged.

Support ranking is lexicographic: ascending lifetime usage, descending distinct
target neighbors per letter (integer neighbors*1000/length), descending raw neighbor
count, descending matching letter-index opportunities, oldest last use, stable ID.
Targets are all minimum-usage eligible words. Support sizes are 0,2,4,16,full,
deduplicated/clamped; an undersized target starts with just enough support to reach
the configured answer count. Full support is a terminal escape hatch, not the
first widening step. No length/difficulty quotas or underrepresented-length bias.

Compare at most three successful stages. Stop early at quality>=3900, columns<=9,
leaves<=3. Prefer boards meeting quality>=3500, columns<=9, leaves<=3; then maximize
quality +180*selected target count -400 if ten columns. Ties: more targets, fewer
columns, more crossings, fewer leaves, lexical structure. Guardrails are preferences,
not validity rules: return the best strict-valid success if none meets them.

Coverage and average-quality goals are met; three wide boards miss the <=2 goal.
Mean attempts 2.67 miss <=2; max five meets the cap. This is not Pareto dominance:
max usage rises 2→3, average repeat gap falls, and generation costs more. Six-letter
coverage improves substantially, but seven-letter coverage falls. No metric was
hidden by changing generator validity or content.

All three 30-puzzle runs passed independent strict validation and cooldown checks.
Detailed reproducible output, including every support ID offered, follows. Timing
is local observation only, never a stopping rule or correctness assertion.

```text
# Catalogue v3 stress report — balanced=false, bounded=true

Catalogue v3: 300 entries; 300 unique; issues [].
Difficulty: {WordDifficulty.easy: 210, WordDifficulty.medium: 75, WordDifficulty.hard: 15}; lengths: {4: 68, 5: 102, 6: 99, 7: 31}.
Tags (multi-tag entries counted in each): {action: 28, adjective: 17, animal: 28, body: 15, clothing: 12, color: 4, concept: 4, drink: 2, emotion: 2, family: 9, food: 38, home: 39, nature: 40, number: 4, object: 1, people: 18, place: 15, school: 5, sport: 3, technology: 4, time: 10, transport: 8, weather: 10, work: 10}.
A–Z occurrences: {A: 140, B: 41, C: 71, D: 41, E: 206, F: 33, G: 30, H: 65, I: 83, J: 2, K: 35, L: 84, M: 39, N: 91, O: 125, P: 46, Q: 1, R: 145, S: 87, T: 120, U: 38, V: 17, W: 31, X: 1, Y: 19, Z: 2}.
Crossing partners min / average / max: 145 / 252.35 / 295; zero: [].
Bottom 10: DUCK:145, BOOK:150, BABY:157, WIND:168, HILL:175, MOON:175, MILK:176, FOLLOW:178, WOLF:178, FOOT:184.
Top 10: COURAGE:295, STATION:293, ORANGE:292, APRICOT:291, OCEAN:290, BLANKET:289, BROTHER:289, RAINBOW:289, SEASON:289, CURTAIN:287.

## Sequence

Base seed 20261003; cooldown 5; count 30. No relaxation. Timing is local diagnostic only, around generateNext.

| Index | ID | Seed | Eligible | Generation pool | Tiers | Attempts | Score | Crossings | Leaves | Rows×cols | Density | ms (all attempts) | Checks (all attempts) | Nodes (final attempt) | Complete (final attempt) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | generated-v3-000001 | 3255270515 | 300 | 300 | [] | 1 | 4216 | 12 | 1 | 9×8 | 0.5833 | 807 | 4000000 | 6352 | 1008 |
| 2 | generated-v3-000002 | 3017514609 | 290 | 290 | [] | 1 | 4195 | 12 | 1 | 9×8 | 0.5972 | 654 | 4000000 | 6694 | 842 |
| 3 | generated-v3-000003 | 4063561778 | 280 | 280 | [] | 1 | 3963 | 12 | 2 | 10×9 | 0.5444 | 650 | 4000000 | 6413 | 926 |
| 4 | generated-v3-000004 | 4080171169 | 270 | 270 | [] | 1 | 3708 | 11 | 2 | 9×8 | 0.5833 | 607 | 4000000 | 6693 | 598 |
| 5 | generated-v3-000005 | 212570333 | 260 | 260 | [] | 1 | 4316 | 12 | 1 | 10×7 | 0.6286 | 779 | 4000000 | 7369 | 1404 |
| 6 | generated-v3-000006 | 2351277153 | 250 | 250 | [] | 1 | 4088 | 12 | 2 | 10×8 | 0.5625 | 606 | 4000000 | 6879 | 506 |
| 7 | generated-v3-000007 | 122973788 | 250 | 250 | [] | 1 | 3611 | 11 | 2 | 9×9 | 0.5432 | 808 | 4000000 | 7377 | 1342 |
| 8 | generated-v3-000008 | 3616392535 | 250 | 250 | [] | 1 | 4187 | 12 | 0 | 9×9 | 0.5802 | 1014 | 4000000 | 8624 | 2710 |
| 9 | generated-v3-000009 | 1200630159 | 250 | 250 | [] | 1 | 4066 | 12 | 1 | 9×9 | 0.5556 | 706 | 4000000 | 7227 | 1192 |
| 10 | generated-v3-000010 | 3356167200 | 250 | 250 | [] | 1 | 3135 | 10 | 2 | 10×9 | 0.5000 | 829 | 4000000 | 7828 | 1254 |
| 11 | generated-v3-000011 | 3448742630 | 250 | 250 | [] | 1 | 4086 | 12 | 1 | 9×9 | 0.6173 | 707 | 4000000 | 6931 | 932 |
| 12 | generated-v3-000012 | 3722140078 | 250 | 250 | [] | 1 | 4651 | 13 | 0 | 10×8 | 0.5750 | 673 | 4000000 | 7085 | 930 |
| 13 | generated-v3-000013 | 3296970215 | 250 | 250 | [] | 1 | 4156 | 12 | 1 | 10×8 | 0.5625 | 595 | 4000000 | 6597 | 574 |
| 14 | generated-v3-000014 | 3191423739 | 250 | 250 | [] | 1 | 4646 | 13 | 0 | 10×8 | 0.5500 | 610 | 4000000 | 7314 | 768 |
| 15 | generated-v3-000015 | 1586798619 | 250 | 250 | [] | 1 | 4447 | 13 | 1 | 10×9 | 0.5222 | 838 | 4000000 | 7755 | 1614 |
| 16 | generated-v3-000016 | 3309678214 | 250 | 250 | [] | 1 | 4055 | 12 | 1 | 10×9 | 0.5222 | 789 | 4000000 | 7427 | 872 |
| 17 | generated-v3-000017 | 1709764501 | 250 | 250 | [] | 1 | 3587 | 11 | 2 | 9×9 | 0.5432 | 718 | 4000000 | 7571 | 1166 |
| 18 | generated-v3-000018 | 1267087583 | 250 | 250 | [] | 1 | 3696 | 11 | 2 | 10×8 | 0.5625 | 796 | 4000000 | 7525 | 1526 |
| 19 | generated-v3-000019 | 642745423 | 250 | 250 | [] | 1 | 4270 | 12 | 0 | 10×8 | 0.5500 | 908 | 4000000 | 8396 | 2078 |
| 20 | generated-v3-000020 | 2432605180 | 250 | 250 | [] | 1 | 4003 | 12 | 2 | 9×9 | 0.5802 | 648 | 4000000 | 8104 | 808 |
| 21 | generated-v3-000021 | 2039714612 | 250 | 250 | [] | 1 | 4151 | 12 | 1 | 10×8 | 0.5375 | 867 | 4000000 | 7661 | 1696 |
| 22 | generated-v3-000022 | 3891639982 | 250 | 250 | [] | 1 | 4159 | 12 | 1 | 10×8 | 0.5750 | 666 | 4000000 | 7723 | 1046 |
| 23 | generated-v3-000023 | 2347641815 | 250 | 250 | [] | 1 | 4037 | 12 | 1 | 10×9 | 0.5111 | 664 | 4000000 | 7488 | 1124 |
| 24 | generated-v3-000024 | 3386510391 | 250 | 250 | [] | 1 | 3675 | 11 | 2 | 10×8 | 0.5375 | 620 | 4000000 | 7546 | 642 |
| 25 | generated-v3-000025 | 3020097767 | 250 | 250 | [] | 1 | 4389 | 13 | 1 | 10×9 | 0.5111 | 593 | 4000000 | 7110 | 712 |
| 26 | generated-v3-000026 | 3535478817 | 250 | 250 | [] | 1 | 3695 | 11 | 1 | 9×9 | 0.5802 | 601 | 4000000 | 7198 | 720 |
| 27 | generated-v3-000027 | 382374061 | 250 | 250 | [] | 1 | 3671 | 11 | 1 | 9×9 | 0.5432 | 886 | 4000000 | 6965 | 1676 |
| 28 | generated-v3-000028 | 1858263009 | 250 | 250 | [] | 1 | 3547 | 11 | 2 | 10×9 | 0.5222 | 835 | 4000000 | 8013 | 1620 |
| 29 | generated-v3-000029 | 2410942209 | 250 | 250 | [] | 1 | 3175 | 10 | 3 | 10×8 | 0.5375 | 575 | 4000000 | 6510 | 256 |
| 30 | generated-v3-000030 | 665389888 | 250 | 250 | [] | 1 | 4074 | 12 | 1 | 9×9 | 0.5556 | 553 | 4000000 | 6547 | 310 |

Answers and attempt outcomes:
- 1: BROTHER, ROOM, RAIN, UNCLE, HOME, MOON, FACE, EXAM, MEAT, FARM; cooldown excluded 0; min usage null; widened false; tiers=[], pool=300, success
- 2: FRIDGE, KNEE, ONION, DOOR, BIRD, GOAT, ROBOT, FOUR, AUNT, DIRTY; cooldown excluded 10; min usage null; widened false; tiers=[], pool=290, success
- 3: SCHOOL, SOAP, PEPPER, CHESS, LARGE, SMILE, DRESS, DOLPHIN, NECK, BEAR; cooldown excluded 20; min usage null; widened false; tiers=[], pool=280, success
- 4: BABY, BOOK, BOAT, SOFA, TREE, LAKE, CITY, RABBIT, ZEBRA, FIRE; cooldown excluded 30; min usage null; widened false; tiers=[], pool=270, success
- 5: APPLE, LEAF, PEAR, PAPER, FORK, RACE, CAMERA, SHEEP, BRUSH, BACK; cooldown excluded 40; min usage null; widened false; tiers=[], pool=260, success
- 6: KETTLE, CAKE, DANGER, HORSE, NIGHT, LION, LEND, TABLE, FIVE, COMB; cooldown excluded 50; min usage null; widened false; tiers=[], pool=250, success
- 7: HEALTH, WEEK, WAVE, MEAT, MOON, NOSE, HOME, HAMMER, LEARN, BANK; cooldown excluded 50; min usage null; widened false; tiers=[], pool=250, success
- 8: FRIEND, READ, TURTLE, TRAIN, FROG, GRASS, NURSE, RICE, MUSEUM, EXAM; cooldown excluded 50; min usage null; widened false; tiers=[], pool=250, success
- 9: INSECT, SALT, BANANA, FACE, RAIN, SEED, LEMON, CLOCK, SKIRT, AUNT; cooldown excluded 50; min usage null; widened false; tiers=[], pool=250, success
- 10: FROST, ROOF, SOCK, COAT, CITY, WOLF, SNOW, FOOT, AIRPORT, SCARF; cooldown excluded 50; min usage null; widened false; tiers=[], pool=250, success
- 11: HARVEST, HAIR, RACE, KITCHEN, SAND, BOAT, TOMATO, LEAVE, BICYCLE, BABY; cooldown excluded 50; min usage null; widened false; tiers=[], pool=250, success
- 12: BROTHER, TREE, SHIRT, STAR, EIGHT, ROAD, PANDA, HONEY, HAPPY, BEACH; cooldown excluded 50; min usage null; widened false; tiers=[], pool=250, success
- 13: HORSE, LAKE, BEAR, CAMERA, PEACH, SHOP, PILOT, OLIVE, BAKER, COMB; cooldown excluded 50; min usage null; widened false; tiers=[], pool=250, success
- 14: SEASON, RICE, FIVE, CHESS, MOON, HOME, SOUP, PARROT, ONION, ANGRY; cooldown excluded 50; min usage null; widened false; tiers=[], pool=250, success
- 15: PUMPKIN, LION, SOAP, HOTEL, TICKET, HAMMER, RETURN, SOFA, KNEE, CAKE; cooldown excluded 50; min usage null; widened false; tiers=[], pool=250, success
- 16: SUNSET, SOIL, WRITE, FATHER, LEAF, MELON, HOUSE, SHOE, MIRROR, RAIN; cooldown excluded 50; min usage null; widened false; tiers=[], pool=250, success
- 17: BABY, BANK, BACK, CANDLE, DEER, CITY, SKIRT, PASTA, GRAPE, GOAT; cooldown excluded 50; min usage null; widened false; tiers=[], pool=250, success
- 18: CHILD, LEND, TREE, WATCH, TOWEL, COAT, WATER, LARGE, BREAD, BIRD; cooldown excluded 50; min usage null; widened false; tiers=[], pool=250, success
- 19: SCREEN, HAIR, SCHOOL, CLEAN, STAR, ROOT, EARTH, HEAD, READ, RACE; cooldown excluded 50; min usage null; widened false; tiers=[], pool=250, success
- 20: BUTTON, MOON, POTATO, SALT, YOGURT, STONE, OCEAN, SPOON, AUNT, SAND; cooldown excluded 50; min usage null; widened false; tiers=[], pool=250, success
- 21: PAPER, DOOR, SALAD, SHOP, SLEEP, EXAM, PEAR, APPLE, TIGER, BOAT; cooldown excluded 50; min usage null; widened false; tiers=[], pool=250, success
- 22: WEALTH, WALL, WAVE, BANANA, PEACH, WIND, NIGHT, ANGRY, YOUNG, FROG; cooldown excluded 50; min usage null; widened false; tiers=[], pool=250, success
- 23: KETTLE, BOOK, BREEZE, LEAVE, HEART, LAKE, OLIVE, EAGLE, KNEE, BEAR; cooldown excluded 50; min usage null; widened false; tiers=[], pool=250, success
- 24: CLOCK, CITY, MOUTH, COMB, HILL, BANK, ISLAND, DUCK, FISH, FACE; cooldown excluded 50; min usage null; widened false; tiers=[], pool=250, success
- 25: ALMOND, FARM, SEASON, BROWN, PASTA, BABY, LEAF, FROST, DIRTY, ONION; cooldown excluded 50; min usage null; widened false; tiers=[], pool=250, success
- 26: COFFEE, CAKE, WOLF, TODAY, FOUR, HAIR, OCEAN, UNCLE, STUDENT, AUNT; cooldown excluded 50; min usage null; widened false; tiers=[], pool=250, success
- 27: RETURN, FIVE, PILLOW, DOOR, RICE, COAT, TRAIN, NOSE, DEER, BIRD; cooldown excluded 50; min usage null; widened false; tiers=[], pool=250, success
- 28: WIND, MOON, SHOE, WAVE, DRESS, INVITE, DOLPHIN, WISDOM, EXAM, RACE; cooldown excluded 50; min usage null; widened false; tiers=[], pool=250, success
- 29: FARMER, ROOT, ROOM, MEAT, FIRE, HOME, SOFA, ROOF, CHAIR, RAIN; cooldown excluded 50; min usage null; widened false; tiers=[], pool=250, success
- 30: DRAWER, LEND, LEARN, SNAKE, PANDA, SOCK, COMB, WEEK, CAMERA, READ; cooldown excluded 50; min usage null; widened false; tiers=[], pool=250, success
Attempts min / average / max: 1 / 1.00 / 1.
Support diagnostics:
- 1: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 2: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 3: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 4: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 5: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 6: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 7: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 8: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 9: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 10: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 11: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 12: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 13: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 14: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 15: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 16: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 17: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 18: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 19: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 20: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 21: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 22: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 23: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 24: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 25: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 26: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 27: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 28: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 29: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
- 30: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers []; selected target/support 0/10; success
Chosen support-size histogram: {0: 30}; target/support answers average: 0.0/10.0.

PASS: 30/30 complete; independent strict validation passed; all phantom adjacencies and unexplained runs = 0; cooldown checked by both IDs and solutions.
Scores min / average / max: 3135 / 3988.50 / 4651; lowest indices [10]; highest indices [12].
Crossings min / average / max: 10 / 11.73 / 13; maximum leaves 3.
Visible widths: {7: 1, 8: 13, 9: 16}; dimensions: {10×7: 1, 10×8: 10, 10×9: 7, 9×8: 3, 9×9: 9}.
Rows min / average / max: 9 / 9.60 / 10; columns: 7 / 8.50 / 9; density: 0.5 / 0.56 / 0.6285714285714286.
10-column boards (index:score:density): .
Time ms min / average / max: 553 / 720.07 / 1014; total 21602 ms.
Candidate checks min / average / max: 4000000 / 4000000.00 / 4000000.

## Usage

Unique 175 / 300; coverage 58.33%; slots 300.
Usage frequency → number of words: {0: 125, 1: 91, 2: 53, 3: 22, 4: 8, 5: 1}.
Top 15: MOON:5, AUNT:4, BABY:4, CITY:4, COMB:4, EXAM:4, HOME:4, RACE:4, RAIN:4, BANK:3, BEAR:3, BIRD:3, BOAT:3, CAKE:3, CAMERA:3.
Repeat distance min / average / max: 6 / 11.76 / 28. Average is over consecutive reuse events, not per-word averages.
Never used (125): ANCIENT, ANSWER, APRICOT, ARRIVE, ARTIST, AUTUMN, BASKET, BELIEVE, BLACK, BLANKET, BORROW, BOTTLE, BRANCH, BRAVE, BREATHE, BRIDGE, BUCKET, BUTTER, CABBAGE, CAMEL, CARPET, CARROT, CARRY, CASTLE, CATCH, CEILING, CHEESE, CHERRY, CHICKEN, CHOOSE, CLIMB, CLOUD, COAST, COOKIE, COTTON, COURAGE, COUSIN, CURTAIN, DESERT, DESERVE, DOCTOR, DONKEY, DRIVER, EMPTY, ENOUGH, FEATHER, FINGER, FLOOR, FLOUR, FLOWER, FOLLOW, FOREST, FORGET, GARDEN, GARLIC, GLOVE, GREEN, HAND, HEAVY, JACKET, JUICE, KNIFE, LESSON, LIBRARY, LIGHT, LISTEN, MARKET, MILK, MONKEY, MONTH, MOTHER, MOUSE, NARROW, NEEDLE, OFFICE, ORANGE, PEANUT, PENCIL, PHONE, PLANE, PLANET, PLANT, PLATE, POCKET, POLITE, PROMISE, QUIET, RAINBOW, REPAIR, RIVER, SALARY, SEARCH, SEVEN, SHALLOW, SHARE, SHARK, SHELF, SHELTER, SISTER, SMALL, SMOOTH, SPACE, SPIDER, SPRING, STATION, STORM, STREAM, STREET, SUGAR, SUMMER, TEACHER, TENNIS, THROW, THUNDER, TOOTH, TRUCK, VALLEY, VILLAGE, WALNUT, WHALE, WHISPER, WHITE, WINDOW, WINTER, WRINKLE.

## App Puzzle 1

generated-v3-000001; seed 3255270515; bounds rows 1–9, columns 1–8; 807 ms.

- BROTHER — Erkek kardeş — down — start(2,5) — clue(1,5)
- ROOM — Oda — right — start(8,5) — clue(8,4)
- RAIN — Yağmur — right — start(3,5) — clue(3,4)
- UNCLE — Amca veya dayı — down — start(2,8) — clue(1,8)
- HOME — Yuva — right — start(6,5) — clue(6,4)
- MOON — Ay — down — start(6,7) — clue(5,7)
- FACE — Yüz — right — start(7,2) — clue(7,1)
- EXAM — Sınav — down — start(5,3) — clue(4,3)
- MEAT — Et — right — start(5,2) — clue(5,1)
- FARM — Çiftlik — down — start(2,2) — clue(1,2)
Difficulty slots: {easy: 264, hard: 4, medium: 32}; unique: {easy: 148, hard: 4, medium: 23}.
Length slots: {4: 158, 5: 87, 6: 45, 7: 10}; unique: {4: 66, 5: 64, 6: 37, 7: 8}.
Length 4 coverage: 66/68 (97.06%).
Length 5 coverage: 64/102 (62.75%).
Length 6 coverage: 37/99 (37.37%).
Length 7 coverage: 8/31 (25.81%).
# Catalogue v3 stress report — balanced=true, bounded=false

Catalogue v3: 300 entries; 300 unique; issues [].
Difficulty: {WordDifficulty.easy: 210, WordDifficulty.medium: 75, WordDifficulty.hard: 15}; lengths: {4: 68, 5: 102, 6: 99, 7: 31}.
Tags (multi-tag entries counted in each): {action: 28, adjective: 17, animal: 28, body: 15, clothing: 12, color: 4, concept: 4, drink: 2, emotion: 2, family: 9, food: 38, home: 39, nature: 40, number: 4, object: 1, people: 18, place: 15, school: 5, sport: 3, technology: 4, time: 10, transport: 8, weather: 10, work: 10}.
A–Z occurrences: {A: 140, B: 41, C: 71, D: 41, E: 206, F: 33, G: 30, H: 65, I: 83, J: 2, K: 35, L: 84, M: 39, N: 91, O: 125, P: 46, Q: 1, R: 145, S: 87, T: 120, U: 38, V: 17, W: 31, X: 1, Y: 19, Z: 2}.
Crossing partners min / average / max: 145 / 252.35 / 295; zero: [].
Bottom 10: DUCK:145, BOOK:150, BABY:157, WIND:168, HILL:175, MOON:175, MILK:176, FOLLOW:178, WOLF:178, FOOT:184.
Top 10: COURAGE:295, STATION:293, ORANGE:292, APRICOT:291, OCEAN:290, BLANKET:289, BROTHER:289, RAINBOW:289, SEASON:289, CURTAIN:287.

## Sequence

Base seed 20261003; cooldown 5; count 30. No relaxation. Timing is local diagnostic only, around generateNext.

| Index | ID | Seed | Eligible | Generation pool | Tiers | Attempts | Score | Crossings | Leaves | Rows×cols | Density | ms (all attempts) | Checks (all attempts) | Nodes (final attempt) | Complete (final attempt) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | generated-v3-000001 | 3255270515 | 300 | 300 | [0] | 1 | 4216 | 12 | 1 | 9×8 | 0.5833 | 707 | 4000000 | 6352 | 1008 |
| 2 | generated-v3-000002 | 3017514609 | 290 | 290 | [0] | 1 | 4195 | 12 | 1 | 9×8 | 0.5972 | 673 | 4000000 | 6694 | 842 |
| 3 | generated-v3-000003 | 4063561778 | 280 | 280 | [0] | 1 | 3963 | 12 | 2 | 10×9 | 0.5444 | 712 | 4000000 | 6413 | 926 |
| 4 | generated-v3-000004 | 4080171169 | 270 | 270 | [0] | 1 | 3708 | 11 | 2 | 9×8 | 0.5833 | 566 | 4000000 | 6693 | 598 |
| 5 | generated-v3-000005 | 212570333 | 260 | 260 | [0] | 1 | 4316 | 12 | 1 | 10×7 | 0.6286 | 760 | 4000000 | 7369 | 1404 |
| 6 | generated-v3-000006 | 2351277153 | 250 | 250 | [0] | 1 | 4088 | 12 | 2 | 10×8 | 0.5625 | 601 | 4000000 | 6879 | 506 |
| 7 | generated-v3-000007 | 122973788 | 250 | 240 | [0] | 1 | 4189 | 12 | 1 | 10×8 | 0.5250 | 697 | 4000000 | 7599 | 1342 |
| 8 | generated-v3-000008 | 3616392535 | 250 | 230 | [0] | 1 | 3708 | 11 | 1 | 9×9 | 0.5679 | 662 | 4000000 | 7582 | 686 |
| 9 | generated-v3-000009 | 1200630159 | 250 | 220 | [0] | 1 | 3633 | 11 | 1 | 10×9 | 0.5333 | 773 | 4000000 | 8109 | 1118 |
| 10 | generated-v3-000010 | 3356167200 | 250 | 210 | [0] | 1 | 3143 | 10 | 2 | 10×9 | 0.5000 | 491 | 4000000 | 7679 | 102 |
| 11 | generated-v3-000011 | 3448742630 | 250 | 200 | [0] | 1 | 3336 | 11 | 3 | 10×10 | 0.5000 | 524 | 4000000 | 8292 | 278 |
| 12 | generated-v3-000012 | 3722140078 | 250 | 190 | [0] | 1 | 3587 | 11 | 2 | 9×9 | 0.5802 | 781 | 4000000 | 8874 | 1030 |
| 13 | generated-v3-000013 | 3296970215 | 250 | 180 | [0] | 1 | 4025 | 12 | 1 | 10×9 | 0.5333 | 636 | 4000000 | 9231 | 688 |
| 14 | generated-v3-000014 | 3191423739 | 250 | 170 | [0] | 1 | 3562 | 11 | 2 | 10×9 | 0.5556 | 613 | 4000000 | 9408 | 322 |
| 15 | generated-v3-000015 | 1586798619 | 250 | 250 | [0, 1] | 2 | 4063 | 12 | 1 | 10×9 | 0.5222 | 1174 | 8000000 | 7225 | 778 |
| 16 | generated-v3-000016 | 3309678214 | 250 | 155 | [0] | 1 | 3346 | 11 | 3 | 10×10 | 0.5300 | 582 | 4000000 | 9926 | 498 |
| 17 | generated-v3-000017 | 1709764501 | 250 | 250 | [0, 1] | 2 | 4203 | 12 | 1 | 9×8 | 0.5972 | 1382 | 7700427 | 8395 | 2334 |
| 18 | generated-v3-000018 | 1267087583 | 250 | 250 | [0, 1] | 2 | 3690 | 11 | 1 | 9×9 | 0.5556 | 1193 | 7702077 | 7948 | 1082 |
| 19 | generated-v3-000019 | 642745423 | 250 | 143 | [0] | 1 | 3350 | 11 | 3 | 10×10 | 0.5500 | 457 | 3696933 | 10000 | 162 |
| 20 | generated-v3-000020 | 2432605180 | 250 | 133 | [0] | 1 | 3806 | 12 | 2 | 10×10 | 0.5100 | 469 | 3424680 | 10000 | 426 |
| 21 | generated-v3-000021 | 2039714612 | 250 | 245 | [0, 1] | 2 | 4103 | 12 | 1 | 9×9 | 0.5432 | 1074 | 7254457 | 7550 | 818 |
| 22 | generated-v3-000022 | 3891639982 | 250 | 245 | [0, 1] | 2 | 3951 | 12 | 2 | 10×9 | 0.5222 | 1233 | 7269973 | 7885 | 1444 |
| 23 | generated-v3-000023 | 2347641815 | 250 | 117 | [0] | 1 | 3912 | 12 | 1 | 10×10 | 0.5200 | 445 | 2948467 | 10000 | 374 |
| 24 | generated-v3-000024 | 3386510391 | 250 | 107 | [0] | 1 | 3963 | 12 | 2 | 10×9 | 0.6000 | 372 | 2786744 | 10000 | 16 |
| 25 | generated-v3-000025 | 3020097767 | 250 | 227 | [0, 1] | 2 | 4077 | 12 | 2 | 10×8 | 0.5875 | 1392 | 6492853 | 8209 | 1190 |
| 26 | generated-v3-000026 | 3535478817 | 250 | 94 | [0] | 1 | 2946 | 10 | 3 | 10×10 | 0.5700 | 323 | 2337556 | 10000 | 132 |
| 27 | generated-v3-000027 | 382374061 | 250 | 220 | [0, 1] | 2 | 3254 | 10 | 2 | 10×8 | 0.5125 | 871 | 6219694 | 8380 | 426 |
| 28 | generated-v3-000028 | 1858263009 | 250 | 213 | [0, 1] | 2 | 3838 | 11 | 1 | 9×8 | 0.6528 | 951 | 6222656 | 8577 | 840 |
| 29 | generated-v3-000029 | 2410942209 | 250 | 83 | [0] | 1 | 3424 | 11 | 2 | 10×10 | 0.5400 | 407 | 2092581 | 10000 | 340 |
| 30 | generated-v3-000030 | 665389888 | 250 | 213 | [0, 1] | 2 | 3592 | 11 | 2 | 9×9 | 0.5679 | 1641 | 5830582 | 8734 | 760 |

Answers and attempt outcomes:
- 1: BROTHER, ROOM, RAIN, UNCLE, HOME, MOON, FACE, EXAM, MEAT, FARM; cooldown excluded 0; min usage 0; widened false; tiers=[0], pool=300, success
- 2: FRIDGE, KNEE, ONION, DOOR, BIRD, GOAT, ROBOT, FOUR, AUNT, DIRTY; cooldown excluded 10; min usage 0; widened false; tiers=[0], pool=290, success
- 3: SCHOOL, SOAP, PEPPER, CHESS, LARGE, SMILE, DRESS, DOLPHIN, NECK, BEAR; cooldown excluded 20; min usage 0; widened false; tiers=[0], pool=280, success
- 4: BABY, BOOK, BOAT, SOFA, TREE, LAKE, CITY, RABBIT, ZEBRA, FIRE; cooldown excluded 30; min usage 0; widened false; tiers=[0], pool=270, success
- 5: APPLE, LEAF, PEAR, PAPER, FORK, RACE, CAMERA, SHEEP, BRUSH, BACK; cooldown excluded 40; min usage 0; widened false; tiers=[0], pool=260, success
- 6: KETTLE, CAKE, DANGER, HORSE, NIGHT, LION, LEND, TABLE, FIVE, COMB; cooldown excluded 50; min usage 0; widened false; tiers=[0], pool=250, success
- 7: SALT, SOCK, COAT, LEARN, SNOW, FOOT, PASTA, LESSON, HILL, SHOP; cooldown excluded 50; min usage 0; widened false; tiers=[0], pool=240, success
- 8: WIND, DUCK, WALL, CLOCK, GREEN, HAIR, SHOE, GLOVE, VILLAGE, EAGLE; cooldown excluded 50; min usage 0; widened false; tiers=[0], pool=230, success
- 9: MARKET, RICE, SEED, MOUSE, THROW, FROG, TIGER, MILK, ANCIENT, PANDA; cooldown excluded 50; min usage 0; widened false; tiers=[0], pool=220, success
- 10: SPACE, STAR, RIVER, CAMEL, SOUP, WAVE, NURSE, NOSE, BANK, SKIRT; cooldown excluded 50; min usage 0; widened false; tiers=[0], pool=210, success
- 11: TURTLE, SOIL, PILLOW, SALARY, POTATO, FISH, WOLF, EIGHT, SUGAR, CARRY; cooldown excluded 50; min usage 0; widened false; tiers=[0], pool=200, success
- 12: FROST, DEER, ROOT, SEASON, SAND, ORANGE, FLOUR, HEAD, EARTH, BRAVE; cooldown excluded 50; min usage 0; widened false; tiers=[0], pool=190, success
- 13: HEART, HAND, READ, BANANA, CLIMB, CHAIR, WHITE, LIGHT, WEALTH, HAPPY; cooldown excluded 50; min usage 0; widened false; tiers=[0], pool=180, success
- 14: HEALTH, ROAD, GARDEN, MONTH, WISDOM, TRAIN, LEMON, HOTEL, WATER, WEEK; cooldown excluded 50; min usage 0; widened false; tiers=[0], pool=170, success
- 15: RAINBOW, ROOF, FOUR, WINTER, TOWEL, EAGLE, WRITE, PANDA, EXAM, BEAR; cooldown excluded 50; min usage 0; widened true; tiers=[0], pool=160, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=250, success
- 16: PLATE, OCEAN, BLACK, PUMPKIN, BROWN, SNAKE, SLEEP, DESERT, CARPET, TODAY; cooldown excluded 50; min usage 0; widened false; tiers=[0], pool=155, success
- 17: DRESS, RAIN, UNCLE, SOIL, TREE, LARGE, SALAD, CHESS, FISH, FACE; cooldown excluded 50; min usage 0; widened true; tiers=[0], pool=145, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=250, success
- 18: SHOP, SOAP, PEAR, PASTA, RICE, FIRE, EARTH, ROBOT, DESERVE, ROOM; cooldown excluded 50; min usage 0; widened true; tiers=[0], pool=144, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=250, success
- 19: CHEESE, PLANE, PHONE, COURAGE, SHELF, GRAPE, SPOON, PENCIL, CATCH, STATION; cooldown excluded 50; min usage 0; widened false; tiers=[0], pool=143, success
- 20: SEVEN, EMPTY, SHARE, HEAVY, AIRPORT, WATCH, CLEAN, BRIDGE, OLIVE, FLOOR; cooldown excluded 50; min usage 0; widened false; tiers=[0], pool=133, success
- 21: FOREST, SALT, HAIR, HOUSE, ROOF, SOFA, SNOW, WINDOW, ONION, KNEE; cooldown excluded 50; min usage 0; widened true; tiers=[0], pool=123, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=245, success
- 22: FEATHER, FORK, REPAIR, DEER, APPLE, MEAT, WAVE, TABLE, PILOT, PAPER; cooldown excluded 50; min usage 0; widened true; tiers=[0], pool=120, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=245, success
- 23: SUMMER, MELON, POLITE, BREEZE, KNIFE, STORM, GRASS, CARROT, SMALL, LEAVE; cooldown excluded 50; min usage 0; widened false; tiers=[0], pool=117, success
- 24: OFFICE, MOUTH, TENNIS, CHILD, SPIDER, STONE, SCARF, SUNSET, ALMOND, DOCTOR; cooldown excluded 50; min usage 0; widened false; tiers=[0], pool=107, success
- 25: CABBAGE, COAT, BIRD, APRICOT, GLOVE, SEED, HOME, COMB, BEACH, ZEBRA; cooldown excluded 50; min usage 0; widened true; tiers=[0], pool=97, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=227, success
- 26: TOOTH, TRUCK, HONEY, AUTUMN, BAKER, SHIRT, CURTAIN, BUCKET, WHISPER, RETURN; cooldown excluded 50; min usage 0; widened false; tiers=[0], pool=94, success
- 27: FARM, DOOR, LEAF, LEMON, MOON, AUNT, ROOT, STAR, NECK, BACK; cooldown excluded 50; min usage 0; widened true; tiers=[0], pool=84, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=220, success
- 28: NOSE, RACE, LION, LEARN, CAKE, WEEK, OCEAN, ANCIENT, CEILING, FIVE; cooldown excluded 50; min usage 0; widened true; tiers=[0], pool=84, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=213, success
- 29: ARTIST, COAST, PLANT, PEACH, BREAD, STREAM, SHARK, COOKIE, BREATHE, QUIET; cooldown excluded 50; min usage 0; widened false; tiers=[0], pool=83, success
- 30: SHELTER, HAND, SNAKE, LAKE, READ, FOOT, PILOT, WHITE, BROWN, BABY; cooldown excluded 50; min usage 0; widened true; tiers=[0], pool=73, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=213, success
Attempts min / average / max: 1 / 1.30 / 2.
Support diagnostics:
- 1: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/10; success
- 2: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/10; success
- 3: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/10; success
- 4: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/10; success
- 5: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/10; success
- 6: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/10; success
- 7: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/10; success
- 8: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/10; success
- 9: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/10; success
- 10: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/10; success
- 11: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/10; success
- 12: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/10; success
- 13: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/10; success
- 14: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/10; success
- 15: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 0; ids []; tiers [0, 1]; selected target/support 0/10; success
- 16: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/10; success
- 17: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 0; ids []; tiers [0, 1]; selected target/support 0/10; success
- 18: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 0; ids []; tiers [0, 1]; selected target/support 0/10; success
- 19: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/10; success
- 20: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/10; success
- 21: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 0; ids []; tiers [0, 1]; selected target/support 0/10; success
- 22: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 0; ids []; tiers [0, 1]; selected target/support 0/10; success
- 23: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/10; success
- 24: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/10; success
- 25: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 0; ids []; tiers [0, 1]; selected target/support 0/10; success
- 26: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/10; success
- 27: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 0; ids []; tiers [0, 1]; selected target/support 0/10; success
- 28: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 0; ids []; tiers [0, 1]; selected target/support 0/10; success
- 29: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/10; success
- 30: target pool 0; candidates 0; offered []; selected target/support 0/10; successes 1; First valid complete tier.
  stage: support 0; ids []; tiers [0]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 0; ids []; tiers [0, 1]; selected target/support 0/10; success
Chosen support-size histogram: {0: 30}; target/support answers average: 0.0/10.0.

PASS: 30/30 complete; independent strict validation passed; all phantom adjacencies and unexplained runs = 0; cooldown checked by both IDs and solutions.
Scores min / average / max: 2946 / 3772.90 / 4316; lowest indices [26]; highest indices [5].
Crossings min / average / max: 10 / 11.40 / 12; maximum leaves 3.
Visible widths: {7: 1, 8: 9, 9: 13, 10: 7}; dimensions: {10×10: 7, 10×7: 1, 10×8: 4, 10×9: 8, 9×8: 5, 9×9: 5}.
Rows min / average / max: 9 / 9.67 / 10; columns: 7 / 8.87 / 10; density: 0.5 / 0.56 / 0.6527777777777778.
10-column boards (index:score:density): 11:3336:0.5000, 16:3346:0.5300, 19:3350:0.5500, 20:3806:0.5100, 23:3912:0.5200, 26:2946:0.5700, 29:3424:0.5400.
Time ms min / average / max: 323 / 772.07 / 1641; total 23162 ms.
Candidate checks min / average / max: 2092581 / 4665989.33 / 8000000.

## Usage

Unique 228 / 300; coverage 76.00%; slots 300.
Usage frequency → number of words: {0: 72, 1: 156, 2: 72}.
Top 15: ANCIENT:2, APPLE:2, AUNT:2, BABY:2, BACK:2, BEAR:2, BIRD:2, BROWN:2, CAKE:2, CHESS:2, COAT:2, COMB:2, DEER:2, DOOR:2, DRESS:2.
Repeat distance min / average / max: 6 / 16.38 / 26. Average is over consecutive reuse events, not per-word averages.
Never used (72): ANGRY, ANSWER, ARRIVE, BASKET, BELIEVE, BICYCLE, BLANKET, BORROW, BOTTLE, BRANCH, BUTTER, BUTTON, CANDLE, CASTLE, CHERRY, CHICKEN, CHOOSE, CLOUD, COFFEE, COTTON, COUSIN, DONKEY, DRAWER, DRIVER, ENOUGH, FARMER, FATHER, FINGER, FLOWER, FOLLOW, FORGET, FRIEND, GARLIC, HAMMER, HARVEST, INSECT, INVITE, ISLAND, JACKET, JUICE, KITCHEN, LIBRARY, LISTEN, MIRROR, MONKEY, MOTHER, MUSEUM, NARROW, NEEDLE, PARROT, PEANUT, PLANET, POCKET, PROMISE, SCREEN, SEARCH, SHALLOW, SISTER, SMOOTH, SPRING, STREET, STUDENT, TEACHER, THUNDER, TICKET, TOMATO, VALLEY, WALNUT, WHALE, WRINKLE, YOGURT, YOUNG.

## App Puzzle 1

generated-v3-000001; seed 3255270515; bounds rows 1–9, columns 1–8; 707 ms.

- BROTHER — Erkek kardeş — down — start(2,5) — clue(1,5)
- ROOM — Oda — right — start(8,5) — clue(8,4)
- RAIN — Yağmur — right — start(3,5) — clue(3,4)
- UNCLE — Amca veya dayı — down — start(2,8) — clue(1,8)
- HOME — Yuva — right — start(6,5) — clue(6,4)
- MOON — Ay — down — start(6,7) — clue(5,7)
- FACE — Yüz — right — start(7,2) — clue(7,1)
- EXAM — Sınav — down — start(5,3) — clue(4,3)
- MEAT — Et — right — start(5,2) — clue(5,1)
- FARM — Çiftlik — down — start(2,2) — clue(1,2)
Difficulty slots: {easy: 239, hard: 11, medium: 50}; unique: {easy: 172, hard: 10, medium: 46}.
Length slots: {4: 117, 5: 119, 6: 45, 7: 19}; unique: {4: 68, 5: 97, 6: 45, 7: 18}.
Length 4 coverage: 68/68 (100.00%).
Length 5 coverage: 97/102 (95.10%).
Length 6 coverage: 45/99 (45.45%).
Length 7 coverage: 18/31 (58.06%).
# Catalogue v3 stress report — balanced=true, bounded=true

Catalogue v3: 300 entries; 300 unique; issues [].
Difficulty: {WordDifficulty.easy: 210, WordDifficulty.medium: 75, WordDifficulty.hard: 15}; lengths: {4: 68, 5: 102, 6: 99, 7: 31}.
Tags (multi-tag entries counted in each): {action: 28, adjective: 17, animal: 28, body: 15, clothing: 12, color: 4, concept: 4, drink: 2, emotion: 2, family: 9, food: 38, home: 39, nature: 40, number: 4, object: 1, people: 18, place: 15, school: 5, sport: 3, technology: 4, time: 10, transport: 8, weather: 10, work: 10}.
A–Z occurrences: {A: 140, B: 41, C: 71, D: 41, E: 206, F: 33, G: 30, H: 65, I: 83, J: 2, K: 35, L: 84, M: 39, N: 91, O: 125, P: 46, Q: 1, R: 145, S: 87, T: 120, U: 38, V: 17, W: 31, X: 1, Y: 19, Z: 2}.
Crossing partners min / average / max: 145 / 252.35 / 295; zero: [].
Bottom 10: DUCK:145, BOOK:150, BABY:157, WIND:168, HILL:175, MOON:175, MILK:176, FOLLOW:178, WOLF:178, FOOT:184.
Top 10: COURAGE:295, STATION:293, ORANGE:292, APRICOT:291, OCEAN:290, BLANKET:289, BROTHER:289, RAINBOW:289, SEASON:289, CURTAIN:287.

## Sequence

Base seed 20261003; cooldown 5; count 30. No relaxation. Timing is local diagnostic only, around generateNext.

| Index | ID | Seed | Eligible | Generation pool | Tiers | Attempts | Score | Crossings | Leaves | Rows×cols | Density | ms (all attempts) | Checks (all attempts) | Nodes (final attempt) | Complete (final attempt) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | generated-v3-000001 | 3255270515 | 300 | 300 | [0] | 1 | 4216 | 12 | 1 | 9×8 | 0.5833 | 1261 | 4000000 | 6352 | 1008 |
| 2 | generated-v3-000002 | 3017514609 | 290 | 290 | [0] | 1 | 4195 | 12 | 1 | 9×8 | 0.5972 | 1124 | 4000000 | 6694 | 842 |
| 3 | generated-v3-000003 | 4063561778 | 280 | 280 | [0] | 1 | 3963 | 12 | 2 | 10×9 | 0.5444 | 958 | 4000000 | 6413 | 926 |
| 4 | generated-v3-000004 | 4080171169 | 270 | 270 | [0] | 1 | 3708 | 11 | 2 | 9×8 | 0.5833 | 686 | 4000000 | 6693 | 598 |
| 5 | generated-v3-000005 | 212570333 | 260 | 260 | [0] | 1 | 4316 | 12 | 1 | 10×7 | 0.6286 | 809 | 4000000 | 7369 | 1404 |
| 6 | generated-v3-000006 | 2351277153 | 250 | 250 | [0] | 1 | 4088 | 12 | 2 | 10×8 | 0.5625 | 590 | 4000000 | 6879 | 506 |
| 7 | generated-v3-000007 | 122973788 | 250 | 240 | [0] | 1 | 4189 | 12 | 1 | 10×8 | 0.5250 | 729 | 4000000 | 7599 | 1342 |
| 8 | generated-v3-000008 | 3616392535 | 250 | 232 | [0, 1] | 2 | 4553 | 13 | 0 | 9×9 | 0.5309 | 1541 | 8000000 | 8499 | 2298 |
| 9 | generated-v3-000009 | 1200630159 | 250 | 221 | [0] | 1 | 4409 | 13 | 1 | 10×9 | 0.5111 | 777 | 4000000 | 8454 | 1586 |
| 10 | generated-v3-000010 | 3356167200 | 250 | 211 | [0] | 1 | 4159 | 12 | 1 | 10×8 | 0.5750 | 581 | 4000000 | 8509 | 546 |
| 11 | generated-v3-000011 | 3448742630 | 250 | 201 | [0] | 4 | 3557 | 11 | 2 | 10×9 | 0.5333 | 2434 | 16000000 | 8690 | 600 |
| 12 | generated-v3-000012 | 3722140078 | 250 | 193 | [0, 1] | 2 | 3954 | 12 | 2 | 10×9 | 0.5556 | 1256 | 8000000 | 8940 | 462 |
| 13 | generated-v3-000013 | 3296970215 | 250 | 184 | [0, 1] | 3 | 3814 | 12 | 2 | 10×10 | 0.5300 | 1844 | 12000000 | 9307 | 822 |
| 14 | generated-v3-000014 | 3191423739 | 250 | 172 | [0] | 3 | 3424 | 11 | 2 | 10×10 | 0.5000 | 1570 | 12000000 | 9427 | 212 |
| 15 | generated-v3-000015 | 1586798619 | 250 | 164 | [0, 1] | 3 | 3472 | 11 | 3 | 10×9 | 0.5667 | 1440 | 11789521 | 10000 | 16 |
| 16 | generated-v3-000016 | 3309678214 | 250 | 153 | [0] | 1 | 3974 | 12 | 2 | 10×9 | 0.5778 | 629 | 3871678 | 10000 | 998 |
| 17 | generated-v3-000017 | 1709764501 | 250 | 143 | [0] | 1 | 3982 | 12 | 2 | 10×9 | 0.5778 | 516 | 3658637 | 10000 | 504 |
| 18 | generated-v3-000018 | 1267087583 | 250 | 149 | [0, 1] | 4 | 3557 | 11 | 2 | 10×9 | 0.5333 | 1954 | 13948125 | 10000 | 866 |
| 19 | generated-v3-000019 | 642745423 | 250 | 132 | [0, 1] | 3 | 4590 | 13 | 1 | 10×8 | 0.6125 | 1261 | 9912912 | 10000 | 340 |
| 20 | generated-v3-000020 | 2432605180 | 250 | 120 | [0] | 3 | 3784 | 12 | 2 | 10×10 | 0.5200 | 1356 | 9109328 | 10000 | 604 |
| 21 | generated-v3-000021 | 2039714612 | 250 | 110 | [0] | 1 | 4062 | 12 | 1 | 10×9 | 0.5556 | 372 | 2702583 | 10000 | 300 |
| 22 | generated-v3-000022 | 3891639982 | 250 | 116 | [0, 1] | 4 | 4016 | 12 | 2 | 9×9 | 0.5679 | 1266 | 9902614 | 10000 | 750 |
| 23 | generated-v3-000023 | 2347641815 | 250 | 112 | [0, 1] | 4 | 4056 | 12 | 1 | 10×9 | 0.5667 | 1369 | 9385317 | 10000 | 552 |
| 24 | generated-v3-000024 | 3386510391 | 250 | 94 | [0, 1] | 4 | 3628 | 11 | 3 | 10×8 | 0.6000 | 1310 | 9334621 | 10000 | 48 |
| 25 | generated-v3-000025 | 3020097767 | 250 | 88 | [0, 1] | 5 | 3651 | 11 | 1 | 10×9 | 0.5444 | 1655 | 12424998 | 10000 | 606 |
| 26 | generated-v3-000026 | 3535478817 | 250 | 81 | [0, 1] | 5 | 3551 | 11 | 2 | 10×9 | 0.5444 | 1605 | 12383666 | 10000 | 12 |
| 27 | generated-v3-000027 | 382374061 | 250 | 86 | [0, 1] | 5 | 3573 | 11 | 2 | 10×9 | 0.5333 | 1566 | 11238941 | 10000 | 158 |
| 28 | generated-v3-000028 | 1858263009 | 250 | 250 | [0, 1, 2] | 5 | 4071 | 12 | 1 | 9×9 | 0.5432 | 1559 | 10862409 | 7548 | 1404 |
| 29 | generated-v3-000029 | 2410942209 | 250 | 81 | [0, 1] | 4 | 3943 | 12 | 2 | 10×9 | 0.5444 | 805 | 6764667 | 10000 | 46 |
| 30 | generated-v3-000030 | 665389888 | 250 | 250 | [0, 1, 2] | 5 | 3693 | 11 | 1 | 9×9 | 0.5309 | 1407 | 10235790 | 7796 | 1184 |

Answers and attempt outcomes:
- 1: BROTHER, ROOM, RAIN, UNCLE, HOME, MOON, FACE, EXAM, MEAT, FARM; cooldown excluded 0; min usage 0; widened false; tiers=[0], pool=300, success
- 2: FRIDGE, KNEE, ONION, DOOR, BIRD, GOAT, ROBOT, FOUR, AUNT, DIRTY; cooldown excluded 10; min usage 0; widened false; tiers=[0], pool=290, success
- 3: SCHOOL, SOAP, PEPPER, CHESS, LARGE, SMILE, DRESS, DOLPHIN, NECK, BEAR; cooldown excluded 20; min usage 0; widened false; tiers=[0], pool=280, success
- 4: BABY, BOOK, BOAT, SOFA, TREE, LAKE, CITY, RABBIT, ZEBRA, FIRE; cooldown excluded 30; min usage 0; widened false; tiers=[0], pool=270, success
- 5: APPLE, LEAF, PEAR, PAPER, FORK, RACE, CAMERA, SHEEP, BRUSH, BACK; cooldown excluded 40; min usage 0; widened false; tiers=[0], pool=260, success
- 6: KETTLE, CAKE, DANGER, HORSE, NIGHT, LION, LEND, TABLE, FIVE, COMB; cooldown excluded 50; min usage 0; widened false; tiers=[0], pool=250, success
- 7: SALT, SOCK, COAT, LEARN, SNOW, FOOT, PASTA, LESSON, HILL, SHOP; cooldown excluded 50; min usage 0; widened false; tiers=[0], pool=240, success
- 8: FEATHER, NOSE, LEMON, MEAT, PLANE, FROG, OCEAN, HAND, RICE, DEER; cooldown excluded 50; min usage 0; widened true; tiers=[0], pool=230, success / tiers=[0, 1], pool=232, success
- 9: SEARCH, FISH, STAR, CURTAIN, MOUSE, SEED, EIGHT, ANGRY, CATCH, HAIR; cooldown excluded 50; min usage 0; widened false; tiers=[0], pool=221, success
- 10: DONKEY, SAND, AUTUMN, DUCK, HONEY, OLIVE, TIGER, EARTH, SHOE, WAVE; cooldown excluded 50; min usage 0; widened false; tiers=[0], pool=211, success
- 11: WATCH, HEAD, WALL, ALMOND, THROW, PANDA, REPAIR, ROOT, NEEDLE, READ; cooldown excluded 50; min usage 0; widened true; tiers=[0], pool=201, success / tiers=[0, 1], pool=203, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=205, success / tiers=[0, 1], pool=217, success
- 12: SPIDER, SOUP, POLITE, RACE, WRINKLE, ANSWER, NURSE, ROAD, TENNIS, SOIL; cooldown excluded 50; min usage 0; widened true; tiers=[0], pool=191, success / tiers=[0, 1], pool=193, success
- 13: WISDOM, WIND, DOCTOR, SPACE, SUMMER, BREAD, SEASON, BANANA, RAINBOW, ROOF; cooldown excluded 50; min usage 0; widened true; tiers=[0], pool=182, success / tiers=[0, 1], pool=184, success / tiers=[0, 1], pool=186, success
- 14: TURTLE, WEEK, BLACK, TRAIN, PHONE, MONTH, WATER, BOTTLE, WINDOW, WOLF; cooldown excluded 50; min usage 0; widened true; tiers=[0], pool=172, success / tiers=[0, 1], pool=174, success / tiers=[0, 1], pool=176, success
- 15: LIBRARY, PEAR, SHARE, CHAIR, SHIRT, STORM, BRANCH, BANK, YOUNG, SPRING; cooldown excluded 50; min usage 0; widened true; tiers=[0], pool=162, success / tiers=[0, 1], pool=164, success / tiers=[0, 1], pool=166, success
- 16: MOTHER, MILK, LISTEN, HOTEL, ORANGE, VALLEY, SKIRT, CHILD, SMOOTH, HAPPY; cooldown excluded 50; min usage 0; widened false; tiers=[0], pool=153, success
- 17: PENCIL, LIGHT, WALNUT, CLEAN, EAGLE, SHELF, EMPTY, ENOUGH, SPOON, BASKET; cooldown excluded 50; min usage 0; widened false; tiers=[0], pool=143, success
- 18: BREATHE, WAVE, PILLOW, PLANT, FINGER, BEAR, RAIN, HEART, CAKE, LEAF; cooldown excluded 50; min usage 0; widened true; tiers=[0], pool=133, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=135, success / tiers=[0, 1], pool=137, success / tiers=[0, 1], pool=149, success
- 19: CARPET, FACE, TODAY, FLOOR, KNIFE, TREE, CABBAGE, COAST, PLATE, STREET; cooldown excluded 50; min usage 0; widened true; tiers=[0], pool=128, success / tiers=[0, 1], pool=130, success / tiers=[0, 1], pool=132, success
- 20: BRIDGE, STONE, SALAD, FOLLOW, FORGET, LEAVE, GREEN, WINTER, BAKER, GRASS; cooldown excluded 50; min usage 0; widened true; tiers=[0], pool=120, success / tiers=[0, 1], pool=122, success / tiers=[0, 1], pool=124, success
- 21: GRAPE, SNAKE, RIVER, ARTIST, HEAVY, WHITE, PILOT, HEALTH, GLOVE, TOWEL; cooldown excluded 50; min usage 0; widened false; tiers=[0], pool=110, success
- 22: TEACHER, FIRE, HOME, HAIR, CHICKEN, NOSE, RICE, HOUSE, TOOTH, SHOE; cooldown excluded 50; min usage 0; widened true; tiers=[0], pool=100, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=102, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=104, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=116, success
- 23: APRICOT, AUNT, STAR, STREAM, SALT, SALARY, YOGURT, CARRY, BICYCLE, LAKE; cooldown excluded 50; min usage 0; widened true; tiers=[0], pool=96, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=98, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=100, success / tiers=[0, 1], pool=112, success
- 24: CHOOSE, READ, ISLAND, TOMATO, CLIMB, COAT, BEACH, BRAVE, EXAM, DEER; cooldown excluded 50; min usage 0; widened true; tiers=[0], pool=90, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=92, success / tiers=[0, 1], pool=94, success / tiers=[0, 1], pool=106, success
- 25: FLOUR, LEND, NECK, JUICE, HEAD, WEALTH, WHALE, SCARF, SHALLOW, WRITE; cooldown excluded 50; min usage 0; widened true; tiers=[0], pool=84, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=86, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=88, success / tiers=[0, 1], pool=100, success / tiers=[0, 1, 2], pool=250, success
- 26: INSECT, GOAT, POTATO, BROWN, BOAT, CLOCK, SLEEP, MELON, KNEE, ARRIVE; cooldown excluded 50; min usage 0; widened true; tiers=[0], pool=77, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=79, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=81, success / tiers=[0, 1], pool=93, success / tiers=[0, 1, 2], pool=250, success
- 27: STONE, SEED, RETURN, NURSE, WEEK, FIVE, COUSIN, FROST, COFFEE, CITY; cooldown excluded 50; min usage 0; widened true; tiers=[0], pool=70, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=72, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=74, success / tiers=[0, 1], pool=86, success / tiers=[0, 1, 2], pool=250, success
- 28: BREEZE, COMB, CARPET, RACE, TREE, ROOF, SOAP, EMPTY, TRAIN, BANK; cooldown excluded 50; min usage 0; widened true; tiers=[0], pool=66, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=68, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=70, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=82, success / tiers=[0, 1, 2], pool=250, success
- 29: HOTEL, SOIL, ROOT, FOREST, FATHER, AIRPORT, EARTH, SAND, SHARK, TRUCK; cooldown excluded 50; min usage 0; widened true; tiers=[0], pool=65, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=67, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=69, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=81, success
- 30: GARDEN, HAIR, SHARE, RICE, DOOR, STAR, AUNT, ONION, SOFA, BEAR; cooldown excluded 50; min usage 0; widened true; tiers=[0], pool=60, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=62, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=64, Search budget exhausted without a valid complete board. / tiers=[0, 1], pool=76, success / tiers=[0, 1, 2], pool=250, success
Attempts min / average / max: 1 / 2.67 / 5.
Support diagnostics:
- 1: target pool 300; candidates 0; offered []; selected target/support 10/0; successes 1; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 1 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 10/0; success
- 2: target pool 290; candidates 0; offered []; selected target/support 10/0; successes 1; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 1 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 10/0; success
- 3: target pool 280; candidates 0; offered []; selected target/support 10/0; successes 1; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 1 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 10/0; success
- 4: target pool 270; candidates 0; offered []; selected target/support 10/0; successes 1; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 1 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 10/0; success
- 5: target pool 260; candidates 0; offered []; selected target/support 10/0; successes 1; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 1 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 10/0; success
- 6: target pool 250; candidates 0; offered []; selected target/support 10/0; successes 1; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 1 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 10/0; success
- 7: target pool 240; candidates 10; offered []; selected target/support 10/0; successes 1; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 1 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 10/0; success
- 8: target pool 230; candidates 20; offered [meat, rain]; selected target/support 9/1; successes 2; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 2 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 10/0; success
  stage: support 2; ids [meat, rain]; tiers [0, 1]; selected target/support 9/1; success
- 9: target pool 221; candidates 29; offered []; selected target/support 10/0; successes 1; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 1 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 10/0; success
- 10: target pool 211; candidates 39; offered []; selected target/support 10/0; successes 1; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 1 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 10/0; success
- 11: target pool 201; candidates 49; offered []; selected target/support 10/0; successes 3; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 3 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 10/0; success
  stage: support 2; ids [race, pear]; tiers [0, 1]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 4; ids [race, pear, home, bear]; tiers [0, 1]; selected target/support 8/2; success
  stage: support 16; ids [race, pear, home, bear, rain, lake, leaf, face, tree, fire, boat, goat, exam, aunt, soap, sofa]; tiers [0, 1]; selected target/support 6/4; success
- 12: target pool 191; candidates 59; offered [race, pear]; selected target/support 9/1; successes 2; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 2 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 10/0; success
  stage: support 2; ids [race, pear]; tiers [0, 1]; selected target/support 9/1; success
- 13: target pool 182; candidates 68; offered [pear, home]; selected target/support 10/0; successes 3; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 3 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 10/0; success
  stage: support 2; ids [pear, home]; tiers [0, 1]; selected target/support 10/0; success
  stage: support 4; ids [pear, home, bear, coat]; tiers [0, 1]; selected target/support 8/2; success
- 14: target pool 172; candidates 78; offered []; selected target/support 10/0; successes 3; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 3 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 10/0; success
  stage: support 2; ids [nose, pear]; tiers [0, 1]; selected target/support 9/1; success
  stage: support 4; ids [nose, pear, lake, home]; tiers [0, 1]; selected target/support 7/3; success
- 15: target pool 162; candidates 88; offered [nose, pear]; selected target/support 9/1; successes 3; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 3 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 10/0; success
  stage: support 2; ids [nose, pear]; tiers [0, 1]; selected target/support 9/1; success
  stage: support 4; ids [nose, pear, bear, lake]; tiers [0, 1]; selected target/support 6/4; success
- 16: target pool 153; candidates 97; offered []; selected target/support 10/0; successes 1; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 1 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 10/0; success
- 17: target pool 143; candidates 107; offered []; selected target/support 10/0; successes 1; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 1 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 10/0; success
- 18: target pool 133; candidates 117; offered [nose, shoe, bear, face, lake, tree, rice, read, leaf, home, cake, fire, coat, rain, wave, exam]; selected target/support 5/5; successes 3; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 3 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 2; ids [nose, shoe]; tiers [0, 1]; selected target/support 8/2; success
  stage: support 4; ids [nose, shoe, bear, face]; tiers [0, 1]; selected target/support 7/3; success
  stage: support 16; ids [nose, shoe, bear, face, lake, tree, rice, read, leaf, home, cake, fire, coat, rain, wave, exam]; tiers [0, 1]; selected target/support 5/5; success
- 19: target pool 128; candidates 122; offered [nose, shoe, face, tree]; selected target/support 8/2; successes 3; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 3 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 10/0; success
  stage: support 2; ids [nose, shoe]; tiers [0, 1]; selected target/support 9/1; success
  stage: support 4; ids [nose, shoe, face, tree]; tiers [0, 1]; selected target/support 8/2; success
- 20: target pool 120; candidates 130; offered []; selected target/support 10/0; successes 3; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 3 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 10/0; success
  stage: support 2; ids [nose, shoe]; tiers [0, 1]; selected target/support 9/1; success
  stage: support 4; ids [nose, shoe, rice, read]; tiers [0, 1]; selected target/support 7/3; success
- 21: target pool 110; candidates 140; offered []; selected target/support 10/0; successes 1; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 1 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 10/0; success
- 22: target pool 100; candidates 150; offered [nose, shoe, rice, home, read, fire, coat, lake, exam, deer, head, star, hair, salt, boat, neck]; selected target/support 4/6; successes 1; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 1 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 2; ids [nose, shoe]; tiers [0, 1]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 4; ids [nose, shoe, rice, home]; tiers [0, 1]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 16; ids [nose, shoe, rice, home, read, fire, coat, lake, exam, deer, head, star, hair, salt, boat, neck]; tiers [0, 1]; selected target/support 4/6; success
- 23: target pool 96; candidates 154; offered [read, lake, coat, exam, deer, star, salt, head, boat, neck, lend, goat, road, root, aunt, soil]; selected target/support 6/4; successes 2; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 2 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 2; ids [read, lake]; tiers [0, 1]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 4; ids [read, lake, coat, exam]; tiers [0, 1]; selected target/support 6/4; success
  stage: support 16; ids [read, lake, coat, exam, deer, star, salt, head, boat, neck, lend, goat, road, root, aunt, soil]; tiers [0, 1]; selected target/support 6/4; success
- 24: target pool 90; candidates 160; offered [read, coat, exam, deer]; selected target/support 6/4; successes 3; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 3 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 2; ids [read, coat]; tiers [0, 1]; selected target/support 8/2; success
  stage: support 4; ids [read, coat, exam, deer]; tiers [0, 1]; selected target/support 6/4; success
  stage: support 16; ids [read, coat, exam, deer, neck, head, lend, boat, goat, road, knee, root, five, ocean, seed, soil]; tiers [0, 1]; selected target/support 4/6; success
- 25: target pool 84; candidates 166; offered [neck, head, lend, boat]; selected target/support 7/3; successes 3; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 3 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 2; ids [neck, head]; tiers [0, 1]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 4; ids [neck, head, lend, boat]; tiers [0, 1]; selected target/support 7/3; success
  stage: support 16; ids [neck, head, lend, boat, root, goat, knee, road, seed, five, soil, ocean, week, soap, sofa, learn]; tiers [0, 1]; selected target/support 4/6; success
  stage: support 166; ids [neck, head, lend, boat, root, goat, knee, road, seed, five, soil, ocean, week, soap, sofa, learn, horse, mouse, nurse, hotel, table, earth, heart, water, tiger, clean, plate, lemon, olive, lion, city, sand, snow, share, large, bread, plane, coast, phone, honey, four, farm, sock, dress, train, paper, space, zebra, uncle, storm, shirt, skirt, fork, bird, bank, eight, chair, smile, apple, knife, hand, eagle, chess, room, back, throw, today, soup, shop, sheep, shelf, empty, plant, dirty, month, door, foot, frog, robot, light, turtle, carpet, mother, orange, watch, comb, fish, camera, listen, season, lesson, angry, night, roof, search, danger, enough, street, answer, polite, summer, basket, branch, floor, catch, tennis, bottle, spider, donkey, brush, repair, pencil, finger, pasta, child, moon, milk, kettle, fridge, black, wind, duck, doctor, pepper, rabbit, spring, hill, valley, walnut, wolf, spoon, needle, smooth, almond, wisdom, curtain, panda, brother, wrinkle, autumn, rainbow, school, wall, feather, breathe, onion, cabbage, young, library, dolphin, baby, window, book, pillow, banana, happy, race, tree, pear, bear, meat, face, cake, leaf, rain, wave]; tiers [0, 1, 2]; selected target/support 1/9; success
- 26: target pool 77; candidates 173; offered [knee, root, boat, goat]; selected target/support 7/3; successes 3; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 3 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 2; ids [knee, root]; tiers [0, 1]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 4; ids [knee, root, boat, goat]; tiers [0, 1]; selected target/support 7/3; success
  stage: support 16; ids [knee, root, boat, goat, road, seed, week, five, soap, sofa, ocean, soil, learn, stone, horse, mouse]; tiers [0, 1]; selected target/support 5/5; success
  stage: support 173; ids [knee, root, boat, goat, road, seed, week, five, soap, sofa, ocean, soil, learn, stone, horse, mouse, nurse, hotel, city, sand, tiger, table, lemon, olive, sock, earth, heart, water, clean, plate, baker, phone, honey, four, lion, snow, green, share, large, bread, space, storm, plane, coast, farm, fork, bird, bank, dress, train, paper, zebra, skirt, eight, uncle, shirt, hand, knife, chair, room, chess, smile, apple, empty, soup, back, leave, eagle, throw, dirty, month, today, door, frog, shop, sheep, robot, plant, shelf, light, foot, comb, turtle, carpet, mother, orange, watch, night, roof, camera, listen, season, lesson, enough, angry, search, forget, polite, danger, basket, moon, street, winter, tennis, bottle, answer, summer, branch, donkey, fish, floor, catch, spider, repair, finger, pencil, bridge, pasta, duck, kettle, fridge, grass, brush, doctor, spring, spoon, black, child, pepper, milk, wind, rabbit, valley, walnut, almond, needle, smooth, salad, panda, hill, curtain, wisdom, wolf, brother, wrinkle, onion, young, rainbow, autumn, school, feather, breathe, cabbage, wall, library, dolphin, book, baby, window, pillow, banana, happy, follow, race, tree, meat, pear, bear, cake, face, rain, leaf, wave]; tiers [0, 1, 2]; selected target/support 2/8; success
- 27: target pool 70; candidates 180; offered [root, seed, road, five, nurse, ocean, week, city, learn, stone, horse, mouse, soap, sofa, tiger, hotel]; selected target/support 4/6; successes 3; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 3 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 2; ids [root, seed]; tiers [0, 1]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 4; ids [root, seed, road, five]; tiers [0, 1]; selected target/support 6/4; success
  stage: support 16; ids [root, seed, road, five, nurse, ocean, week, city, learn, stone, horse, mouse, soap, sofa, tiger, hotel]; tiers [0, 1]; selected target/support 4/6; success
  stage: support 180; ids [root, seed, road, five, nurse, ocean, week, city, learn, stone, horse, mouse, soap, sofa, tiger, hotel, bird, soil, sand, green, earth, heart, water, plate, table, towel, white, lemon, olive, glove, four, farm, sock, share, dress, train, baker, bread, clean, snake, space, eight, phone, honey, river, large, paper, grape, storm, zebra, shirt, skirt, plane, coast, fork, snow, uncle, chair, lion, hand, bank, chess, smile, knife, empty, dirty, room, apple, month, back, leave, eagle, sheep, throw, heavy, today, robot, shelf, door, frog, soup, plant, watch, night, light, foot, shop, comb, turtle, carpet, mother, orange, angry, camera, listen, season, danger, summer, lesson, enough, roof, fish, duck, catch, pilot, street, winter, search, tennis, forget, answer, polite, basket, branch, moon, pasta, artist, bottle, spider, finger, bridge, donkey, repair, health, fridge, floor, brush, kettle, pencil, grass, doctor, rabbit, spring, child, pepper, wind, spoon, milk, black, valley, curtain, needle, smooth, walnut, almond, wrinkle, salad, panda, hill, brother, rainbow, autumn, wisdom, young, feather, breathe, school, wolf, cabbage, onion, baby, library, dolphin, book, wall, window, banana, pillow, happy, follow, race, meat, tree, pear, bear, cake, face, rain, leaf, wave]; tiers [0, 1, 2]; selected target/support 1/9; success
- 28: target pool 66; candidates 184; offered [root, road, ocean, learn, horse, mouse, house, soap, sofa, earth, heart, water, tiger, plate, table, hotel, bird, sand, soil, green, train, baker, bread, clean, towel, white, lemon, olive, glove, farm, sock, share, dress, large, paper, grape, snake, space, zebra, eight, shirt, skirt, plane, phone, honey, four, hand, bank, river, storm, uncle, coast, chair, apple, empty, dirty, fork, snow, leave, eagle, chess, smile, knife, heavy, lion, back, month, room, sheep, throw, today, robot, shelf, plant, night, light, turtle, carpet, mother, orange, watch, angry, door, frog, soup, shop, comb, camera, listen, season, danger, summer, lesson, enough, foot, fish, duck, street, winter, artist, search, tennis, answer, forget, polite, basket, branch, pasta, catch, pilot, bottle, spider, health, finger, bridge, donkey, roof, brush, kettle, repair, pencil, fridge, moon, grass, floor, child, rabbit, spring, pepper, doctor, milk, wind, valley, black, spoon, needle, walnut, hill, curtain, tooth, salad, panda, smooth, almond, teacher, wrinkle, autumn, wisdom, feather, breathe, brother, rainbow, cabbage, school, chicken, young, wolf, baby, onion, wall, library, dolphin, book, window, happy, banana, pillow, follow, meat, nose, tree, race, rice, shoe, home, pear, bear, cake, fire, face, rain, leaf, wave, hair]; selected target/support 1/9; successes 2; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 2 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 2; ids [root, road]; tiers [0, 1]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 4; ids [root, road, ocean, learn]; tiers [0, 1]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 16; ids [root, road, ocean, learn, horse, mouse, house, soap, sofa, earth, heart, water, tiger, plate, table, hotel]; tiers [0, 1]; selected target/support 5/5; success
  stage: support 184; ids [root, road, ocean, learn, horse, mouse, house, soap, sofa, earth, heart, water, tiger, plate, table, hotel, bird, sand, soil, green, train, baker, bread, clean, towel, white, lemon, olive, glove, farm, sock, share, dress, large, paper, grape, snake, space, zebra, eight, shirt, skirt, plane, phone, honey, four, hand, bank, river, storm, uncle, coast, chair, apple, empty, dirty, fork, snow, leave, eagle, chess, smile, knife, heavy, lion, back, month, room, sheep, throw, today, robot, shelf, plant, night, light, turtle, carpet, mother, orange, watch, angry, door, frog, soup, shop, comb, camera, listen, season, danger, summer, lesson, enough, foot, fish, duck, street, winter, artist, search, tennis, answer, forget, polite, basket, branch, pasta, catch, pilot, bottle, spider, health, finger, bridge, donkey, roof, brush, kettle, repair, pencil, fridge, moon, grass, floor, child, rabbit, spring, pepper, doctor, milk, wind, valley, black, spoon, needle, walnut, hill, curtain, tooth, salad, panda, smooth, almond, teacher, wrinkle, autumn, wisdom, feather, breathe, brother, rainbow, cabbage, school, chicken, young, wolf, baby, onion, wall, library, dolphin, book, window, happy, banana, pillow, follow, meat, nose, tree, race, rice, shoe, home, pear, bear, cake, fire, face, rain, leaf, wave, hair]; tiers [0, 1, 2]; selected target/support 1/9; success
- 29: target pool 65; candidates 185; offered [root, road, ocean, sofa, learn, horse, mouse, house, sand, soil, earth, heart, water, tiger, plate, hotel]; selected target/support 5/5; successes 1; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 1 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 2; ids [root, road]; tiers [0, 1]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 4; ids [root, road, ocean, sofa]; tiers [0, 1]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 16; ids [root, road, ocean, sofa, learn, horse, mouse, house, sand, soil, earth, heart, water, tiger, plate, hotel]; tiers [0, 1]; selected target/support 5/5; success
- 30: target pool 60; candidates 190; offered [ocean, road, sofa, learn, horse, lemon, mouse, house, olive, glove, heart, water, tiger, plate, table, towel, beach, sock, hand, green, clean, bread, baker, uncle, plane, white, phone, honey, lion, bird, snow, share, dress, large, paper, grape, snake, brave, space, eight, zebra, shirt, skirt, coast, river, storm, apple, farm, leave, eagle, chess, smile, chair, dirty, heavy, four, knife, month, fork, back, sheep, shelf, today, duck, throw, plant, night, light, turtle, mother, orange, season, lesson, carry, robot, watch, room, soup, shop, stream, camera, listen, danger, polite, summer, choose, enough, pilot, angry, foot, moon, wind, fish, street, winter, tennis, search, artist, answer, bottle, forget, basket, branch, pasta, catch, spider, health, finger, pencil, bridge, donkey, door, frog, child, climb, kettle, repair, fridge, milk, brush, rabbit, spring, needle, pepper, doctor, valley, island, grass, floor, spoon, yogurt, panda, black, hill, walnut, almond, wisdom, salad, curtain, smooth, teacher, wrinkle, tooth, tomato, autumn, breathe, feather, brother, apricot, rainbow, onion, young, school, cabbage, chicken, bicycle, salary, wolf, wall, baby, dolphin, library, window, happy, banana, pillow, book, follow, nose, meat, shoe, home, rice, read, pear, bear, cake, exam, fire, face, lake, deer, rain, leaf, wave, star, coat, salt, hair, aunt]; selected target/support 1/9; successes 2; Prefer quality >=3500 / <=9 columns / <=3 leaves, then quality + 180 per target answer - 400 for 10 columns among 2 successful stages; stop at quality 3900 / <=9 columns / <=3 leaves or 3 successes.
  stage: support 0; ids []; tiers [0]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 2; ids [ocean, road]; tiers [0, 1]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 4; ids [ocean, road, sofa, learn]; tiers [0, 1]; selected target/support 0/0; Search budget exhausted without a valid complete board.
  stage: support 16; ids [ocean, road, sofa, learn, horse, lemon, mouse, house, olive, glove, heart, water, tiger, plate, table, towel]; tiers [0, 1]; selected target/support 5/5; success
  stage: support 190; ids [ocean, road, sofa, learn, horse, lemon, mouse, house, olive, glove, heart, water, tiger, plate, table, towel, beach, sock, hand, green, clean, bread, baker, uncle, plane, white, phone, honey, lion, bird, snow, share, dress, large, paper, grape, snake, brave, space, eight, zebra, shirt, skirt, coast, river, storm, apple, farm, leave, eagle, chess, smile, chair, dirty, heavy, four, knife, month, fork, back, sheep, shelf, today, duck, throw, plant, night, light, turtle, mother, orange, season, lesson, carry, robot, watch, room, soup, shop, stream, camera, listen, danger, polite, summer, choose, enough, pilot, angry, foot, moon, wind, fish, street, winter, tennis, search, artist, answer, bottle, forget, basket, branch, pasta, catch, spider, health, finger, pencil, bridge, donkey, door, frog, child, climb, kettle, repair, fridge, milk, brush, rabbit, spring, needle, pepper, doctor, valley, island, grass, floor, spoon, yogurt, panda, black, hill, walnut, almond, wisdom, salad, curtain, smooth, teacher, wrinkle, tooth, tomato, autumn, breathe, feather, brother, apricot, rainbow, onion, young, school, cabbage, chicken, bicycle, salary, wolf, wall, baby, dolphin, library, window, happy, banana, pillow, book, follow, nose, meat, shoe, home, rice, read, pear, bear, cake, exam, fire, face, lake, deer, rain, leaf, wave, star, coat, salt, hair, aunt]; tiers [0, 1, 2]; selected target/support 1/9; success
Chosen support-size histogram: {0: 15, 2: 4, 4: 4, 16: 5, 184: 1, 190: 1}; target/support answers average: 8.033333333333333/1.9666666666666666.

PASS: 30/30 complete; independent strict validation passed; all phantom adjacencies and unexplained runs = 0; cooldown checked by both IDs and solutions.
Scores min / average / max: 3424 / 3938.27 / 4590; lowest indices [14]; highest indices [19].
Crossings min / average / max: 11 / 11.77 / 13; maximum leaves 3.
Visible widths: {7: 1, 8: 8, 9: 18, 10: 3}; dimensions: {10×10: 3, 10×7: 1, 10×8: 5, 10×9: 14, 9×8: 3, 9×9: 4}.
Rows min / average / max: 9 / 9.77 / 10; columns: 7 / 8.77 / 10; density: 0.5 / 0.56 / 0.6285714285714286.
10-column boards (index:score:density): 13:3814:0.5300, 14:3424:0.5000, 20:3784:0.5200.
Time ms min / average / max: 372 / 1207.67 / 2434; total 36230 ms.
Candidate checks min / average / max: 2702583 / 7984193.57 / 16000000.

## Usage

Unique 241 / 300; coverage 80.33%; slots 300.
Usage frequency → number of words: {0: 59, 1: 189, 2: 45, 3: 7}.
Top 15: AUNT:3, BEAR:3, HAIR:3, RACE:3, RICE:3, STAR:3, TREE:3, BANK:2, BOAT:2, CAKE:2, CARPET:2, CITY:2, COAT:2, COMB:2, DEER:2.
Repeat distance min / average / max: 7 / 15.83 / 28. Average is over consecutive reuse events, not per-word averages.
Never used (59): ANCIENT, BELIEVE, BLANKET, BORROW, BUCKET, BUTTER, BUTTON, CAMEL, CANDLE, CARROT, CASTLE, CEILING, CHEESE, CHERRY, CLOUD, COOKIE, COTTON, COURAGE, DESERT, DESERVE, DRAWER, DRIVER, FARMER, FLOWER, FRIEND, GARLIC, HAMMER, HARVEST, INVITE, JACKET, KITCHEN, MARKET, MIRROR, MONKEY, MOUTH, MUSEUM, NARROW, OFFICE, PARROT, PEACH, PEANUT, PLANET, POCKET, PROMISE, PUMPKIN, QUIET, SCREEN, SEVEN, SHELTER, SISTER, SMALL, STATION, STUDENT, SUGAR, SUNSET, THUNDER, TICKET, VILLAGE, WHISPER.

## App Puzzle 1

generated-v3-000001; seed 3255270515; bounds rows 1–9, columns 1–8; 1261 ms.

- BROTHER — Erkek kardeş — down — start(2,5) — clue(1,5)
- ROOM — Oda — right — start(8,5) — clue(8,4)
- RAIN — Yağmur — right — start(3,5) — clue(3,4)
- UNCLE — Amca veya dayı — down — start(2,8) — clue(1,8)
- HOME — Yuva — right — start(6,5) — clue(6,4)
- MOON — Ay — down — start(6,7) — clue(5,7)
- FACE — Yüz — right — start(7,2) — clue(7,1)
- EXAM — Sınav — down — start(5,3) — clue(4,3)
- MEAT — Et — right — start(5,2) — clue(5,1)
- FARM — Çiftlik — down — start(2,2) — clue(1,2)
Difficulty slots: {easy: 234, hard: 6, medium: 60}; unique: {easy: 180, hard: 6, medium: 55}.
Length slots: {4: 118, 5: 102, 6: 65, 7: 15}; unique: {4: 68, 5: 94, 6: 64, 7: 15}.
Length 4 coverage: 68/68 (100.00%).
Length 5 coverage: 94/102 (92.16%).
Length 6 coverage: 64/99 (64.65%).
Length 7 coverage: 15/31 (48.39%).

## Comparison (same records and seed, current-run timings)

| Metric | Unbalanced | Naive v3 | Bounded support |
|---|---|---|---|
| unique words | 175 | 228 | 241 |
| coverage percent | 58.333333333333336 | 76.0 | 80.33333333333333 |
| maximum usage | 5 | 2 | 3 |
| unused | 125 | 72 | 59 |
| maximum quality | 4651 | 4316 | 4590 |
| minimum crossings | 10 | 10 | 11 |
| maximum crossings | 13 | 12 | 13 |
| ten-column boards | 0 | 7 | 3 |
| minimum repeat distance | 6 | 6 | 7 |
| average repeat distance | 11.76 | 16.375 | 15.830508474576272 |
| maximum repeat distance | 28 | 26 | 28 |
| minimum ms | 553 | 323 | 372 |
| maximum ms | 1014 | 1641 | 2434 |
| total ms | 21602 | 23162 | 36230 |
| maximum attempts | 1 | 2 | 5 |
| maximum candidate checks | 4000000 | 8000000 | 16000000 |
| average quality | 3988.5 | 3772.9 | 3938.266666666667 |
| minimum quality | 3135 | 2946 | 3424 |
| average crossings | 11.733333333333333 | 11.4 | 11.766666666666667 |
| average ms | 720.0666666666667 | 772.0666666666667 | 1207.6666666666667 |
| average attempts | 1.0 | 1.3 | 2.6666666666666665 |
| average candidate checks | 4000000.0 | 4665989.333333333 | 7984193.566666666 |

```
