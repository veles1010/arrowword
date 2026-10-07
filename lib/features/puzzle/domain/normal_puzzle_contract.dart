/// Main-game V1 only. Daily and lower-level generation have separate contracts.
const normalPuzzleCount = 36;
const totalNormalPuzzleCount = normalPuzzleCount * 3;

bool isNormalPuzzleIndex(int index) => index >= 1 && index <= normalPuzzleCount;
int normalCompletedCount(int completedThrough) =>
    completedThrough.clamp(0, normalPuzzleCount);
