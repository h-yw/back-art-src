import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../editor/widgets/text_editor_panel.dart';
import '../../editor/state/editor_state.dart';
import '../model/layer.dart';
import '../state/canvas_state.dart';
import 'dart:math';
import 'package:collection/collection.dart';

const double kHandleRadius = 6.0;
const double kHandleTapTargetRadius = 20.0;
const Duration kTextDoubleTapThreshold = Duration(milliseconds: 280);
const double kDoubleTapSlop = 24.0;
const double kSnapThresholdInScreenPixels = 10.0;
const double kSnapScaleTolerance = 0.03;
const double kSnapRotationTolerance = 0.03;

enum SnapGuideAxis { horizontal, vertical }

class SnapGuide {
  const SnapGuide({required this.axis, required this.coordinate});

  final SnapGuideAxis axis;
  final double coordinate;
}

class SnapResult {
  const SnapResult({required this.rect, required this.guides});

  final Rect rect;
  final List<SnapGuide> guides;
}

@visibleForTesting
SnapResult applySnapToRect(
  Rect tentativeRect,
  Layer currentLayer,
  List<Layer> layers,
  Size canvasSize,
  double canvasScale,
) {
  final threshold = kSnapThresholdInScreenPixels / canvasScale;
  final canvasXTargets = [0.0, canvasSize.width / 2, canvasSize.width];
  final canvasYTargets = [0.0, canvasSize.height / 2, canvasSize.height];
  final otherLayers = layers.where((layer) {
    return layer.id != currentLayer.id &&
        layer is! BackgroundLayer &&
        layer.isVisible;
  });

  final xTargets = [
    ...canvasXTargets,
    for (final layer in otherLayers) ...[
      layer.rect.left,
      layer.rect.center.dx,
      layer.rect.right,
    ],
  ];
  final yTargets = [
    ...canvasYTargets,
    for (final layer in otherLayers) ...[
      layer.rect.top,
      layer.rect.center.dy,
      layer.rect.bottom,
    ],
  ];

  final sourceXs = [
    tentativeRect.left,
    tentativeRect.center.dx,
    tentativeRect.right,
  ];
  final sourceYs = [
    tentativeRect.top,
    tentativeRect.center.dy,
    tentativeRect.bottom,
  ];

  double? dx;
  double? snappedX;
  for (final source in sourceXs) {
    for (final target in xTargets) {
      final delta = target - source;
      if (delta.abs() > threshold) continue;
      if (dx == null || delta.abs() < dx.abs()) {
        dx = delta;
        snappedX = target;
      }
    }
  }

  double? dy;
  double? snappedY;
  for (final source in sourceYs) {
    for (final target in yTargets) {
      final delta = target - source;
      if (delta.abs() > threshold) continue;
      if (dy == null || delta.abs() < dy.abs()) {
        dy = delta;
        snappedY = target;
      }
    }
  }

  final snappedRect = tentativeRect.shift(Offset(dx ?? 0, dy ?? 0));
  final guides = <SnapGuide>[
    if (snappedX != null)
      SnapGuide(axis: SnapGuideAxis.vertical, coordinate: snappedX),
    if (snappedY != null)
      SnapGuide(axis: SnapGuideAxis.horizontal, coordinate: snappedY),
  ];
  return SnapResult(rect: snappedRect, guides: guides);
}

@visibleForTesting
bool shouldSnapForTransform({
  required double scaleDelta,
  required double rotationDelta,
}) {
  return (scaleDelta - 1.0).abs() <= kSnapScaleTolerance &&
      rotationDelta.abs() <= kSnapRotationTolerance;
}

class CanvasView extends ConsumerStatefulWidget {
  const CanvasView({Key? key, required this.canvasDisplaySize})
    : super(key: key);
  final Size canvasDisplaySize;
  @override
  ConsumerState<CanvasView> createState() => _CanvasViewState();
}

class _CanvasViewState extends ConsumerState<CanvasView> {
  Layer? _initialLayerState;
  Offset? _initialFocalPoint;
  DateTime? _lastTapAt;
  Offset? _lastTapLocalPosition;
  String? _lastTappedTextLayerId;
  List<SnapGuide> _activeSnapGuides = const [];

  @override
  Widget build(BuildContext context) {
    final canvasState = ref.watch(canvasStateProvider);
    final selectedLayerId = ref.watch(selectedLayerProvider);
    final canvasNotifier = ref.read(canvasStateProvider.notifier);
    final canvasDisplaySize = widget.canvasDisplaySize;
    final double scale = canvasDisplaySize.width / canvasState.canvasSize.width;
    return GestureDetector(
      onTapUp: (details) {
        final tapLocalPosition = details.localPosition;
        final tapPosition = tapLocalPosition / scale;
        final selectedLayer = canvasState.layers.firstWhereOrNull(
          (layer) => layer.id == selectedLayerId,
        );
        if (_isTapOnDeleteHandle(selectedLayer, tapPosition, scale)) {
          canvasNotifier.removeLayer(selectedLayer!.id);
          ref.read(selectedLayerProvider.notifier).state = nextEditableLayerId(
            canvasState.layers,
            currentLayerId: selectedLayer.id,
          );
          _clearTapTracking();
          return;
        }

        final currentSelectedId = ref.read(selectedLayerProvider);
        final tappedLayer = _findTopmostEditableLayer(
          canvasState.layers,
          tapPosition,
        );
        if (_isTextLayerDoubleTap(tappedLayer, tapLocalPosition)) {
          final tappedTextLayer = tappedLayer as TextLayer;
          ref.read(selectedLayerProvider.notifier).state = tappedTextLayer.id;
          _clearTapTracking();
          showModalBottomSheet<void>(
            context: context,
            builder: (context) => const TextEditorPanel(),
          );
          return;
        }

        if (tappedLayer != null) {
          if (tappedLayer.id == currentSelectedId) {
            ref.read(selectedLayerProvider.notifier).state = null;
          } else {
            ref.read(selectedLayerProvider.notifier).state = tappedLayer.id;
          }
        } else {
          ref.read(selectedLayerProvider.notifier).state = null;
        }
        _trackTap(tappedLayer, tapLocalPosition);
      },
      onScaleStart: (details) {
        final selectedId = ref.read(selectedLayerProvider);
        if (selectedId != null) {
          final layer = canvasState.layers.firstWhere(
            (l) => l.id == selectedId,
          );
          if (layer.isLocked) {
            _initialLayerState = null;
            _initialFocalPoint = null;
            _activeSnapGuides = const [];
            return;
          }
          _initialLayerState = canvasState.layers.firstWhere(
            (l) => l.id == selectedId,
          );
          _initialFocalPoint = details.localFocalPoint;
        }
      },
      onScaleUpdate: (details) {
        final selectedId = ref.read(selectedLayerProvider);
        final currentLayer = canvasState.layers.firstWhereOrNull(
          (l) => l.id == selectedId,
        );
        if (currentLayer == null ||
            _initialLayerState == null ||
            _initialFocalPoint == null)
          return;
        if (currentLayer is BackgroundLayer) return;
        final newScale = _initialLayerState!.scale * details.scale;
        final newRotation = _initialLayerState!.rotation + details.rotation;
        final initialFocalPointInCanvas = _initialFocalPoint! / scale;
        final totalTranslationInCanvas =
            (details.localFocalPoint - _initialFocalPoint!) / scale;
        final initialCenter = _initialLayerState!.rect.center;
        final initialVector = initialCenter - initialFocalPointInCanvas;
        final r = details.rotation;
        final rotatedVector = Offset(
          initialVector.dx * cos(r) - initialVector.dy * sin(r),
          initialVector.dx * sin(r) + initialVector.dy * cos(r),
        );
        final scaledRotatedVector = rotatedVector * details.scale;
        final finalNewCenter =
            initialFocalPointInCanvas +
            scaledRotatedVector +
            totalTranslationInCanvas;
        final newRect = Rect.fromCenter(
          center: finalNewCenter,
          width: _initialLayerState!.rect.width,
          height: _initialLayerState!.rect.height,
        );
        final shouldSnap = shouldSnapForTransform(
          scaleDelta: details.scale,
          rotationDelta: details.rotation,
        );
        final snapResult = shouldSnap
            ? applySnapToRect(
                newRect,
                currentLayer,
                canvasState.layers,
                canvasState.canvasSize,
                scale,
              )
            : SnapResult(rect: newRect, guides: const []);
        final updatedLayer = currentLayer.copyWith(
          rect: snapResult.rect,
          scale: newScale,
          rotation: newRotation,
        );
        if (!_areSnapGuidesEqual(_activeSnapGuides, snapResult.guides)) {
          setState(() {
            _activeSnapGuides = snapResult.guides;
          });
        }
        canvasNotifier.updateLayerLive(updatedLayer);
      },
      onScaleEnd: (details) {
        final selectedId = ref.read(selectedLayerProvider);
        if (selectedId != null && _initialLayerState != null) {
          canvasNotifier.commitTransform(selectedId);
        }
        setState(() {
          _initialLayerState = null;
          _initialFocalPoint = null;
          _activeSnapGuides = const [];
        });
      },
      child: CustomPaint(
        size: canvasDisplaySize,
        painter: CanvasPainter(
          canvasState: canvasState,
          selectedLayerId: selectedLayerId,
          snapGuides: _activeSnapGuides,
        ),
      ),
    );
  }

  Layer? _findTopmostEditableLayer(List<Layer> layers, Offset tapPosition) {
    return layers.lastWhereOrNull((layer) {
      if (layer is BackgroundLayer || !layer.isVisible || layer.isLocked) {
        return false;
      }
      return _isTapOnLayer(layer, tapPosition);
    });
  }

  bool _isTextLayerDoubleTap(Layer? tappedLayer, Offset tapLocalPosition) {
    if (tappedLayer is! TextLayer || tappedLayer.isLocked) {
      return false;
    }

    final lastTapAt = _lastTapAt;
    final lastTapLocalPosition = _lastTapLocalPosition;
    if (lastTapAt == null || lastTapLocalPosition == null) {
      return false;
    }

    final isWithinTimeout =
        DateTime.now().difference(lastTapAt) <= kTextDoubleTapThreshold;
    final isSameLayer = _lastTappedTextLayerId == tappedLayer.id;
    final isWithinDistance =
        (tapLocalPosition - lastTapLocalPosition).distance <= kDoubleTapSlop;
    return isWithinTimeout && isSameLayer && isWithinDistance;
  }

  void _trackTap(Layer? tappedLayer, Offset tapLocalPosition) {
    if (tappedLayer is TextLayer && !tappedLayer.isLocked) {
      _lastTapAt = DateTime.now();
      _lastTapLocalPosition = tapLocalPosition;
      _lastTappedTextLayerId = tappedLayer.id;
      return;
    }
    _clearTapTracking();
  }

  void _clearTapTracking() {
    _lastTapAt = null;
    _lastTapLocalPosition = null;
    _lastTappedTextLayerId = null;
  }

  bool _areSnapGuidesEqual(List<SnapGuide> a, List<SnapGuide> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index].axis != b[index].axis) return false;
      if ((a[index].coordinate - b[index].coordinate).abs() > 0.001) {
        return false;
      }
    }
    return true;
  }

  bool _isTapOnDeleteHandle(
    Layer? layer,
    Offset tapPosition,
    double canvasScale,
  ) {
    if (layer == null ||
        layer is BackgroundLayer ||
        !layer.isVisible ||
        layer.isLocked) {
      return false;
    }

    final transformedTapPosition = _transformToLayerSpace(layer, tapPosition);
    final handleRadiusInLayerSpace =
        kHandleTapTargetRadius / (canvasScale * layer.scale);
    return (transformedTapPosition - layer.rect.topLeft).distance <=
        handleRadiusInLayerSpace;
  }

  Offset _transformToLayerSpace(Layer layer, Offset tapPosition) {
    final transform = Matrix4.identity()
      ..translate(layer.rect.center.dx, layer.rect.center.dy)
      ..rotateZ(layer.rotation)
      ..scale(layer.scale)
      ..translate(-layer.rect.center.dx, -layer.rect.center.dy);

    final invTransform = Matrix4.inverted(transform);
    return MatrixUtils.transformPoint(invTransform, tapPosition);
  }

  bool _isTapOnLayer(Layer layer, Offset tapPosition) {
    final transformedTapPosition = _transformToLayerSpace(layer, tapPosition);
    return layer.rect.contains(transformedTapPosition);
  }
}

class CanvasPainter extends CustomPainter {
  const CanvasPainter({
    required this.canvasState,
    this.selectedLayerId,
    this.snapGuides = const [],
  });

  final CanvasState canvasState;
  final String? selectedLayerId;
  final List<SnapGuide> snapGuides;

  static const double _highlightStrokeWidth = 2.0;
  static const double _handleStrokeWidth = 1.5;
  static const double _handleRadius = 6.0;
  static const Color _highlightColor = Colors.blue;
  static const Color _handleColor = Colors.white;

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / canvasState.canvasSize.width;
    canvas.scale(scale);

    for (final layer in canvasState.layers) {
      if (layer.isVisible) {
        _paintLayer(canvas, layer);
      }
    }

    _paintSnapGuides(canvas);

    final selectedLayer = canvasState.layers.firstWhereOrNull(
      (l) => l.id == selectedLayerId,
    );
    if (selectedLayer != null && selectedLayer is! BackgroundLayer) {
      _highlightLayer(canvas, selectedLayer, scale);
    }
  }

  void _paintLayer(Canvas canvas, Layer layer) {
    canvas.save();
    canvas.translate(layer.rect.center.dx, layer.rect.center.dy);
    canvas.rotate(layer.rotation);
    canvas.scale(layer.scale);
    canvas.translate(-layer.rect.center.dx, -layer.rect.center.dy);

    if (layer is BackgroundLayer) {
      _paintBackgroundLayer(canvas, layer);
    } else if (layer is TextLayer) {
      _paintTextLayer(canvas, layer);
    } else if (layer is ImageLayer) {
      _paintImageLayer(canvas, layer);
    } else if (layer is ShapeLayer) {
      // **添加缺失的判断和绘制调用**
      _paintShapeLayer(canvas, layer);
    }

    canvas.restore();
  }

  void _paintBackgroundLayer(Canvas canvas, BackgroundLayer layer) {
    final paint = Paint();
    if (layer.gradient != null) {
      paint.shader = layer.gradient!.createShader(
        Rect.fromLTWH(
          0,
          0,
          canvasState.canvasSize.width,
          canvasState.canvasSize.height,
        ),
      );
    } else {
      paint.color = layer.color;
    }
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        canvasState.canvasSize.width,
        canvasState.canvasSize.height,
      ),
      paint,
    );
  }

  void _paintTextLayer(Canvas canvas, TextLayer layer) {
    // 创建 TextPainter 用于布局和绘制
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: layer.textAlign,
    );

    const double margin = 16.0;
    final maxWidth = canvasState.canvasSize.width - layer.rect.left - margin;

    // 检查是否启用了描边
    if (layer.hasStroke && layer.strokeWidth > 0) {
      // --- 绘制描边层 ---
      // 创建一个用于描边的Paint
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = layer.strokeWidth
        ..color = layer.strokeColor;

      // 创建带有描边样式的TextSpan
      final strokeTextSpan = TextSpan(
        text: layer.text,
        style: layer.style.copyWith(
          foreground: strokePaint,
          // 关键：将填充色设为透明，避免遮挡描边
          color: null,
        ),
      );

      textPainter.text = strokeTextSpan;
      textPainter.layout(
        minWidth: 0,
        maxWidth: maxWidth > 0 ? maxWidth : double.infinity,
      );
      textPainter.paint(canvas, layer.rect.topLeft);
    }

    // --- 绘制填充层 ---
    // 总是绘制填充层，这样即使描边开启，文字中心也是有颜色的
    final textSpan = TextSpan(text: layer.text, style: layer.style);
    textPainter.text = textSpan;
    textPainter.layout(
      minWidth: 0,
      maxWidth: maxWidth > 0 ? maxWidth : double.infinity,
    );
    textPainter.paint(canvas, layer.rect.topLeft);
  }

  void _paintImageLayer(Canvas canvas, ImageLayer layer) {
    Rect targetRect = layer.rect;
    if (layer.alignment != null) {
      final canvasRect = Rect.fromLTWH(
        0,
        0,
        canvasState.canvasSize.width,
        canvasState.canvasSize.height,
      );
      targetRect = layer.alignment!.inscribe(layer.rect.size, canvasRect);
    }

    canvas.drawImageRect(
      layer.image,
      Rect.fromLTWH(
        0,
        0,
        layer.image.width.toDouble(),
        layer.image.height.toDouble(),
      ),
      targetRect,
      Paint()
        ..color = Colors.white.withValues(alpha: layer.opacity)
        ..filterQuality = FilterQuality.high
        ..blendMode = BlendMode.modulate,
    );
  }

  void _paintShapeLayer(Canvas canvas, ShapeLayer layer) {
    final paint = Paint()
      ..color = layer.color.withValues(alpha: layer.opacity)
      ..style = layer.paintStyle;

    if (layer.paintStyle == PaintingStyle.stroke) {
      // 描边宽度应该不受图层缩放影响，所以除以scale
      paint.strokeWidth = (layer.strokeWidth ?? 2.0) / layer.scale;
    }

    // 根据 shapeType 绘制不同的形状
    switch (layer.shapeType) {
      case ShapeType.rectangle:
        canvas.drawRect(layer.rect, paint);
        break;
      case ShapeType.circle:
        // 对于圆形，我们使用 rect 的中心点和其较短边的半径来绘制
        final center = layer.rect.center;
        final radius = layer.rect.shortestSide / 2;
        canvas.drawCircle(center, radius, paint);
        break;
    }
  }

  void _paintSnapGuides(Canvas canvas) {
    if (snapGuides.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final guide in snapGuides) {
      switch (guide.axis) {
        case SnapGuideAxis.horizontal:
          canvas.drawLine(
            Offset(0, guide.coordinate),
            Offset(canvasState.canvasSize.width, guide.coordinate),
            paint,
          );
          break;
        case SnapGuideAxis.vertical:
          canvas.drawLine(
            Offset(guide.coordinate, 0),
            Offset(guide.coordinate, canvasState.canvasSize.height),
            paint,
          );
          break;
      }
    }
  }

  void _highlightLayer(Canvas canvas, Layer layer, double scaleFactor) {
    if (layer is BackgroundLayer) return;

    canvas.save();
    canvas.translate(layer.rect.center.dx, layer.rect.center.dy);
    canvas.rotate(layer.rotation);
    canvas.scale(layer.scale);
    canvas.translate(-layer.rect.center.dx, -layer.rect.center.dy);

    // 计算有效的缩放因子，用于动态调整边框和手柄的大小，使其在视觉上保持一致
    final double effectiveScale = scaleFactor * layer.scale;

    final paint = Paint()
      ..color = _highlightColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _highlightStrokeWidth / effectiveScale;

    canvas.drawRect(layer.rect, paint);

    final handlePaint = Paint()..color = _handleColor;
    final handlePaintStroke = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = _handleStrokeWidth / effectiveScale;

    final handleRadius = _handleRadius / effectiveScale;

    final corners = [
      layer.rect.topLeft,
      layer.rect.topRight,
      layer.rect.bottomLeft,
      layer.rect.bottomRight,
    ];

    for (final corner in corners) {
      canvas.drawCircle(corner, handleRadius, handlePaint);
      canvas.drawCircle(corner, handleRadius, handlePaintStroke);
    }

    // --- 绘制左上角的删除按钮 ---
    final deleteHandleCenter = layer.rect.topLeft;
    final deleteHandlePaint = Paint()..color = Colors.red;

    // 绘制红色圆形背景
    canvas.drawCircle(deleteHandleCenter, handleRadius, deleteHandlePaint);

    // 在圆形内部绘制一个白色的 "X" 图标
    final crossPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = _handleStrokeWidth / effectiveScale
      ..style = PaintingStyle.stroke;

    final crossOffset = handleRadius * 0.5; // "X" 的大小是手柄半径的一半
    canvas.drawLine(
      deleteHandleCenter.translate(-crossOffset, -crossOffset),
      deleteHandleCenter.translate(crossOffset, crossOffset),
      crossPaint,
    );
    canvas.drawLine(
      deleteHandleCenter.translate(-crossOffset, crossOffset),
      deleteHandleCenter.translate(crossOffset, -crossOffset),
      crossPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return oldDelegate.canvasState != canvasState ||
        oldDelegate.selectedLayerId != selectedLayerId;
  }
}
