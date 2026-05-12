import 'package:BackArt/features/canvas/state/canvas_state.dart';
import 'package:BackArt/features/editor/state/editor_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AlignmentPanel extends ConsumerWidget {
  const AlignmentPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLayerId = ref.watch(selectedLayerProvider);

    if (selectedLayerId == null) {
      return const Center(child: Text("Please select a layer to align."));
    }

    final horizontalAlignments = {
      Icons.align_horizontal_left: Alignment.centerLeft,
      Icons.align_horizontal_center: Alignment.center,
      Icons.align_horizontal_right: Alignment.centerRight,
    };

    final verticalAlignments = {
      Icons.align_vertical_top: Alignment.topCenter,
      Icons.align_vertical_center: Alignment.center,
      Icons.align_vertical_bottom: Alignment.bottomCenter,
    };

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Align Layer', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildAlignmentRow(
            context,
            ref,
            selectedLayerId,
            'Horizontal',
            horizontalAlignments,
          ),
          const SizedBox(height: 16),
          _buildAlignmentRow(
            context,
            ref,
            selectedLayerId,
            'Vertical',
            verticalAlignments,
          ),
        ],
      ),
    );
  }

  Widget _buildAlignmentRow(
    BuildContext context,
    WidgetRef ref,
    String layerId,
    String title,
    Map<IconData, Alignment> alignments,
  ) {
    final isHorizontal = title == 'Horizontal'; // 判断当前是水平还是垂直行

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: alignments.entries.map((entry) {
            return IconButton.filledTonal(
              icon: Icon(entry.key),
              tooltip: entry.value.toString().split('.').last,
              onPressed: () {
                final notifier = ref.read(canvasStateProvider.notifier);
                // 根据是水平还是垂直行，调用不同的方法
                if (isHorizontal) {
                  notifier.alignLayerHorizontally(layerId, entry.value);
                } else {
                  notifier.alignLayerVertically(layerId, entry.value);
                }
                Navigator.of(context).pop(); // 对齐后自动关闭面板
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
