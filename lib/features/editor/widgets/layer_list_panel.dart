import 'package:BackArt/features/canvas/model/layer.dart';
import 'package:BackArt/features/canvas/state/canvas_state.dart';
import 'package:BackArt/features/editor/widgets/text_editor_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view/editor_screen.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class LayerListPanel extends ConsumerWidget {
  const LayerListPanel({Key? key}) : super(key: key);

  String _getLayerTitle(Layer layer) {
    switch (layer) {
      case TextLayer():
        // 如果文本内容为空，则显示一个占位符
        if (layer.text.trim().isEmpty) return 'Empty Text';
        // 如果文本内容过长，进行截断
        return layer.text.length > 20
            ? '${layer.text.substring(0, 20)}...'
            : layer.text;
      case ImageLayer():
        return 'Image Layer'; // 图片图层的描述
      case ShapeLayer():
        // 根据形状类型给出更具体的名称, e.g., "Rectangle Shape"
        return '${layer.shapeType.name.capitalize()} Shape';
      default:
        return 'Untitled Layer';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canvasState = ref.watch(canvasStateProvider);
    final layers = canvasState.layers;
    final selectedLayerId = ref.watch(selectedLayerProvider);
    final canvasNotifier = ref.read(canvasStateProvider.notifier);

    final backgroundLayer = layers[0] as BackgroundLayer;

    final reorderableLayers =
    layers.where((l) => l is! BackgroundLayer).toList().reversed.toList();

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Display the non-reorderable background layer at the top
            ListTile(
              title: const Text('Background'),
              selected: backgroundLayer.id == selectedLayerId,
              onTap: () {
                ref.read(selectedLayerProvider.notifier).state =
                    backgroundLayer.id;
                Navigator.of(context).pop();
              },
            ),
            const Divider(),
            // The reorderable list for all other layers
            Expanded(
              child: ReorderableListView.builder(
                itemCount: reorderableLayers.length,
                itemBuilder: (context, index) {
                  final layer = reorderableLayers[index];
                  final isSelected = layer.id == selectedLayerId;

                  return ListTile(
                    key: ValueKey(layer.id), // Important for reordering
                    title: Text(_getLayerTitle(layer)),
                    selected: isSelected,
                    onTap: () {
                      ref.read(selectedLayerProvider.notifier).state = layer.id;
                      Navigator.of(context).pop();
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // --- 可见性切换按钮 ---
                        IconButton(
                          icon: Icon(
                            layer.isVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          tooltip: layer.isVisible ? 'Hide' : 'Show',
                          onPressed: () =>
                              canvasNotifier.toggleLayerVisibility(layer.id),
                        ),
                        // --- 锁定切换按钮 ---
                        IconButton(
                          icon: Icon(
                            layer.isLocked ? Icons.lock : Icons.lock_open,
                          ),
                          tooltip: layer.isLocked ? 'Unlock' : 'Lock',
                          onPressed: () =>
                              canvasNotifier.toggleLayerLock(layer.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => canvasNotifier.removeLayer(layer.id),
                        ),
                      ],
                    ),
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  final layer = reorderableLayers[oldIndex];
                  if (layer.isLocked) return;
                  canvasNotifier.reorderLayer(oldIndex, newIndex);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
