import 'dart:math';
import 'dart:typed_data';

import 'package:BackArt/features/canvas/model/layer.dart';
import 'package:BackArt/features/canvas/state/canvas_state.dart';
import 'package:BackArt/features/canvas/view/canvas_view.dart';
import 'package:BackArt/features/editor/state/editor_state.dart';
import 'package:BackArt/features/editor/widgets/alignment_panel.dart';
import 'package:BackArt/features/editor/widgets/color_editor_panel.dart';
import 'package:BackArt/features/editor/widgets/image_editor_panel.dart';
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

enum _PublishAction { save, share }

class _PublishPreset {
  const _PublishPreset({
    required this.title,
    required this.subtitle,
    required this.pixelRatio,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final double pixelRatio;
  final IconData icon;
}

class _PublishRequest {
  const _PublishRequest({required this.action, required this.preset});

  final _PublishAction action;
  final _PublishPreset preset;
}

class EditorScreen extends ConsumerWidget {
  EditorScreen({Key? key}) : super(key: key);

  // A GlobalKey is needed to access the RepaintBoundary
  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const List<_PublishPreset> _publishPresets = [
    _PublishPreset(
      title: '快速分享',
      subtitle: '1.5x · 速度更快，适合聊天和预览',
      pixelRatio: 1.5,
      icon: Icons.flash_on_outlined,
    ),
    _PublishPreset(
      title: '高清',
      subtitle: '3x · 质量和速度更均衡',
      pixelRatio: 3.0,
      icon: Icons.high_quality_outlined,
    ),
    _PublishPreset(
      title: '打印级',
      subtitle: '5x · 适合海报和高分辨率屏幕',
      pixelRatio: 5.0,
      icon: Icons.workspace_premium_outlined,
    ),
  ];

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

  Future<Uint8List?> _captureCanvasWithoutSelection(
    WidgetRef ref, {
    required double pixelRatio,
  }) async {
    final originalSelectedId = ref.read(selectedLayerProvider);
    ref.read(selectedLayerProvider.notifier).state = null;

    try {
      await Future.delayed(const Duration(milliseconds: 50));
      final service = ExportService();
      return await service.captureCanvasPng(_canvasKey, pixelRatio: pixelRatio);
    } finally {
      ref.read(selectedLayerProvider.notifier).state = originalSelectedId;
    }
  }

  Future<void> _publishCanvas(BuildContext context, WidgetRef ref) async {
    final request = await _showPublishSheet(context, ref);
    if (request == null || !context.mounted) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          const Center(child: CircularProgressIndicator()),
    );

    final bytes = await _captureCanvasWithoutSelection(
      ref,
      pixelRatio: request.preset.pixelRatio,
    );

    if (context.mounted) {
      Navigator.of(context).pop();
    }

    if (!context.mounted) {
      return;
    }

    if (bytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('导出失败，请重试。')));
      return;
    }

    final service = ExportService();
    final success = switch (request.action) {
      _PublishAction.save => await service.savePngBytes(bytes),
      _PublishAction.share => await service.sharePngBytes(bytes),
    };

    if (!context.mounted) {
      return;
    }

    final message = switch (request.action) {
      _PublishAction.save => success ? '已保存到相册。' : '保存失败，请重试。',
      _PublishAction.share => success ? '已打开分享面板。' : '分享失败，请重试。',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<_PublishRequest?> _showPublishSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final canvasSize = ref.read(
      canvasStateProvider.select((state) => state.canvasSize),
    );
    return showModalBottomSheet<_PublishRequest>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        var selectedPreset = _publishPresets[1];
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: FractionallySizedBox(
                heightFactor: 0.8,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '发布画布',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '当前尺寸 ${canvasSize.width.round()} x ${canvasSize.height.round()}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final preset in _publishPresets)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () => setState(
                                        () => selectedPreset = preset,
                                      ),
                                      child: Ink(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: preset == selectedPreset
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                : Theme.of(
                                                    context,
                                                  ).colorScheme.outlineVariant,
                                            width: preset == selectedPreset
                                                ? 2
                                                : 1,
                                          ),
                                          color: preset == selectedPreset
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primaryContainer
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.surface,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondaryContainer,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Icon(preset.icon),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      preset.title,
                                                      style: Theme.of(
                                                        context,
                                                      ).textTheme.titleMedium,
                                                    ),
                                                    Text(
                                                      preset.subtitle,
                                                      style: Theme.of(
                                                        context,
                                                      ).textTheme.bodySmall,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Radio<_PublishPreset>(
                                                value: preset,
                                                groupValue: selectedPreset,
                                                onChanged: (_) => setState(
                                                  () => selectedPreset = preset,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).pop(
                                _PublishRequest(
                                  action: _PublishAction.share,
                                  preset: selectedPreset,
                                ),
                              ),
                              icon: const Icon(Icons.ios_share_rounded),
                              label: const Text('分享'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => Navigator.of(context).pop(
                                _PublishRequest(
                                  action: _PublishAction.save,
                                  preset: selectedPreset,
                                ),
                              ),
                              icon: const Icon(Icons.save_alt_outlined),
                              label: const Text('保存到相册'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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

  void _showImageEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const ImageEditorPanel(),
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
        actions.add(
          _ToolbarAction(
            icon: Icons.tune_rounded,
            label: '图片',
            onPressed: () => _showImageEditor(context),
            isPrimary: true,
          ),
        );
        break;
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

  Future<void> _showToolbarActionsSheet(
    BuildContext context,
    List<_ToolbarAction> actions,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final action in actions)
              ListTile(
                leading: Icon(
                  action.icon,
                  color: action.isDestructive
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
                title: Text(
                  action.label,
                  style: action.isDestructive
                      ? TextStyle(color: Theme.of(context).colorScheme.error)
                      : null,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  action.onPressed();
                },
              ),
          ],
        ),
      ),
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
    final primaryAction =
        contextActions.firstWhereOrNull((action) => action.isPrimary) ??
        contextActions.firstOrNull;
    final secondaryActions = contextActions
        .where((action) => action != primaryAction)
        .toList();
    final quickAction = secondaryActions.firstWhereOrNull(
      (action) => !action.isDestructive,
    );
    final overflowActions = secondaryActions
        .where((action) => action != quickAction)
        .toList();
    final shouldShowMore = overflowActions.isNotEmpty;

    return Scaffold(
      key: _scaffoldKey,
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
          FilledButton.tonalIcon(
            onPressed: () => _publishCanvas(context, ref),
            icon: const Icon(Icons.publish_outlined),
            label: const Text('发布'),
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
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  icon: const Icon(Icons.layers_outlined),
                  label: Text('${layers.length - 1}'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (primaryAction != null)
                  Expanded(
                    child: primaryAction.isPrimary
                        ? FilledButton.icon(
                            onPressed: primaryAction.onPressed,
                            icon: Icon(primaryAction.icon),
                            label: Text(primaryAction.label),
                          )
                        : FilledButton.tonalIcon(
                            onPressed: primaryAction.onPressed,
                            icon: Icon(primaryAction.icon),
                            label: Text(primaryAction.label),
                          ),
                  ),
                if (primaryAction != null &&
                    (quickAction != null || shouldShowMore))
                  const SizedBox(width: 8),
                if (quickAction != null)
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: quickAction.onPressed,
                      icon: Icon(quickAction.icon),
                      label: Text(quickAction.label),
                    ),
                  ),
                if (quickAction != null && shouldShowMore)
                  const SizedBox(width: 8),
                if (shouldShowMore)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showToolbarActionsSheet(context, overflowActions),
                      icon: const Icon(Icons.more_horiz_rounded),
                      label: const Text('更多'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
