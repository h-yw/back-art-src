import 'package:BackArt/features/canvas/model/layer.dart';
import 'package:BackArt/features/canvas/state/canvas_state.dart';
import 'package:BackArt/features/editor/widgets/text_editor_panel.dart';
import 'package:BackArt/widgets/slide_picker/slide_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view/editor_screen.dart';

class ShapeEditorPanel extends ConsumerWidget {
  const ShapeEditorPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLayerId = ref.watch(selectedLayerProvider);
    final canvasNotifier = ref.read(canvasStateProvider.notifier);

    final layer = ref
        .watch(canvasStateProvider)
        .layers
        .firstWhere(
          (l) => l.id == selectedLayerId,
          orElse: () => ShapeLayer.initial(), // Fallback
        );

    // 如果选中的不是形状图层，则不显示任何内容
    if (layer is! ShapeLayer) {
      return const Center(child: Text("Please select a shape layer."));
    }

    final shapeLayer = layer;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Text('Edit Shape', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: 'Shape Type',
            child: Center(
              child: ToggleButtons(
                isSelected: [
                  shapeLayer.shapeType == ShapeType.rectangle,
                  shapeLayer.shapeType == ShapeType.circle,
                ],
                onPressed: (index) {
                  canvasNotifier.updateLayer(
                    shapeLayer.copyWith(
                      shapeType:
                      index == 0 ? ShapeType.rectangle : ShapeType.circle,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8.0),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(Icons.rectangle_outlined),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(Icons.circle_outlined),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: 'Shape Color',
            child: SlidePicker(
              pickerColor: shapeLayer.color,
              onColorChanged: (newColor) {
                canvasNotifier.updateLayer(
                  shapeLayer.copyWith(color: newColor),
                );
              },
            ),
          ),
          // **填充/描边切换**
          _buildSection(
            context,
            title: 'Style',
            child: Center(
              child: ToggleButtons(
                isSelected: [
                  shapeLayer.paintStyle == PaintingStyle.fill,
                  shapeLayer.paintStyle == PaintingStyle.stroke,
                ],
                onPressed: (index) {
                  canvasNotifier.updateLayer(
                    shapeLayer.copyWith(
                      paintStyle: index == 0
                          ? PaintingStyle.fill
                          : PaintingStyle.stroke,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8.0),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(Icons.format_color_fill),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(Icons.border_style),
                  ),
                ],
              ),
            ),
          ),
          // **描边宽度滑块 (仅在描边模式下显示)**
          if (shapeLayer.paintStyle == PaintingStyle.stroke)
            _buildSection(
              context,
              title: 'Stroke Width',
              child: Slider(
                value: (shapeLayer.strokeWidth??2.0),
                min: 1.0,
                max: 50.0,
                divisions: 49,
                label: (shapeLayer.strokeWidth??2.0).round().toString(),
                onChanged: (newWidth) {
                  canvasNotifier.updateLayerLive(
                    shapeLayer.copyWith(strokeWidth: newWidth),
                  );
                },
                onChangeEnd: (newWidth) {
                  // 拖动结束后提交
                  canvasNotifier.commitLiveUpdate();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
