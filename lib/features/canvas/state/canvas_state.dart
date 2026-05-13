import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:BackArt/core/utils/color_utils.dart';
import 'package:BackArt/features/canvas/data/canvas_draft_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/templates.dart';
import '../model/layer.dart';
import 'package:collection/collection.dart';

@immutable
class CanvasState {
  const CanvasState({
    required this.layers,
    this.canvasSize = const Size(1080, 1920),
  });

  final List<Layer> layers;
  final Size canvasSize;

  factory CanvasState.initial() {
    final background = BackgroundLayer.initial();
    final textColor = ColorUtils.getContrastingColor(background.color);

    // 先获取初始的文本图层
    final initialTextLayer = TextLayer.initial();

    // 在原有的style基础上，只修改颜色
    final updatedStyle = initialTextLayer.style.copyWith(color: textColor);

    return CanvasState(
      layers: [
        background,
        initialTextLayer.copyWith(style: updatedStyle),
      ],
    );
  }

  CanvasState copyWith({List<Layer>? layers, Size? canvasSize}) {
    return CanvasState(
      layers: layers ?? this.layers,
      canvasSize: canvasSize ?? this.canvasSize,
    );
  }
}

enum ImageReplacementMode { preserveFrame, fitCanvas, fillCanvas }

class CanvasStateNotifier extends StateNotifier<CanvasState> {
  CanvasStateNotifier({
    CanvasState? initialState,
    Future<void> Function(CanvasState state)? onStateChanged,
  }) : _onStateChanged = onStateChanged,
       super(initialState ?? CanvasState.initial()) {
    state = _normalizeState(state);
    _history.add(state);
    _historyIndex++;
  }

  final Future<void> Function(CanvasState state)? _onStateChanged;
  final List<CanvasState> _history = [];
  int _historyIndex = -1;

  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;

  CanvasState _normalizeState(CanvasState currentState) {
    syncLayerIdCounterWithIds(currentState.layers.map((layer) => layer.id));

    final seenIds = <String>{};
    var didUpdate = false;
    final normalizedLayers = currentState.layers.map((layer) {
      if (seenIds.add(layer.id)) {
        return layer;
      }

      didUpdate = true;
      return layer.copyWith(id: generateLayerId());
    }).toList();

    syncLayerIdCounterWithIds(normalizedLayers.map((layer) => layer.id));
    return didUpdate
        ? currentState.copyWith(layers: normalizedLayers)
        : currentState;
  }

  void _recordState(CanvasState newState) {
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(newState);
    _historyIndex++;
    state = newState;

    if (_history.length > 50) {
      _history.removeAt(0);
      _historyIndex--;
    }
    _persistState();
  }

  void undo() {
    if (canUndo) {
      _historyIndex--;
      state = _history[_historyIndex];
      _persistState();
    }
  }

  void redo() {
    if (canRedo) {
      _historyIndex++;
      state = _history[_historyIndex];
      _persistState();
    }
  }

  void _persistState() {
    final onStateChanged = _onStateChanged;
    if (onStateChanged == null) return;
    unawaited(onStateChanged(state).catchError((_) {}));
  }

  CanvasState _calculateUpdatedState(Layer updatedLayer) {
    final originalLayer = state.layers.firstWhere(
      (l) => l.id == updatedLayer.id,
      // Provide a fallback to avoid crashing if the layer is somehow gone.
      orElse: () => updatedLayer,
    );
    var layerToProcess = updatedLayer;
    final isBackgroundUpdate = updatedLayer is BackgroundLayer;
    Color? newTextColor;

    if (isBackgroundUpdate) {
      final backgroundLayer = updatedLayer;
      final Color contrastColorBase =
          (backgroundLayer.gradient is LinearGradient &&
              (backgroundLayer.gradient as LinearGradient).colors.isNotEmpty)
          ? (backgroundLayer.gradient as LinearGradient).colors.first
          : backgroundLayer.color;
      newTextColor = ColorUtils.getContrastingColor(contrastColorBase);
    }

    if (layerToProcess is TextLayer && originalLayer is TextLayer) {
      bool needsAlignment =
          layerToProcess.alignment != originalLayer.alignment &&
          layerToProcess.alignment != null;
      // This condition now correctly triggers a resize when font properties change.
      bool needsResize =
          layerToProcess.text != originalLayer.text ||
          layerToProcess.style != originalLayer.style;

      if (needsAlignment) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: layerToProcess.text,
            style: layerToProcess.style,
          ),
          textAlign: layerToProcess.textAlign,
          textDirection: TextDirection.ltr,
        )..layout(minWidth: 0, maxWidth: state.canvasSize.width);

        const double margin = 16.0;
        final paddedRect = Rect.fromLTRB(
          margin,
          margin,
          state.canvasSize.width - margin,
          state.canvasSize.height - margin,
        );
        final newRect = layerToProcess.alignment!.inscribe(
          textPainter.size,
          paddedRect,
        );
        layerToProcess = layerToProcess.copyWith(rect: newRect);
      } else if (needsResize) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: layerToProcess.text,
            style: layerToProcess.style,
          ),
          textAlign: layerToProcess.textAlign,
          textDirection: TextDirection.ltr,
        )..layout(minWidth: 0, maxWidth: state.canvasSize.width);

        final newRect = Rect.fromLTWH(
          layerToProcess.rect.left,
          layerToProcess.rect.top,
          textPainter.width,
          textPainter.height,
        );
        layerToProcess = layerToProcess.copyWith(rect: newRect);
      }
    }

    final newLayers = state.layers.map((currentLayer) {
      if (currentLayer.id == updatedLayer.id) {
        return layerToProcess;
      }
      if (isBackgroundUpdate && currentLayer is TextLayer) {
        return currentLayer.copyWith(
          style: currentLayer.style.copyWith(color: newTextColor),
        );
      }
      return currentLayer;
    }).toList();

    return state.copyWith(layers: newLayers);
  }

  void updateLayerLive(Layer updatedLayer) {
    state = _calculateUpdatedState(updatedLayer);
  }

  void commitLiveUpdate() {
    _recordState(state);
  }

  void addLayer(Layer layer) {
    var layerToAdd = layer;
    if (layerToAdd is TextLayer) {
      final textPainter = TextPainter(
        text: TextSpan(text: layerToAdd.text, style: layerToAdd.style),
        textAlign: layerToAdd.textAlign,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: state.canvasSize.width);

      final newRect = Rect.fromLTWH(
        layerToAdd.rect.left,
        layerToAdd.rect.top,
        textPainter.width,
        textPainter.height,
      );
      layerToAdd = layerToAdd.copyWith(rect: newRect);

      if (layerToAdd.style.color == null) {
        final backgroundLayer =
            state.layers.firstWhere((l) => l is BackgroundLayer)
                as BackgroundLayer;
        final textColor = ColorUtils.getContrastingColor(backgroundLayer.color);
        layerToAdd = layerToAdd.copyWith(
          style: layerToAdd.style.copyWith(color: textColor),
        );
      }
    }
    final newLayers = [...state.layers, layerToAdd];
    _recordState(state.copyWith(layers: newLayers));
  }

  void addImageFromImage(ui.Image image) {
    final rect = _layoutImageRect(
      imageSize: Size(image.width.toDouble(), image.height.toDouble()),
      canvasSize: state.canvasSize,
      cover: false,
      maxScale: 1.0,
    );
    final layer = ImageLayer(id: generateLayerId(), image: image, rect: rect);
    _recordState(state.copyWith(layers: [...state.layers, layer]));
  }

  String? duplicateLayer(
    String layerId, {
    Offset offset = const Offset(24, 24),
  }) {
    final originalIndex = state.layers.indexWhere(
      (layer) => layer.id == layerId,
    );
    if (originalIndex == -1) return null;

    final originalLayer = state.layers[originalIndex];
    if (originalLayer is BackgroundLayer) return null;

    final duplicate = _buildDuplicatedLayer(originalLayer, offset);
    final newLayers = [...state.layers]..insert(originalIndex + 1, duplicate);
    _recordState(state.copyWith(layers: newLayers));
    return duplicate.id;
  }

  bool replaceImageLayer(
    String layerId,
    ui.Image image, {
    ImageReplacementMode mode = ImageReplacementMode.preserveFrame,
  }) {
    final imageLayer = state.layers.firstWhereOrNull((layer) {
      return layer.id == layerId && layer is ImageLayer;
    });
    if (imageLayer is! ImageLayer) return false;

    final updatedRect = switch (mode) {
      ImageReplacementMode.preserveFrame => imageLayer.rect,
      ImageReplacementMode.fitCanvas => _layoutImageRect(
        imageSize: Size(image.width.toDouble(), image.height.toDouble()),
        canvasSize: state.canvasSize,
        cover: false,
      ),
      ImageReplacementMode.fillCanvas => _layoutImageRect(
        imageSize: Size(image.width.toDouble(), image.height.toDouble()),
        canvasSize: state.canvasSize,
        cover: true,
      ),
    };

    updateLayer(
      imageLayer.copyWith(
        image: image,
        rect: updatedRect,
        scale: mode == ImageReplacementMode.preserveFrame
            ? imageLayer.scale
            : 1.0,
        alignment: mode == ImageReplacementMode.preserveFrame
            ? imageLayer.alignment
            : null,
        clearAlignment: mode != ImageReplacementMode.preserveFrame,
        cropScale: 1.0,
        cropAlignment: Alignment.center,
      ),
    );
    return true;
  }

  bool fitImageLayerToCanvas(String layerId, {bool cover = false}) {
    final imageLayer = state.layers.firstWhereOrNull((layer) {
      return layer.id == layerId && layer is ImageLayer;
    });
    if (imageLayer is! ImageLayer) return false;

    final updatedRect = _layoutImageRect(
      imageSize: Size(
        imageLayer.image.width.toDouble(),
        imageLayer.image.height.toDouble(),
      ),
      canvasSize: state.canvasSize,
      cover: cover,
    );

    updateLayer(
      imageLayer.copyWith(
        rect: updatedRect,
        scale: 1.0,
        alignment: null,
        clearAlignment: true,
        cropScale: 1.0,
        cropAlignment: Alignment.center,
      ),
    );
    return true;
  }

  bool resetImageLayerToIntrinsicSize(String layerId) {
    final imageLayer = state.layers.firstWhereOrNull((layer) {
      return layer.id == layerId && layer is ImageLayer;
    });
    if (imageLayer is! ImageLayer) return false;

    final currentCenter = imageLayer.rect.center;
    final intrinsicRect = Rect.fromCenter(
      center: currentCenter,
      width: imageLayer.image.width.toDouble(),
      height: imageLayer.image.height.toDouble(),
    );

    updateLayer(
      imageLayer.copyWith(
        rect: intrinsicRect,
        scale: 1.0,
        alignment: null,
        clearAlignment: true,
        cropScale: 1.0,
        cropAlignment: Alignment.center,
      ),
    );
    return true;
  }

  Layer _buildDuplicatedLayer(Layer layer, Offset offset) {
    final newRect = layer.rect.translate(offset.dx, offset.dy);
    final newId = generateLayerId();

    return switch (layer) {
      TextLayer() => layer.copyWith(id: newId, rect: newRect),
      ImageLayer() => layer.copyWith(id: newId, rect: newRect),
      ShapeLayer() => layer.copyWith(id: newId, rect: newRect),
      BackgroundLayer() => layer,
      _ => layer,
    };
  }

  void removeLayer(String layerId) {
    final newLayers = state.layers
        .where((layer) => layer.id != layerId)
        .toList();
    _recordState(state.copyWith(layers: newLayers));
  }

  void updateLayer(Layer updatedLayer) {
    final newState = _calculateUpdatedState(updatedLayer);
    _recordState(newState);
  }

  void setCanvasSize(Size newSize) {
    final oldSize = state.canvasSize;
    if (oldSize == newSize) return;

    final scaleX = newSize.width / oldSize.width;
    final scaleY = newSize.height / oldSize.height;

    final newLayers = state.layers.map((layer) {
      // 背景层不进行缩放
      if (layer is BackgroundLayer) return layer;

      final oldRect = layer.rect;
      final newRect = Rect.fromLTWH(
        oldRect.left * scaleX,
        oldRect.top * scaleY,
        oldRect.width * scaleX,
        oldRect.height * scaleY,
      );
      // 同时按比例缩放图层本身的 scale 属性
      final newLayerScale = layer.scale * (scaleX + scaleY) / 2.0;

      return layer.copyWith(rect: newRect, scale: newLayerScale);
    }).toList();
    _recordState(state.copyWith(canvasSize: newSize, layers: newLayers));
  }

  void reorderLayer(int oldIndex, int newIndex) {
    final editableLayers = state.layers
        .where((layer) => layer is! BackgroundLayer)
        .toList();
    if (oldIndex < 0 ||
        oldIndex >= editableLayers.length ||
        newIndex < 0 ||
        newIndex > editableLayers.length) {
      return;
    }

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final layer = editableLayers.removeAt(oldIndex);
    editableLayers.insert(newIndex, layer);

    _recordState(
      state.copyWith(
        layers: [
          state.layers.firstWhere((layer) => layer is BackgroundLayer),
          ...editableLayers,
        ],
      ),
    );
  }

  void reorderLayersTopToBottom(List<String> orderedLayerIds) {
    final backgroundLayer = state.layers.firstWhereOrNull(
      (layer) => layer is BackgroundLayer,
    );
    if (backgroundLayer == null) return;

    final editableLayers = state.layers
        .where((layer) => layer is! BackgroundLayer)
        .toList();
    if (orderedLayerIds.length != editableLayers.length) return;

    final layersById = {for (final layer in editableLayers) layer.id: layer};
    final reorderedEditableLayers = <Layer>[];
    for (final id in orderedLayerIds) {
      final layer = layersById[id];
      if (layer == null) return;
      reorderedEditableLayers.add(layer);
    }

    _recordState(
      state.copyWith(
        layers: [backgroundLayer, ...reorderedEditableLayers.reversed],
      ),
    );
  }

  /// 对齐图层的方法**
  void alignLayer(String layerId, Alignment alignment) {
    final Layer? layer = state.layers.firstWhereOrNull((l) => l.id == layerId);
    if (layer == null || layer is BackgroundLayer) return;

    // 定义画布的安全区域（带一点边距）
    const double margin = 16.0;
    final canvasRect = Rect.fromLTRB(
      margin,
      margin,
      state.canvasSize.width - margin,
      state.canvasSize.height - margin,
    );

    // 使用 Alignment.inscribe 计算图层在画布中的新位置
    final newRect = alignment.inscribe(layer.rect.size, canvasRect);

    // 创建一个更新了位置的新图层
    final updatedLayer = layer.copyWith(rect: newRect);

    // 更新状态并记录历史
    updateLayer(updatedLayer);
  }

  /// 仅在水平方向上对齐图层
  void alignLayerHorizontally(String layerId, Alignment alignment) {
    final Layer? layer = state.layers.firstWhereOrNull((l) => l.id == layerId);
    if (layer == null || layer is BackgroundLayer) return;

    const double margin = 16.0;
    // 创建一个仅限制水平方向的对齐区域
    final targetRect = Rect.fromLTWH(
      margin,
      layer.rect.top, // 保持图层当前的垂直位置
      state.canvasSize.width - (margin * 2),
      layer.rect.height,
    );

    final newRect = alignment.inscribe(layer.rect.size, targetRect);
    updateLayer(layer.copyWith(rect: newRect));
  }

  /// 仅在垂直方向上对齐图层
  void alignLayerVertically(String layerId, Alignment alignment) {
    final Layer? layer = state.layers.firstWhereOrNull((l) => l.id == layerId);
    if (layer == null || layer is BackgroundLayer) return;

    const double margin = 16.0;
    // 创建一个仅限制垂直方向的对齐区域
    final targetRect = Rect.fromLTWH(
      layer.rect.left, // 保持图层当前的水平位置
      margin,
      layer.rect.width,
      state.canvasSize.height - (margin * 2),
    );

    final newRect = alignment.inscribe(layer.rect.size, targetRect);
    updateLayer(layer.copyWith(rect: newRect));
  }

  void toggleLayerVisibility(String layerId) {
    final newLayers = state.layers.map((layer) {
      if (layer.id == layerId) {
        return layer.copyWith(isVisible: !layer.isVisible);
      }
      return layer;
    }).toList();
    _recordState(state.copyWith(layers: newLayers));
  }

  void toggleLayerLock(String layerId) {
    final newLayers = state.layers.map((layer) {
      if (layer.id == layerId) {
        return layer.copyWith(isLocked: !layer.isLocked);
      }
      return layer;
    }).toList();
    _recordState(state.copyWith(layers: newLayers));
  }

  void commitTransform(String layerId) {
    var layer = state.layers.firstWhereOrNull((l) => l.id == layerId);
    if (layer == null) {
      commitLiveUpdate(); // 如果找不到图层，则按原逻辑提交
      return;
    }

    final canvasRect = Rect.fromLTWH(
      0,
      0,
      state.canvasSize.width,
      state.canvasSize.height,
    );
    final layerCenter = layer.rect.center;

    // 计算需要将中心点移回画布所需的偏移量
    final double dx = (layerCenter.dx < canvasRect.left)
        ? canvasRect.left - layerCenter.dx
        : (layerCenter.dx > canvasRect.right)
        ? canvasRect.right - layerCenter.dx
        : 0;

    final double dy = (layerCenter.dy < canvasRect.top)
        ? canvasRect.top - layerCenter.dy
        : (layerCenter.dy > canvasRect.bottom)
        ? canvasRect.bottom - layerCenter.dy
        : 0;

    // 如果需要修正位置
    if (dx != 0 || dy != 0) {
      final correctedRect = layer.rect.translate(dx, dy);
      layer = layer.copyWith(rect: correctedRect);
    }

    // 使用修正后的图层更新状态并记录历史
    updateLayer(layer);
  }

  void applyTemplate(Template template) {
    // 创建新的图层列表，包含模板的背景和内容图层
    final newLayers = [
      template.background,
      ...template.contentLayers.where((layer) => layer is! BackgroundLayer),
    ];

    _recordState(state.copyWith(layers: newLayers));
  }
}

final initialCanvasStateProvider = Provider<CanvasState?>((ref) => null);

final canvasDraftRepositoryProvider = Provider<CanvasDraftRepository?>(
  (ref) => null,
);

Rect _layoutImageRect({
  required Size imageSize,
  required Size canvasSize,
  required bool cover,
  double maxScale = double.infinity,
}) {
  final widthScale = canvasSize.width / imageSize.width;
  final heightScale = canvasSize.height / imageSize.height;
  final fittedScale =
      (cover ? max(widthScale, heightScale) : min(widthScale, heightScale))
          .clamp(0.0, maxScale);

  return Rect.fromCenter(
    center: canvasSize.center(Offset.zero),
    width: imageSize.width * fittedScale,
    height: imageSize.height * fittedScale,
  );
}

final canvasStateProvider =
    StateNotifierProvider<CanvasStateNotifier, CanvasState>((ref) {
      final draftRepository = ref.watch(canvasDraftRepositoryProvider);
      return CanvasStateNotifier(
        initialState: ref.watch(initialCanvasStateProvider),
        onStateChanged: draftRepository?.save,
      );
    });
