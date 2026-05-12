import 'dart:math';
import 'dart:typed_data';

import 'package:BackArt/features/canvas/model/layer.dart';
import 'package:BackArt/features/canvas/state/canvas_state.dart';
import 'package:BackArt/features/canvas/view/canvas_view.dart';
import 'package:BackArt/features/editor/state/editor_state.dart';
import 'package:BackArt/features/editor/widgets/alignment_panel.dart';
import 'package:BackArt/features/editor/widgets/color_editor_panel.dart';
import 'package:BackArt/features/editor/widgets/layer_list_panel.dart';
import 'package:BackArt/features/editor/widgets/shape_editor_panel.dart';
import 'package:BackArt/features/editor/widgets/size_selector_panel.dart';
import 'package:BackArt/features/editor/widgets/template_selector_panel.dart';
import 'package:BackArt/features/editor/widgets/text_editor_panel.dart';
import 'package:BackArt/features/export/service/export_service.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'package:collection/collection.dart'; // Ensure you have this package in pubspec.yaml

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

    final isLayerSelected =
        selectedLayer != null && selectedLayer is! BackgroundLayer;

    return Scaffold(
      drawer: const LayerListPanel(),
      body: SafeArea(
        // child: RepaintBoundary(key: _canvasKey, child: const CanvasView()),
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
          // 将按钮定义为变量，使布局代码更清晰
          final List<Widget> leadingActions = [
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
          ];

          final List<Widget> centerActions = [
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
            // 情境编辑按钮
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

          final List<Widget> trailingActions = [
            PopupMenuButton<Function>(
              icon: const Icon(Icons.more_vert),
              tooltip: '更多选项',
              onSelected: (action) => action(),
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: isLayerSelected,
                  value: () {
                    // 只重置旋转角度
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
                    // 只重置缩放比例
                    final updatedLayer = selectedLayer!.copyWith(scale: 1.0);
                    canvasNotifier.updateLayer(updatedLayer);
                  },
                  child: const ListTile(
                    leading: Icon(Icons.zoom_in_map_rounded),
                    title: Text('重置缩放'),
                  ),
                ),
                // highlight-end
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
                PopupMenuItem(
                  enabled: isLayerSelected,
                  value: () {
                    final duplicatedLayerId = canvasNotifier.duplicateLayer(
                      selectedLayer!.id,
                    );
                    if (duplicatedLayerId != null) {
                      ref.read(selectedLayerProvider.notifier).state =
                          duplicatedLayerId;
                    }
                  },
                  child: const ListTile(
                    leading: Icon(Icons.copy_all_outlined),
                    title: Text('复制图层'),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: () => _shareImage(context, ref),
                  child: const ListTile(
                    leading: Icon(Icons.share),
                    title: Text('分享图片'),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: () => _exportImage(context, ref),
                  child: const ListTile(
                    leading: Icon(Icons.save_alt_outlined),
                    title: Text('导出图片'),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: () => Scaffold.of(context).openDrawer(),
                  child: const ListTile(
                    leading: Icon(Icons.layers_outlined),
                    title: Text('图层列表'),
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
                            // All grid-related settings go into EmojiViewConfig
                            emojiViewConfig: EmojiViewConfig(
                              columns: 8,
                              emojiSizeMax: 28.0,
                              verticalSpacing: 0,
                              horizontalSpacing: 0,
                              backgroundColor: Color(0xFFF2F2F2),
                              recentsLimit: 28,
                            ),
                            // All category-related settings go into CategoryViewConfig
                            categoryViewConfig: CategoryViewConfig(
                              initCategory: Category.RECENT,
                              indicatorColor: Colors.blue,
                              iconColor: Colors.grey,
                              iconColorSelected: Colors.blue,
                              backgroundColor: Color(0xFFF2F2F2),
                              tabIndicatorAnimDuration: kTabScrollDuration,
                              categoryIcons: CategoryIcons(),
                            ),
                            // Skin tone settings
                            skinToneConfig: SkinToneConfig(
                              dialogBackgroundColor: Colors.white,
                              indicatorColor: Colors.grey,
                            ),
                            // Bottom action bar settings
                            bottomActionBarConfig: BottomActionBarConfig(
                              enabled: true,
                              showBackspaceButton: true,
                              backgroundColor: Color(0xFFF2F2F2),
                              buttonIconColor: Colors.grey,
                              buttonColor: Colors.transparent,
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
                const PopupMenuDivider(),
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
          ];

          return Container(
            height: 56.0 + MediaQuery.of(context).padding.bottom,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withAlpha(51),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                ...leadingActions,
                const Spacer(),
                ...centerActions,
                const Spacer(),
                ...trailingActions,
              ],
            ),
          );
        },
      ),
    );
  }
}
