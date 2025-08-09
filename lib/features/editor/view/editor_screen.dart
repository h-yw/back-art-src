import 'dart:math';
import 'dart:typed_data';

import 'package:BackArt/features/canvas/model/layer.dart';
import 'package:BackArt/features/canvas/state/canvas_state.dart';
import 'package:BackArt/features/canvas/view/canvas_view.dart';
import 'package:BackArt/features/editor/widgets/alignment_panel.dart';
import 'package:BackArt/features/editor/widgets/color_editor_panel.dart';
import 'package:BackArt/features/editor/widgets/layer_list_panel.dart';
import 'package:BackArt/features/editor/widgets/shape_editor_panel.dart';
import 'package:BackArt/features/editor/widgets/size_selector_panel.dart';
import 'package:BackArt/features/editor/widgets/template_selector_panel.dart';
import 'package:BackArt/features/editor/widgets/text_editor_panel.dart';
import 'package:BackArt/features/editor/widgets/unicode_emoji_selector_panel.dart';
import 'package:BackArt/features/export/service/export_service.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'package:collection/collection.dart'; // Ensure you have this package in pubspec.yaml

enum SelectedLayerType { none, text, image, shape, background }

// selectedLayerProvider 保持不变，移到这里以保持文件独立性
final selectedLayerProvider = StateProvider<String?>((ref) {
  final layers = ref.read(canvasStateProvider).layers;
  // 查找第一个非背景的图层作为默认选中
  final firstEditableLayer = layers.firstWhere(
    (l) => l is! BackgroundLayer,
    orElse: () => layers.last,
  );
  return firstEditableLayer.id;
});

class EditorScreen extends ConsumerWidget {
  EditorScreen({Key? key}) : super(key: key);

  // A GlobalKey is needed to access the RepaintBoundary
  final GlobalKey _canvasKey = GlobalKey();

  Future<void> _pickImage(WidgetRef ref) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final data = await pickedFile.readAsBytes();
      final image = await _bytesToImage(data);
      final layer = ImageLayer.fromImage(image);
      ref.read(canvasStateProvider.notifier).addLayer(layer);
    }
  }

  Future<ui.Image> _bytesToImage(Uint8List data) async {
    final codec = await ui.instantiateImageCodec(data);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _exportImage(BuildContext context, WidgetRef ref) async {
    // 弹出分辨率选择对话框
    final double? selectedPixelRatio = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择导出分辨率'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('标准 (Standard)'),
              subtitle: const Text('适用于快速分享'),
              onTap: () => Navigator.of(context).pop(1.0), // 1x 分辨率
            ),
            ListTile(
              title: const Text('高清 (HD)'),
              subtitle: const Text('推荐，质量与速度均衡'),
              onTap: () => Navigator.of(context).pop(3.0), // 3x 分辨率
            ),
            ListTile(
              title: const Text('超清 (4K+)'),
              subtitle: const Text('适用于打印或超高清屏幕'),
              onTap: () => Navigator.of(context).pop(5.0), // 5x 分辨率
            ),
          ],
        ),
      ),
    );

    // 如果用户没有选择（例如点击了对话框外部），则不执行任何操作
    if (selectedPixelRatio == null) return;

    // -- 后续的导出逻辑 --
    final originalSelectedId = ref.read(selectedLayerProvider);
    ref.read(selectedLayerProvider.notifier).state = null;

    await Future.delayed(const Duration(milliseconds: 50));

    final service = ExportService();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // 使用用户选择的 pixelRatio 进行保存
    final success = await service.saveCanvas(
      _canvasKey,
      pixelRatio: selectedPixelRatio,
    );
    Navigator.of(context).pop();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(success ? '已保存到相册!' : '保存失败.')));

    ref.read(selectedLayerProvider.notifier).state = originalSelectedId;
  }

  void _shareImage(BuildContext context, WidgetRef ref) async {
    final originalSelectedId = ref.read(selectedLayerProvider);
    ref.read(selectedLayerProvider.notifier).state = null;

    await Future.delayed(const Duration(milliseconds: 50));

    final service = ExportService();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    await service.shareCanvas(
      _canvasKey,
      pixelRatio: 3.0, // 分享时使用 3x 分辨率
    );

    Navigator.of(context).pop();

    ref.read(selectedLayerProvider.notifier).state = originalSelectedId;
  }

  // -- 我们将之前创建 emoji 的逻辑提取到一个新方法中 --
  void _addEmojiToCanvas(String emoji, WidgetRef ref) {
    final emojiLayer = TextLayer.initial().copyWith(
      text: emoji,
      style: const TextStyle(
        fontSize: 150,
        backgroundColor: Colors.transparent,
      ),
      rect: const Rect.fromLTWH(400, 800, 150, 150),
    );
    ref.read(canvasStateProvider.notifier).addLayer(emojiLayer);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //  监听选择的图层和图层列表的变化
    final selectedLayerId = ref.watch(selectedLayerProvider);
    final layers = ref.watch(canvasStateProvider).layers;

    // --- 获取 notifier 和撤销/重做状态 ---
    final canvasNotifier = ref.read(canvasStateProvider.notifier);
    final canUndo = ref.watch(
      canvasStateProvider.select((s) => canvasNotifier.canUndo),
    );
    final canRedo = ref.watch(
      canvasStateProvider.select((s) => canvasNotifier.canRedo),
    );

    // 判断当前选中的是否是文本图层
    final selectedLayer = layers.firstWhereOrNull(
      (l) => l.id == selectedLayerId,
    );
    final selectedType = switch (selectedLayer) {
      TextLayer() => SelectedLayerType.text,
      ImageLayer() => SelectedLayerType.image,
      ShapeLayer() => SelectedLayerType.shape,
      BackgroundLayer() => SelectedLayerType.background,
      _ => SelectedLayerType.none,
    };
    final isTransformableLayerSelected =
        selectedType == SelectedLayerType.text ||
        selectedType == SelectedLayerType.image ||
        selectedType == SelectedLayerType.shape;

    final isTextLayerSelected = selectedLayer is TextLayer;
    final isLayerSelected =
        selectedLayer != null && selectedLayer is! BackgroundLayer;

    return Scaffold(
      appBar: AppBar(
        title: Text('BackArt'), // You can customize the title
        leading: IconButton(
          icon: const Icon(Icons.layers_outlined),
          tooltip: '图层列表',
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: '撤销',
            onPressed: canUndo ? () => canvasNotifier.undo() : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: '重做',
            onPressed: canRedo ? () => canvasNotifier.redo() : null,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: '分享图片',
            onPressed: () => _shareImage(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.save_alt_outlined),
            tooltip: '导出图片',
            onPressed: () => _exportImage(context, ref),
          ),
          PopupMenuButton<Function>(
            icon: const Icon(Icons.more_vert),
            tooltip: '更多选项',
            onSelected: (action) => action(),
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: isLayerSelected,
                value: () {
                  final updatedLayer = selectedLayer!.copyWith(rotation: 0.0);
                  canvasNotifier.updateLayer(updatedLayer);
                },
                child: const ListTile(
                  leading: Icon(Icons.rotate_90_degrees_ccw),
                  title: Text('重置旋转'),
                ),
              ),
              PopupMenuItem(
                enabled: isLayerSelected,
                value: () {
                  final updatedLayer = selectedLayer!.copyWith(scale: 1.0);
                  canvasNotifier.updateLayer(updatedLayer);
                },
                child: const ListTile(
                  leading: Icon(Icons.zoom_in_map_rounded),
                  title: Text('重置缩放'),
                ),
              ),
              PopupMenuItem(
                enabled: isTransformableLayerSelected,
                value: () => showModalBottomSheet(
                  context: context,
                  builder: (context) => const AlignmentPanel(),
                ),
                child: const ListTile(
                  leading: Icon(Icons.align_horizontal_center_rounded),
                  title: Text('对齐图层'),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return EmojiPicker(
                        onEmojiSelected: (Category? category, Emoji emoji) {
                          _addEmojiToCanvas(emoji.emoji, ref);
                          Navigator.of(context).pop();
                        },
                        config: const Config(
                          emojiViewConfig: EmojiViewConfig(
                            columns: 8,
                          ),
                          categoryViewConfig: CategoryViewConfig(
                            initCategory: Category.RECENT,
                          ),
                          skinToneConfig: SkinToneConfig(),
                          bottomActionBarConfig: BottomActionBarConfig(
                            enabled: true,
                          ),
                        ),
                      );
                    },
                  );
                },
                child: const ListTile(
                  leading: Icon(Icons.emoji_emotions_outlined),
                  title: Text('添加表情'),
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: () => showModalBottomSheet(
                  context: context,
                  builder: (context) => const TemplateSelectorPanel(),
                ),
                child: const ListTile(
                  leading: Icon(Icons.dashboard_customize_outlined),
                  title: Text('选择模版'),
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: const LayerListPanel(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final canvasState = ref.watch(canvasStateProvider);
            final double scale = min(
              constraints.biggest.width / canvasState.canvasSize.width,
              constraints.biggest.height / canvasState.canvasSize.height,
            );
            final canvasDisplaySize = canvasState.canvasSize * scale;
            return Center(
              child: RepaintBoundary(
                key: _canvasKey,
                child: SizedBox(
                  width: canvasDisplaySize.width,
                  height: canvasDisplaySize.height,
                  child: CanvasView(canvasDisplaySize: canvasDisplaySize),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          final List<Widget> bottomBarContent;

          if (isTextLayerSelected && selectedLayer is TextLayer) {
            final textLayer = selectedLayer as TextLayer;
            bottomBarContent = [
              Expanded(
                child: Slider(
                  value: textLayer.style.fontSize ?? 16.0,
                  min: 8.0,
                  max: 200.0,
                  divisions: 92,
                  label: (textLayer.style.fontSize ?? 16.0).toStringAsFixed(1),
                  onChanged: (v) => canvasNotifier.updateLayerLive(textLayer.copyWith(style: textLayer.style.copyWith(fontSize: v))),
                  onChangeEnd: (v) => canvasNotifier.commitLiveUpdate(),
                ),
              ),
              IconButton(
                icon: Icon(Icons.color_lens_outlined, color: textLayer.style.color ?? Colors.black),
                tooltip: '文本颜色',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: textLayer.style.color ?? Colors.black,
                        onColorChanged: (newColor) {
                          canvasNotifier.updateLayer(textLayer.copyWith(style: textLayer.style.copyWith(color: newColor)));
                        },
                        enableAlpha: true,
                        labelTypes: const [],
                        pickerAreaHeightPercent: 0.8,
                      ),
                    ),
                  );
                },
              ),
              ToggleButtons(
                isSelected: [
                  textLayer.textAlign == TextAlign.left,
                  textLayer.textAlign == TextAlign.center,
                  textLayer.textAlign == TextAlign.right,
                ],
                onPressed: (index) {
                  final newAlignment = [TextAlign.left, TextAlign.center, TextAlign.right][index];
                  canvasNotifier.updateLayer(textLayer.copyWith(textAlign: newAlignment));
                },
                borderRadius: BorderRadius.circular(8.0),
                constraints: const BoxConstraints(minHeight: 36, minWidth: 40),
                children: const [
                  Icon(Icons.format_align_left, size: 20),
                  Icon(Icons.format_align_center, size: 20),
                  Icon(Icons.format_align_right, size: 20),
                ],
              ),
            ];
          } else {
            bottomBarContent = [
              PopupMenuButton<Function>(
                icon: const Icon(Icons.add_circle_outline_rounded),
                tooltip: '添加图层',
                onSelected: (action) => action(),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: () => ref
                        .read(canvasStateProvider.notifier)
                        .addLayer(TextLayer.initial().copyWith(text: "New Text")),
                    child: const ListTile(
                      leading: Icon(Icons.add_box_outlined),
                      title: Text('添加文本'),
                    ),
                  ),
                  PopupMenuItem(
                    value: () => ref
                        .read(canvasStateProvider.notifier)
                        .addLayer(ShapeLayer.initial()),
                    child: const ListTile(
                      leading: Icon(Icons.add_card_outlined),
                      title: Text('添加形状'),
                    ),
                  ),
                  PopupMenuItem(
                    value: () => _pickImage(ref),
                    child: const ListTile(
                      leading: Icon(Icons.add_photo_alternate_outlined),
                      title: Text('添加图片'),
                    ),
                  ),
                ],
              ),
              if (isLayerSelected)
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded),
                  tooltip: '编辑图层',
                  onPressed: () {
                    switch (selectedType) {
                      case SelectedLayerType.text:
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => const TextEditorPanel(),
                        );
                        break;
                      case SelectedLayerType.shape:
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => const ShapeEditorPanel(),
                        );
                        break;
                      default:
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('该图层没有专属编辑选项')),
                        );
                        break;
                    }
                  },
                ),
              IconButton(
                icon: const Icon(Icons.color_lens_outlined),
                tooltip: '背景颜色',
                onPressed: () => showModalBottomSheet(
                  context: context,
                  builder: (context) => const ColorEditorPanel(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.aspect_ratio_outlined),
                tooltip: '画布尺寸',
                onPressed: () => showModalBottomSheet(
                  context: context,
                  builder: (context) => const SizeSelectorPanel(),
                ),
              ),
            ];
          }

          return BottomAppBar(
            height: 56.0 + MediaQuery.of(context).padding.bottom,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
            elevation: 8.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: bottomBarContent,
            ),
          );
        },
      ),
    );
  }
}
