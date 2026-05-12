// lib/features/editor/widgets/text_editor_panel.dart

import 'package:BackArt/config/font_list.dart';
import 'package:BackArt/features/canvas/model/layer.dart';
import 'package:BackArt/features/canvas/state/canvas_state.dart';
import 'package:BackArt/features/editor/state/editor_state.dart';
import 'package:BackArt/features/editor/widgets/compact-alignment-selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

FontWeight _sliderValueToFontWeight(double value) {
  switch (value.round()) {
    case 1:
      return FontWeight.w100;
    case 2:
      return FontWeight.w200;
    case 3:
      return FontWeight.w300;
    case 4:
      return FontWeight.w400;
    case 5:
      return FontWeight.w500;
    case 6:
      return FontWeight.w600;
    case 7:
      return FontWeight.w700;
    case 8:
      return FontWeight.w800;
    case 9:
      return FontWeight.w900;
    default:
      return FontWeight.w400; // 默认为常规
  }
}

// 辅助方法：将 FontWeight 转换为滑块值
double _fontWeightToSliderValue(FontWeight? weight) {
  if (weight == null) return 4.0; // 默认值为 w400
  // FontWeight.toString() 的结果是 "FontWeight.w400"，我们提取其中的数字
  return (FontWeight.values.indexOf(weight) + 1).toDouble();
}

class TextEditorPanel extends ConsumerWidget {
  const TextEditorPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLayerId = ref.watch(selectedLayerProvider);
    final canvasNotifier = ref.read(canvasStateProvider.notifier);

    final layer = ref
        .watch(canvasStateProvider)
        .layers
        .firstWhere(
          (l) => l.id == selectedLayerId,
          orElse: () => TextLayer.initial(),
        );

    // 如果选中的不是文本图层，则不显示任何内容
    if (layer is! TextLayer) {
      return const Center(child: Text("Please select a text layer."));
    }

    final textLayer = layer;

    // 使用 ListView 来容纳 ExpansionTile
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        // --- 第一组：内容与字体 ---
        ExpansionTile(
          title: const Text(
            '内容与字体',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          initiallyExpanded: true, // 默认展开
          children: [
            _buildSectionPadding(
              child: TextFormField(
                initialValue: textLayer.text,
                decoration: const InputDecoration(
                  labelText: '文本内容',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                minLines: 1,
                onChanged: (newText) {
                  canvasNotifier.updateLayerLive(
                    textLayer.copyWith(text: newText),
                  );
                },
                onEditingComplete: () {
                  canvasNotifier.commitLiveUpdate();
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
            _buildSectionPadding(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: '字体',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                isExpanded: true,
                value:
                    AppFonts.fontNameList.contains(textLayer.style.fontFamily)
                    ? textLayer.style.fontFamily
                    : AppFonts.fontNameList.first,
                onChanged: (newFontFamily) {
                  if (newFontFamily != null) {
                    canvasNotifier.updateLayer(
                      textLayer.copyWith(
                        style: textLayer.style.copyWith(
                          fontFamily: newFontFamily,
                        ),
                      ),
                    );
                  }
                },
                items: AppFonts.fontNameList.map((font) {
                  return DropdownMenuItem(
                    value: font,
                    child: Text(
                      font,
                      style: TextStyle(fontFamily: font, fontSize: 16),
                    ),
                  );
                }).toList(),
              ),
            ),
            _buildCompactSliderRow(
              context,
              label1: '字号',
              value1: textLayer.style.fontSize ?? 16.0,
              min1: 8.0,
              max1: 200.0,
              divisions1: 92,
              onChanged1: (v) => canvasNotifier.updateLayerLive(
                textLayer.copyWith(
                  style: textLayer.style.copyWith(fontSize: v),
                ),
              ),
              onChangeEnd1: (v) => canvasNotifier.commitLiveUpdate(),
              label2: '字重',
              value2: _fontWeightToSliderValue(textLayer.style.fontWeight),
              min2: 1,
              max2: 9,
              divisions2: 8,
              onChanged2: (v) {
                final newWeight = _sliderValueToFontWeight(v);
                canvasNotifier.updateLayerLive(
                  textLayer.copyWith(
                    style: textLayer.style.copyWith(fontWeight: newWeight),
                  ),
                );
              },
              onChangeEnd2: (v) => canvasNotifier.commitLiveUpdate(),
            ),
          ],
        ),

        // --- 第二组：颜色与样式 ---
        ExpansionTile(
          title: const Text(
            '颜色与样式',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          initiallyExpanded: true,
          children: [
            ListTile(
              title: Text(
                '文本颜色',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            _buildSectionPadding(
              child: SlidePicker(
                pickerColor: textLayer.style.color ?? Colors.black,
                onColorChanged: (newColor) {
                  canvasNotifier.updateLayer(
                    textLayer.copyWith(
                      style: textLayer.style.copyWith(color: newColor),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: Text(
                '启用描边',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              value: textLayer.hasStroke,
              onChanged: (isEnabled) {
                canvasNotifier.updateLayer(
                  textLayer.copyWith(hasStroke: isEnabled),
                );
              },
            ),
            if (textLayer.hasStroke) ...[
              _buildSliderListItem(
                context: context,
                label: '描边宽度',
                value: textLayer.strokeWidth,
                min: 0.5,
                max: 20.0,
                divisions: 39,
                onChanged: (newWidth) {
                  canvasNotifier.updateLayerLive(
                    textLayer.copyWith(strokeWidth: newWidth),
                  );
                },
                onChangeEnd: (newWidth) {
                  canvasNotifier.commitLiveUpdate();
                },
              ),
              ListTile(
                title: Text(
                  '描边颜色',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _buildSectionPadding(
                child: SlidePicker(
                  pickerColor: textLayer.strokeColor,
                  onColorChanged: (newColor) {
                    canvasNotifier.updateLayer(
                      textLayer.copyWith(strokeColor: newColor),
                    );
                  },
                ),
              ),
            ],
          ],
        ),

        // --- 第三组：布局与对齐 ---
        ExpansionTile(
          title: const Text(
            '布局与对齐',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          initiallyExpanded: true,
          children: [
            _buildCompactSliderRow(
              context,
              label1: '行高',
              value1: textLayer.style.height ?? 1.5,
              min1: 0.5,
              max1: 4.0,
              divisions1: 35,
              onChanged1: (v) => canvasNotifier.updateLayerLive(
                textLayer.copyWith(style: textLayer.style.copyWith(height: v)),
              ),
              onChangeEnd1: (v) => canvasNotifier.commitLiveUpdate(),
              label2: '字距',
              value2: textLayer.style.letterSpacing ?? 0.0,
              min2: -5.0,
              max2: 20.0,
              divisions2: 50,
              onChanged2: (v) => canvasNotifier.updateLayerLive(
                textLayer.copyWith(
                  style: textLayer.style.copyWith(letterSpacing: v),
                ),
              ),
              onChangeEnd2: (v) => canvasNotifier.commitLiveUpdate(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  // --- 文本对齐 ---
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '文本对齐',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        ToggleButtons(
                          isSelected: [
                            textLayer.textAlign == TextAlign.left,
                            textLayer.textAlign == TextAlign.center,
                            textLayer.textAlign == TextAlign.right,
                          ],
                          onPressed: (index) {
                            final newAlignment = [
                              TextAlign.left,
                              TextAlign.center,
                              TextAlign.right,
                            ][index];
                            canvasNotifier.updateLayer(
                              textLayer.copyWith(textAlign: newAlignment),
                            );
                          },
                          borderRadius: BorderRadius.circular(8.0),
                          constraints: const BoxConstraints(
                            minHeight: 36,
                            minWidth: 40,
                          ), // 紧凑约束
                          children: const [
                            Icon(Icons.format_align_left, size: 20),
                            Icon(Icons.format_align_center, size: 20),
                            Icon(Icons.format_align_right, size: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // --- 布局对齐 ---
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '布局对齐',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        CompactAlignmentSelector(
                          selectedAlignment:
                              textLayer.alignment ?? Alignment.center,
                          onAlignmentSelected: (alignment) {
                            canvasNotifier.updateLayer(
                              textLayer.copyWith(alignment: alignment),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 辅助方法，用于构建带边距的子组件
  Widget _buildSectionPadding({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: child,
    );
  }

  // 辅助方法，用于构建标准的滑块列表项
  Widget _buildSliderListItem({
    required BuildContext context,
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
  }) {
    return ListTile(
      title: Text(label, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        label: value.toStringAsFixed(1),
        onChanged: onChanged,
        onChangeEnd: onChangeEnd,
      ),
    );
  }

  Widget _buildCompactSliderRow(
    BuildContext context, {
    required String label1,
    required double value1,
    required double min1,
    required double max1,
    required int divisions1,
    required ValueChanged<double> onChanged1,
    required ValueChanged<double> onChangeEnd1,
    required String label2,
    required double value2,
    required double min2,
    required double max2,
    required int divisions2,
    required ValueChanged<double> onChanged2,
    required ValueChanged<double> onChangeEnd2,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label1, style: Theme.of(context).textTheme.labelLarge),
                Slider(
                  value: value1,
                  min: min1,
                  max: max1,
                  divisions: divisions1,
                  label: value1.toStringAsFixed(1),
                  onChanged: onChanged1,
                  onChangeEnd: onChangeEnd1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 24), // 两个滑块之间的间距
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label2, style: Theme.of(context).textTheme.labelLarge),
                Slider(
                  value: value2,
                  min: min2,
                  max: max2,
                  divisions: divisions2,
                  label: value2.toStringAsFixed(1),
                  onChanged: onChanged2,
                  onChangeEnd: onChangeEnd2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
