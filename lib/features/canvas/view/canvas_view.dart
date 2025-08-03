import 'package:BackArt/features/editor/widgets/text_editor_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../editor/view/editor_screen.dart';
import '../model/layer.dart';
import '../state/canvas_state.dart';
import 'dart:math';
import 'package:collection/collection.dart';

const double kHandleRadius = 6.0;

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

  @override
  Widget build(BuildContext context) {
    final canvasState = ref.watch(canvasStateProvider);
    final selectedLayerId = ref.watch(selectedLayerProvider);
    final canvasNotifier = ref.read(canvasStateProvider.notifier);
    final canvasDisplaySize = widget.canvasDisplaySize;
    final double scale = canvasDisplaySize.width / canvasState.canvasSize.width;
    return GestureDetector(
      onTapUp: (details) {
        final tapPosition = details.localPosition / scale;
        final currentSelectedId = ref.read(selectedLayerProvider);
        final tappedLayer = canvasState.layers.lastWhereOrNull((layer) {
          if (layer is BackgroundLayer || !layer.isVisible || layer.isLocked)
            return false;
          return _isTapOnLayer(layer, tapPosition);
        });
        if (tappedLayer != null) {
          if (tappedLayer.id == currentSelectedId) {
            ref.read(selectedLayerProvider.notifier).state = null;
          } else {
            ref.read(selectedLayerProvider.notifier).state = tappedLayer.id;
          }
        } else {
          ref.read(selectedLayerProvider.notifier).state = null;
        }
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
        final updatedLayer = currentLayer.copyWith(
          rect: newRect,
          scale: newScale,
          rotation: newRotation,
        );
        canvasNotifier.updateLayerLive(updatedLayer);
      },
      onScaleEnd: (details) {
        final selectedId = ref.read(selectedLayerProvider);
        if (selectedId != null && _initialLayerState != null) {
          canvasNotifier.commitTransform(selectedId);
        }
        _initialLayerState = null;
        _initialFocalPoint = null;
      },
      child: CustomPaint(
        size: canvasDisplaySize,
        painter: CanvasPainter(
          canvasState: canvasState,
          selectedLayerId: selectedLayerId,
        ),
      ),
    );
  }

  bool _isTapOnLayer(Layer layer, Offset tapPosition) {
    final transform = Matrix4.identity()
      ..translate(layer.rect.center.dx, layer.rect.center.dy)
      ..rotateZ(layer.rotation)
      ..scale(layer.scale)
      ..translate(-layer.rect.center.dx, -layer.rect.center.dy);

    final invTransform = Matrix4.inverted(transform);
    final transformedTapPosition = MatrixUtils.transformPoint(
      invTransform,
      tapPosition,
    );

    return layer.rect.contains(transformedTapPosition);
  }

  double _calculateScale(Size originalSize, Size targetSize) {
    final double scaleX = targetSize.width / originalSize.width;
    final double scaleY = targetSize.height / originalSize.height;
    return min(scaleX, scaleY);
  }

  // double _calculateScale(Size originalSize, Size targetSize) {
  //   final double scaleX = targetSize.width / originalSize.width;
  //   final double scaleY = targetSize.height / originalSize.height;
  //   return min(scaleX, scaleY);
  // }
}

class CanvasPainter extends CustomPainter {
  const CanvasPainter({required this.canvasState, this.selectedLayerId});

  final CanvasState canvasState;
  final String? selectedLayerId;

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
      Paint(),
    );
  }

  void _paintShapeLayer(Canvas canvas, ShapeLayer layer) {
    final paint = Paint()
      ..color = layer.color.withOpacity(layer.opacity)
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
