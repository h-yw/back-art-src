import 'package:flutter/material.dart';

class CompactAlignmentSelector extends StatelessWidget {
  const CompactAlignmentSelector({
    required this.selectedAlignment,
    required this.onAlignmentSelected,
  });

  final Alignment selectedAlignment;
  final ValueChanged<Alignment> onAlignmentSelected;

  IconData _getIconForAlignment(Alignment alignment) {
    if (alignment == Alignment.topLeft) return Icons.north_west_rounded;
    if (alignment == Alignment.topCenter) return Icons.north_rounded;
    if (alignment == Alignment.topRight) return Icons.north_east_rounded;
    if (alignment == Alignment.centerLeft) return Icons.west_rounded;
    if (alignment == Alignment.center) return Icons.center_focus_strong_rounded;
    if (alignment == Alignment.centerRight) return Icons.east_rounded;
    if (alignment == Alignment.bottomLeft) return Icons.south_west_rounded;
    if (alignment == Alignment.bottomCenter) return Icons.south_rounded;
    if (alignment == Alignment.bottomRight) return Icons.south_east_rounded;
    return Icons.place;
  }

  @override
  Widget build(BuildContext context) {
    const alignments = [
      Alignment.topLeft,
      Alignment.topCenter,
      Alignment.topRight,
      Alignment.centerLeft,
      Alignment.center,
      Alignment.centerRight,
      Alignment.bottomLeft,
      Alignment.bottomCenter,
      Alignment.bottomRight,
    ];

    return Container(
      height: 120, // 精确控制高度
      width: 120, // 精确控制宽度
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 2, // 减小间距
        crossAxisSpacing: 2, // 减小间距
        children: alignments.map((alignment) {
          final isSelected = selectedAlignment == alignment;
          return IconButton(
            iconSize: 20, // 减小图标大小
            visualDensity: VisualDensity.compact, // 减小按钮的视觉密度
            icon: Icon(_getIconForAlignment(alignment)),
            tooltip: alignment.toString().split('.').last,
            isSelected: isSelected,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                states,
              ) {
                if (states.contains(WidgetState.selected)) {
                  return Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2);
                }
                return null;
              }),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            onPressed: () => onAlignmentSelected(alignment),
          );
        }).toList(),
      ),
    );
  }
}
