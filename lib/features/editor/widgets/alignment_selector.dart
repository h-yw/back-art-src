
import 'package:flutter/material.dart';

class AlignmentSelector extends StatelessWidget {
  const AlignmentSelector({
    Key? key,
    this.selectedAlignment,
    required this.onAlignmentSelected,
  }) : super(key: key);

  final Alignment? selectedAlignment;
  final ValueChanged<Alignment> onAlignmentSelected;

  @override
  Widget build(BuildContext context) {
    const alignments = {
      '左上': Alignment.topLeft,
      '中上': Alignment.topCenter,
      '右上': Alignment.topRight,
      '左中': Alignment.centerLeft,
      '居中': Alignment.center,
      '右中': Alignment.centerRight,
      '左下': Alignment.bottomLeft,
      '中下': Alignment.bottomCenter,
      '右下': Alignment.bottomRight,
    };

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(0.0), // Add padding
      mainAxisSpacing: 4.0, // Reduce spacing
      crossAxisSpacing: 4.0, // Reduce spacing
      children: alignments.entries.map((entry) {
        final isSelected = selectedAlignment == entry.value;
        return InkWell(
          onTap: () => onAlignmentSelected(entry.value),
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : null,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getIconForAlignment(entry.value),
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                  size: 28,
                ),
                Text(
                  entry.key,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

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
}
