# Usage balancing v3 — experiment and limitations

Run against baseline eeef77e on 2026-10-03. Identical 300 records, seed mixer,
generator, scoring and per-attempt budgets. Unbalanced mode uses v3 IDs to signal
the current compatibility domain, but reproduces v2 board structures/metrics.

Coverage improves by 17.67 percentage points, from 175 to 228 unique words.
Maximum reuse falls from five to two. The 240-word/80% target is **not met**.
Nine unseen-only attempts exhaust their count-based search budgets (not a proof
that no board exists), then widen to counts 0 and 1. Wider pools may prefer already
used short words; fairness does not become a grid objective. Recency is not added:
no word exceeds two uses, and this mechanism would not address sparse unseen-only
placement opportunities.

Mean quality drops 5.41%; crossings remain 10–12, leaves at most 3.
Seven boards use 10 columns, versus none unbalanced. This geometry regression
deserves visual evaluation. No quality-threshold retries or new heuristics hide it.
Difficulty/length coverage improves but still skews toward easy/short vocabulary.

Each sequence passes all 30 strict validations and cooldown checks. Timing below
is diagnostic for this local run, including all attempts; unbalanced ran first,
so VM warmup and scheduling affect comparison. Check counts are deterministic.

# Catalogue v3 stress report — balanced=false

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
| 1 | generated-v3-000001 | 3255270515 | 300 | 300 | [] | 1 | 4216 | 12 | 1 | 9×8 | 0.5833 | 868 | 4000000 | 6352 | 1008 |
| 2 | generated-v3-000002 | 3017514609 | 290 | 290 | [] | 1 | 4195 | 12 | 1 | 9×8 | 0.5972 | 639 | 4000000 | 6694 | 842 |
| 3 | generated-v3-000003 | 4063561778 | 280 | 280 | [] | 1 | 3963 | 12 | 2 | 10×9 | 0.5444 | 628 | 4000000 | 6413 | 926 |
| 4 | generated-v3-000004 | 4080171169 | 270 | 270 | [] | 1 | 3708 | 11 | 2 | 9×8 | 0.5833 | 578 | 4000000 | 6693 | 598 |
| 5 | generated-v3-000005 | 212570333 | 260 | 260 | [] | 1 | 4316 | 12 | 1 | 10×7 | 0.6286 | 748 | 4000000 | 7369 | 1404 |
| 6 | generated-v3-000006 | 2351277153 | 250 | 250 | [] | 1 | 4088 | 12 | 2 | 10×8 | 0.5625 | 593 | 4000000 | 6879 | 506 |
| 7 | generated-v3-000007 | 122973788 | 250 | 250 | [] | 1 | 3611 | 11 | 2 | 9×9 | 0.5432 | 749 | 4000000 | 7377 | 1342 |
| 8 | generated-v3-000008 | 3616392535 | 250 | 250 | [] | 1 | 4187 | 12 | 0 | 9×9 | 0.5802 | 1002 | 4000000 | 8624 | 2710 |
| 9 | generated-v3-000009 | 1200630159 | 250 | 250 | [] | 1 | 4066 | 12 | 1 | 9×9 | 0.5556 | 679 | 4000000 | 7227 | 1192 |
| 10 | generated-v3-000010 | 3356167200 | 250 | 250 | [] | 1 | 3135 | 10 | 2 | 10×9 | 0.5000 | 711 | 4000000 | 7828 | 1254 |
| 11 | generated-v3-000011 | 3448742630 | 250 | 250 | [] | 1 | 4086 | 12 | 1 | 9×9 | 0.6173 | 650 | 4000000 | 6931 | 932 |
| 12 | generated-v3-000012 | 3722140078 | 250 | 250 | [] | 1 | 4651 | 13 | 0 | 10×8 | 0.5750 | 628 | 4000000 | 7085 | 930 |
| 13 | generated-v3-000013 | 3296970215 | 250 | 250 | [] | 1 | 4156 | 12 | 1 | 10×8 | 0.5625 | 578 | 4000000 | 6597 | 574 |
| 14 | generated-v3-000014 | 3191423739 | 250 | 250 | [] | 1 | 4646 | 13 | 0 | 10×8 | 0.5500 | 629 | 4000000 | 7314 | 768 |
| 15 | generated-v3-000015 | 1586798619 | 250 | 250 | [] | 1 | 4447 | 13 | 1 | 10×9 | 0.5222 | 790 | 4000000 | 7755 | 1614 |
| 16 | generated-v3-000016 | 3309678214 | 250 | 250 | [] | 1 | 4055 | 12 | 1 | 10×9 | 0.5222 | 660 | 4000000 | 7427 | 872 |
| 17 | generated-v3-000017 | 1709764501 | 250 | 250 | [] | 1 | 3587 | 11 | 2 | 9×9 | 0.5432 | 689 | 4000000 | 7571 | 1166 |
| 18 | generated-v3-000018 | 1267087583 | 250 | 250 | [] | 1 | 3696 | 11 | 2 | 10×8 | 0.5625 | 801 | 4000000 | 7525 | 1526 |
| 19 | generated-v3-000019 | 642745423 | 250 | 250 | [] | 1 | 4270 | 12 | 0 | 10×8 | 0.5500 | 892 | 4000000 | 8396 | 2078 |
| 20 | generated-v3-000020 | 2432605180 | 250 | 250 | [] | 1 | 4003 | 12 | 2 | 9×9 | 0.5802 | 674 | 4000000 | 8104 | 808 |
| 21 | generated-v3-000021 | 2039714612 | 250 | 250 | [] | 1 | 4151 | 12 | 1 | 10×8 | 0.5375 | 770 | 4000000 | 7661 | 1696 |
| 22 | generated-v3-000022 | 3891639982 | 250 | 250 | [] | 1 | 4159 | 12 | 1 | 10×8 | 0.5750 | 692 | 4000000 | 7723 | 1046 |
| 23 | generated-v3-000023 | 2347641815 | 250 | 250 | [] | 1 | 4037 | 12 | 1 | 10×9 | 0.5111 | 649 | 4000000 | 7488 | 1124 |
| 24 | generated-v3-000024 | 3386510391 | 250 | 250 | [] | 1 | 3675 | 11 | 2 | 10×8 | 0.5375 | 573 | 4000000 | 7546 | 642 |
| 25 | generated-v3-000025 | 3020097767 | 250 | 250 | [] | 1 | 4389 | 13 | 1 | 10×9 | 0.5111 | 586 | 4000000 | 7110 | 712 |
| 26 | generated-v3-000026 | 3535478817 | 250 | 250 | [] | 1 | 3695 | 11 | 1 | 9×9 | 0.5802 | 591 | 4000000 | 7198 | 720 |
| 27 | generated-v3-000027 | 382374061 | 250 | 250 | [] | 1 | 3671 | 11 | 1 | 9×9 | 0.5432 | 766 | 4000000 | 6965 | 1676 |
| 28 | generated-v3-000028 | 1858263009 | 250 | 250 | [] | 1 | 3547 | 11 | 2 | 10×9 | 0.5222 | 756 | 4000000 | 8013 | 1620 |
| 29 | generated-v3-000029 | 2410942209 | 250 | 250 | [] | 1 | 3175 | 10 | 3 | 10×8 | 0.5375 | 527 | 4000000 | 6510 | 256 |
| 30 | generated-v3-000030 | 665389888 | 250 | 250 | [] | 1 | 4074 | 12 | 1 | 9×9 | 0.5556 | 524 | 4000000 | 6547 | 310 |

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

PASS: 30/30 complete; independent strict validation passed; all phantom adjacencies and unexplained runs = 0; cooldown checked by both IDs and solutions.
Scores min / average / max: 3135 / 3988.50 / 4651; lowest indices [10]; highest indices [12].
Crossings min / average / max: 10 / 11.73 / 13; maximum leaves 3.
Visible widths: {7: 1, 8: 13, 9: 16}; dimensions: {10×7: 1, 10×8: 10, 10×9: 7, 9×8: 3, 9×9: 9}.
Rows min / average / max: 9 / 9.60 / 10; columns: 7 / 8.50 / 9; density: 0.5 / 0.56 / 0.6285714285714286.
10-column boards (index:score:density): .
Time ms min / average / max: 524 / 687.33 / 1002; total 20620 ms.
Candidate checks min / average / max: 4000000 / 4000000.00 / 4000000.

## Usage

Unique 175 / 300; coverage 58.33%; slots 300.
Usage frequency → number of words: {0: 125, 1: 91, 2: 53, 3: 22, 4: 8, 5: 1}.
Top 15: MOON:5, AUNT:4, BABY:4, CITY:4, COMB:4, EXAM:4, HOME:4, RACE:4, RAIN:4, BANK:3, BEAR:3, BIRD:3, BOAT:3, CAKE:3, CAMERA:3.
Repeat distance min / average / max: 6 / 11.76 / 28. Average is over consecutive reuse events, not per-word averages.
Never used (125): ANCIENT, ANSWER, APRICOT, ARRIVE, ARTIST, AUTUMN, BASKET, BELIEVE, BLACK, BLANKET, BORROW, BOTTLE, BRANCH, BRAVE, BREATHE, BRIDGE, BUCKET, BUTTER, CABBAGE, CAMEL, CARPET, CARROT, CARRY, CASTLE, CATCH, CEILING, CHEESE, CHERRY, CHICKEN, CHOOSE, CLIMB, CLOUD, COAST, COOKIE, COTTON, COURAGE, COUSIN, CURTAIN, DESERT, DESERVE, DOCTOR, DONKEY, DRIVER, EMPTY, ENOUGH, FEATHER, FINGER, FLOOR, FLOUR, FLOWER, FOLLOW, FOREST, FORGET, GARDEN, GARLIC, GLOVE, GREEN, HAND, HEAVY, JACKET, JUICE, KNIFE, LESSON, LIBRARY, LIGHT, LISTEN, MARKET, MILK, MONKEY, MONTH, MOTHER, MOUSE, NARROW, NEEDLE, OFFICE, ORANGE, PEANUT, PENCIL, PHONE, PLANE, PLANET, PLANT, PLATE, POCKET, POLITE, PROMISE, QUIET, RAINBOW, REPAIR, RIVER, SALARY, SEARCH, SEVEN, SHALLOW, SHARE, SHARK, SHELF, SHELTER, SISTER, SMALL, SMOOTH, SPACE, SPIDER, SPRING, STATION, STORM, STREAM, STREET, SUGAR, SUMMER, TEACHER, TENNIS, THROW, THUNDER, TOOTH, TRUCK, VALLEY, VILLAGE, WALNUT, WHALE, WHISPER, WHITE, WINDOW, WINTER, WRINKLE.

## App Puzzle 1

generated-v3-000001; seed 3255270515; bounds rows 1–9, columns 1–8; 868 ms.

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
# Catalogue v3 stress report — balanced=true

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
| 1 | generated-v3-000001 | 3255270515 | 300 | 300 | [0] | 1 | 4216 | 12 | 1 | 9×8 | 0.5833 | 642 | 4000000 | 6352 | 1008 |
| 2 | generated-v3-000002 | 3017514609 | 290 | 290 | [0] | 1 | 4195 | 12 | 1 | 9×8 | 0.5972 | 652 | 4000000 | 6694 | 842 |
| 3 | generated-v3-000003 | 4063561778 | 280 | 280 | [0] | 1 | 3963 | 12 | 2 | 10×9 | 0.5444 | 639 | 4000000 | 6413 | 926 |
| 4 | generated-v3-000004 | 4080171169 | 270 | 270 | [0] | 1 | 3708 | 11 | 2 | 9×8 | 0.5833 | 557 | 4000000 | 6693 | 598 |
| 5 | generated-v3-000005 | 212570333 | 260 | 260 | [0] | 1 | 4316 | 12 | 1 | 10×7 | 0.6286 | 720 | 4000000 | 7369 | 1404 |
| 6 | generated-v3-000006 | 2351277153 | 250 | 250 | [0] | 1 | 4088 | 12 | 2 | 10×8 | 0.5625 | 570 | 4000000 | 6879 | 506 |
| 7 | generated-v3-000007 | 122973788 | 250 | 240 | [0] | 1 | 4189 | 12 | 1 | 10×8 | 0.5250 | 710 | 4000000 | 7599 | 1342 |
| 8 | generated-v3-000008 | 3616392535 | 250 | 230 | [0] | 1 | 3708 | 11 | 1 | 9×9 | 0.5679 | 649 | 4000000 | 7582 | 686 |
| 9 | generated-v3-000009 | 1200630159 | 250 | 220 | [0] | 1 | 3633 | 11 | 1 | 10×9 | 0.5333 | 673 | 4000000 | 8109 | 1118 |
| 10 | generated-v3-000010 | 3356167200 | 250 | 210 | [0] | 1 | 3143 | 10 | 2 | 10×9 | 0.5000 | 533 | 4000000 | 7679 | 102 |
| 11 | generated-v3-000011 | 3448742630 | 250 | 200 | [0] | 1 | 3336 | 11 | 3 | 10×10 | 0.5000 | 517 | 4000000 | 8292 | 278 |
| 12 | generated-v3-000012 | 3722140078 | 250 | 190 | [0] | 1 | 3587 | 11 | 2 | 9×9 | 0.5802 | 669 | 4000000 | 8874 | 1030 |
| 13 | generated-v3-000013 | 3296970215 | 250 | 180 | [0] | 1 | 4025 | 12 | 1 | 10×9 | 0.5333 | 606 | 4000000 | 9231 | 688 |
| 14 | generated-v3-000014 | 3191423739 | 250 | 170 | [0] | 1 | 3562 | 11 | 2 | 10×9 | 0.5556 | 510 | 4000000 | 9408 | 322 |
| 15 | generated-v3-000015 | 1586798619 | 250 | 250 | [0, 1] | 2 | 4063 | 12 | 1 | 10×9 | 0.5222 | 1105 | 8000000 | 7225 | 778 |
| 16 | generated-v3-000016 | 3309678214 | 250 | 155 | [0] | 1 | 3346 | 11 | 3 | 10×10 | 0.5300 | 542 | 4000000 | 9926 | 498 |
| 17 | generated-v3-000017 | 1709764501 | 250 | 250 | [0, 1] | 2 | 4203 | 12 | 1 | 9×8 | 0.5972 | 1287 | 7700427 | 8395 | 2334 |
| 18 | generated-v3-000018 | 1267087583 | 250 | 250 | [0, 1] | 2 | 3690 | 11 | 1 | 9×9 | 0.5556 | 1089 | 7702077 | 7948 | 1082 |
| 19 | generated-v3-000019 | 642745423 | 250 | 143 | [0] | 1 | 3350 | 11 | 3 | 10×10 | 0.5500 | 440 | 3696933 | 10000 | 162 |
| 20 | generated-v3-000020 | 2432605180 | 250 | 133 | [0] | 1 | 3806 | 12 | 2 | 10×10 | 0.5100 | 460 | 3424680 | 10000 | 426 |
| 21 | generated-v3-000021 | 2039714612 | 250 | 245 | [0, 1] | 2 | 4103 | 12 | 1 | 9×9 | 0.5432 | 1030 | 7254457 | 7550 | 818 |
| 22 | generated-v3-000022 | 3891639982 | 250 | 245 | [0, 1] | 2 | 3951 | 12 | 2 | 10×9 | 0.5222 | 1096 | 7269973 | 7885 | 1444 |
| 23 | generated-v3-000023 | 2347641815 | 250 | 117 | [0] | 1 | 3912 | 12 | 1 | 10×10 | 0.5200 | 395 | 2948467 | 10000 | 374 |
| 24 | generated-v3-000024 | 3386510391 | 250 | 107 | [0] | 1 | 3963 | 12 | 2 | 10×9 | 0.6000 | 314 | 2786744 | 10000 | 16 |
| 25 | generated-v3-000025 | 3020097767 | 250 | 227 | [0, 1] | 2 | 4077 | 12 | 2 | 10×8 | 0.5875 | 977 | 6492853 | 8209 | 1190 |
| 26 | generated-v3-000026 | 3535478817 | 250 | 94 | [0] | 1 | 2946 | 10 | 3 | 10×10 | 0.5700 | 293 | 2337556 | 10000 | 132 |
| 27 | generated-v3-000027 | 382374061 | 250 | 220 | [0, 1] | 2 | 3254 | 10 | 2 | 10×8 | 0.5125 | 813 | 6219694 | 8380 | 426 |
| 28 | generated-v3-000028 | 1858263009 | 250 | 213 | [0, 1] | 2 | 3838 | 11 | 1 | 9×8 | 0.6528 | 920 | 6222656 | 8577 | 840 |
| 29 | generated-v3-000029 | 2410942209 | 250 | 83 | [0] | 1 | 3424 | 11 | 2 | 10×10 | 0.5400 | 296 | 2092581 | 10000 | 340 |
| 30 | generated-v3-000030 | 665389888 | 250 | 213 | [0, 1] | 2 | 3592 | 11 | 2 | 9×9 | 0.5679 | 902 | 5830582 | 8734 | 760 |

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

PASS: 30/30 complete; independent strict validation passed; all phantom adjacencies and unexplained runs = 0; cooldown checked by both IDs and solutions.
Scores min / average / max: 2946 / 3772.90 / 4316; lowest indices [26]; highest indices [5].
Crossings min / average / max: 10 / 11.40 / 12; maximum leaves 3.
Visible widths: {7: 1, 8: 9, 9: 13, 10: 7}; dimensions: {10×10: 7, 10×7: 1, 10×8: 4, 10×9: 8, 9×8: 5, 9×9: 5}.
Rows min / average / max: 9 / 9.67 / 10; columns: 7 / 8.87 / 10; density: 0.5 / 0.56 / 0.6527777777777778.
10-column boards (index:score:density): 11:3336:0.5000, 16:3346:0.5300, 19:3350:0.5500, 20:3806:0.5100, 23:3912:0.5200, 26:2946:0.5700, 29:3424:0.5400.
Time ms min / average / max: 293 / 686.87 / 1287; total 20606 ms.
Candidate checks min / average / max: 2092581 / 4665989.33 / 8000000.

## Usage

Unique 228 / 300; coverage 76.00%; slots 300.
Usage frequency → number of words: {0: 72, 1: 156, 2: 72}.
Top 15: ANCIENT:2, APPLE:2, AUNT:2, BABY:2, BACK:2, BEAR:2, BIRD:2, BROWN:2, CAKE:2, CHESS:2, COAT:2, COMB:2, DEER:2, DOOR:2, DRESS:2.
Repeat distance min / average / max: 6 / 16.38 / 26. Average is over consecutive reuse events, not per-word averages.
Never used (72): ANGRY, ANSWER, ARRIVE, BASKET, BELIEVE, BICYCLE, BLANKET, BORROW, BOTTLE, BRANCH, BUTTER, BUTTON, CANDLE, CASTLE, CHERRY, CHICKEN, CHOOSE, CLOUD, COFFEE, COTTON, COUSIN, DONKEY, DRAWER, DRIVER, ENOUGH, FARMER, FATHER, FINGER, FLOWER, FOLLOW, FORGET, FRIEND, GARLIC, HAMMER, HARVEST, INSECT, INVITE, ISLAND, JACKET, JUICE, KITCHEN, LIBRARY, LISTEN, MIRROR, MONKEY, MOTHER, MUSEUM, NARROW, NEEDLE, PARROT, PEANUT, PLANET, POCKET, PROMISE, SCREEN, SEARCH, SHALLOW, SISTER, SMOOTH, SPRING, STREET, STUDENT, TEACHER, THUNDER, TICKET, TOMATO, VALLEY, WALNUT, WHALE, WRINKLE, YOGURT, YOUNG.

## App Puzzle 1

generated-v3-000001; seed 3255270515; bounds rows 1–9, columns 1–8; 642 ms.

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

## Comparison (same records and seed, current-run timings)

| Metric | Unbalanced | Balanced |
|---|---|---|
| unique words | 175 | 228 |
| coverage percent | 58.333333333333336 | 76.0 |
| maximum usage | 5 | 2 |
| average quality | 3988.5 | 3772.9 |
| minimum quality | 3135 | 2946 |
| average crossings | 11.733333333333333 | 11.4 |
| average ms | 687.3333333333334 | 686.8666666666667 |
| average attempts | 1.0 | 1.3 |
| average candidate checks | 4000000.0 | 4665989.333333333 |
