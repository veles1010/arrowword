import 'package:flutter/material.dart';

import '../features/puzzle/domain/puzzle_difficulty.dart';
import '../theme/arrowword_visuals.dart';

class PuzzleDifficultySelector extends StatelessWidget {
  const PuzzleDifficultySelector({
    required this.selected,
    required this.onChanged,
    super.key,
  });
  final PuzzleDifficulty selected;
  final ValueChanged<PuzzleDifficulty> onChanged;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: SegmentedButton<PuzzleDifficulty>(
      segments: [
        for (final difficulty in PuzzleDifficulty.values)
          ButtonSegment(
            value: difficulty,
            label: Text(
              difficulty.turkishLabel,
              style: difficulty == selected
                  ? TextStyle(
                      color: ArrowwordVisuals.of(context).difficultyAccent(
                        difficulty,
                        Theme.of(context).colorScheme,
                      ),
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationThickness: 2,
                    )
                  : null,
            ),
          ),
      ],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onChanged(selection.single),
      style: const ButtonStyle(
        visualDensity: VisualDensity.standard,
        minimumSize: WidgetStatePropertyAll(Size(48, 48)),
      ),
    ),
  );
}
