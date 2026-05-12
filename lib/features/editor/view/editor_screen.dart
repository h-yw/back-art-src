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

class _ToolbarAction {
  const _ToolbarAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDestructive;
}

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

  void _showTextEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const TextEditorPanel(),
    );
  }

  void _showShapeEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const ShapeEditorPanel(),
    );
  }

  void _showAlignmentEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const AlignmentPanel(),
    );
  }

  void _showBackgroundEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const ColorEditorPanel(),
    );
  }

  void _showCanvasSizeEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const SizeSelectorPanel(),
    );
  }

  void _showTemplateSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const TemplateSelectorPanel(),
    );
  }

  void _showEmojiPicker(BuildContext context, WidgetRef ref) {
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
              emojiSizeMax: 28.0,
              verticalSpacing: 0,
              horizontalSpacing: 0,
              backgroundColor: Color(0xFFF2F2F2),
              recentsLimit: 28,
            ),
            categoryViewConfig: CategoryViewConfig(
              initCategory: Category.RECENT,
              indicatorColor: Colors.blue,
              iconColor: Colors.grey,
              iconColorSelected: Colors.blue,
              backgroundColor: Color(0xFFF2F2F2),
              tabIndicatorAnimDuration: kTabScrollDuration,
              categoryIcons: CategoryIcons(),
            ),
            skinToneConfig: SkinToneConfig(
              dialogBackgroundColor: Colors.white,
              indicatorColor: Colors.grey,
            ),
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
  }

  void _showAddLayerSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: const Text('添加文本'),
              onTap: () {
                ref
                    .read(canvasStateProvider.notifier)
                    .addLayer(TextLayer.initial().copyWith(text: 'New Text'));
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_card_outlined),
              title: const Text('添加形状'),
              onTap: () {
                ref
                    .read(canvasStateProvider.notifier)
                    .addLayer(ShapeLayer.initial());
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_photo_alternate_outlined),
              title: const Text('添加图片'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_emotions_outlined),
              title: const Text('添加表情'),
              onTap: () {
                Navigator.of(context).pop();
                _showEmojiPicker(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _resetSelectedLayerTransform(
    CanvasStateNotifier canvasNotifier,
    Layer selectedLayer,
  ) {
    canvasNotifier.updateLayer(
      selectedLayer.copyWith(rotation: 0.0, scale: 1.0),
    );
  }

  void _duplicateSelectedLayer(
    WidgetRef ref,
    CanvasStateNotifier canvasNotifier,
    Layer selectedLayer,
  ) {
    final duplicatedLayerId = canvasNotifier.duplicateLayer(selectedLayer.id);
    if (duplicatedLayerId != null) {
      ref.read(selectedLayerProvider.notifier).state = duplicatedLayerId;
    }
  }

  void _deleteSelectedLayer(
    WidgetRef ref,
    CanvasStateNotifier canvasNotifier,
    List<Layer> layers,
    Layer selectedLayer,
  ) {
    final nextSelectedId = nextEditableLayerId(
      layers,
      currentLayerId: selectedLayer.id,
    );
    canvasNotifier.removeLayer(selectedLayer.id);
    ref.read(selectedLayerProvider.notifier).state = nextSelectedId;
  }

  List<_ToolbarAction> _buildContextActions(
    BuildContext context,
    WidgetRef ref,
    CanvasStateNotifier canvasNotifier,
    List<Layer> layers,
    Layer? selectedLayer,
    SelectedLayerType selectedType,
  ) {
    if (selectedLayer == null || selectedLayer is BackgroundLayer) {
      return [
        _ToolbarAction(
          icon: Icons.color_lens_outlined,
          label: '背景',
          onPressed: () => _showBackgroundEditor(context),
          isPrimary: true,
        ),
        _ToolbarAction(
          icon: Icons.aspect_ratio_outlined,
          label: '尺寸',
          onPressed: () => _showCanvasSizeEditor(context),
        ),
        _ToolbarAction(
          icon: Icons.dashboard_customize_outlined,
          label: '模板',
          onPressed: () => _showTemplateSelector(context),
        ),
      ];
    }

    final actions = <_ToolbarAction>[];
    switch (selectedType) {
      case SelectedLayerType.text:
        actions.add(
          _ToolbarAction(
            icon: Icons.edit_note_rounded,
            label: '文本',
            onPressed: () => _showTextEditor(context),
            isPrimary: true,
          ),
        );
        break;
      case SelectedLayerType.shape:
        actions.add(
          _ToolbarAction(
            icon: Icons.category_outlined,
            label: '形状',
            onPressed: () => _showShapeEditor(context),
            isPrimary: true,
          ),
        );
        break;
      case SelectedLayerType.image:
      case SelectedLayerType.background:
      case SelectedLayerType.none:
        break;
    }

    actions.addAll([
      _ToolbarAction(
        icon: Icons.align_horizontal_center_rounded,
        label: '对齐',
        onPressed: () => _showAlignmentEditor(context),
      ),
      _ToolbarAction(
        icon: Icons.center_focus_strong_outlined,
        label: '重置',
        onPressed: () =>
            _resetSelectedLayerTransform(canvasNotifier, selectedLayer),
      ),
      _ToolbarAction(
        icon: Icons.copy_all_outlined,
        label: '复制',
        onPressed: () =>
            _duplicateSelectedLayer(ref, canvasNotifier, selectedLayer),
      ),
      _ToolbarAction(
        icon: Icons.delete_outline,
        label: '删除',
        onPressed: () =>
            _deleteSelectedLayer(ref, canvasNotifier, layers, selectedLayer),
        isDestructive: true,
      ),
    ]);

    return actions;
  }

  String _selectionTitle(SelectedLayerType selectedType) {
    return switch (selectedType) {
      SelectedLayerType.text => '文本图层',
      SelectedLayerType.image => '图片图层',
      SelectedLayerType.shape => '形状图层',
      SelectedLayerType.background => '背景',
      SelectedLayerType.none => '画布工具',
    };
  }

  String _selectionSubtitle(
    Layer? selectedLayer,
    SelectedLayerType selectedType,
  ) {
    return switch (selectedLayer) {
      TextLayer() =>
        selectedLayer.text.trim().isEmpty
            ? '编辑文字、排版和位置'
            : selectedLayer.text.trim(),
      ImageLayer() => '调整位置、缩放和层级',
      ShapeLayer() => '${selectedLayer.shapeType.name} · 调整样式和位置',
      BackgroundLayer() => '调整背景颜色、尺寸和模板',
      _ => '先选择图层，或直接添加新的元素',
    };
  }

  IconData _selectionIcon(SelectedLayerType selectedType) {
    return switch (selectedType) {
      SelectedLayerType.text => Icons.text_fields_rounded,
      SelectedLayerType.image => Icons.image_outlined,
      SelectedLayerType.shape => Icons.category_outlined,
      SelectedLayerType.background => Icons.wallpaper_outlined,
      SelectedLayerType.none => Icons.tune_rounded,
    };
  }

  Widget _buildToolbarActionButton(
    BuildContext context,
    _ToolbarAction action,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonChild = action.isPrimary
        ? FilledButton.icon(
            onPressed: action.onPressed,
            icon: Icon(action.icon),
            label: Text(action.label),
          )
        : action.isDestructive
        ? OutlinedButton.icon(
            onPressed: action.onPressed,
            icon: Icon(action.icon, color: colorScheme.error),
            label: Text(
              action.label,
              style: TextStyle(color: colorScheme.error),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colorScheme.errorContainer),
            ),
          )
        : FilledButton.tonalIcon(
            onPressed: action.onPressed,
            icon: Icon(action.icon),
            label: Text(action.label),
          );

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: buttonChild,
    );
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
    final contextActions = _buildContextActions(
      context,
      ref,
      canvasNotifier,
      layers,
      selectedLayer,
      selectedType,
    );

    return Scaffold(
      drawer: const LayerListPanel(),
      appBar: AppBar(
        titleSpacing: 8,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_selectionTitle(selectedType)),
            Text(
              _selectionSubtitle(selectedLayer, selectedType),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
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
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: '分享',
            onPressed: () => _shareImage(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.save_alt_outlined),
            tooltip: '导出',
            onPressed: () => _exportImage(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLayerSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('添加'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withAlpha(31),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _selectionIcon(selectedType),
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _selectionTitle(selectedType),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        _selectionSubtitle(selectedLayer, selectedType),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.layers_outlined),
                  label: Text('${layers.length - 1}'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final action in contextActions)
                    _buildToolbarActionButton(context, action),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
