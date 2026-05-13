import 'package:flutter/material.dart';
import 'dart:ui' as ui;

// 使用一个全局的私有计数器来生成唯一的ID
int _idCounter = 0;
final RegExp _layerIdPattern = RegExp(r'^layer_(\d+)$');

String _generateUniqueId() {
  _idCounter++;
  return 'layer_$_idCounter';
}

String generateLayerId() => _generateUniqueId();

void syncLayerIdCounterWithIds(Iterable<String> ids) {
  for (final id in ids) {
    final match = _layerIdPattern.firstMatch(id);
    final parsedValue = match == null ? null : int.tryParse(match.group(1)!);
    if (parsedValue != null && parsedValue > _idCounter) {
      _idCounter = parsedValue;
    }
  }
}

@visibleForTesting
void resetLayerIdCounterForTest([int value = 0]) {
  _idCounter = value;
}

Size _calculateTextSize(
  String text,
  TextStyle style,
  TextAlign textAlign,
  double maxWidth,
) {
  final textSpan = TextSpan(text: text, style: style);
  final textPainter = TextPainter(
    text: textSpan,
    textAlign: textAlign,
    textDirection: TextDirection.ltr, // Assuming LTR for now
  );
  textPainter.layout(minWidth: 0, maxWidth: maxWidth);
  return textPainter.size;
}

@immutable
abstract class Layer {
  const Layer({
    required this.id,
    this.rect = const Rect.fromLTWH(0, 0, 200, 100),
    this.rotation = 0.0,
    this.scale = 1.0,
    this.opacity = 1.0,
    this.alignment,
    this.isVisible = true,
    this.isLocked = false,
  });

  final String id;
  final Rect rect;
  final double rotation;
  final double scale;
  final double opacity;
  final Alignment? alignment;
  final bool isVisible;
  final bool isLocked;

  Layer copyWith({
    String? id,
    Rect? rect,
    double? rotation,
    double? scale,
    double? opacity,
    Alignment? alignment,
    bool? isVisible,
    bool? isLocked,
  });
}

@immutable
class BackgroundLayer extends Layer {
  const BackgroundLayer({
    required String id,
    this.color = Colors.white,
    this.gradient,
  }) : super(id: id, isLocked: true, isVisible: true);

  factory BackgroundLayer.initial() {
    return BackgroundLayer(id: _generateUniqueId());
  }

  final Color color;
  final Gradient? gradient;

  @override
  BackgroundLayer copyWith({
    String? id,
    Rect? rect,
    double? rotation,
    double? scale,
    double? opacity,
    Alignment? alignment,
    Color? color,
    Gradient? gradient,
    bool setGradient = false,
    bool? isVisible,
    bool? isLocked,
  }) {
    // Background layer doesn't have most of these, but we pass them for consistency.
    return BackgroundLayer(
      id: id ?? this.id,
      color: color ?? this.color,
      gradient: setGradient ? gradient : this.gradient,
    );
  }
}

@immutable
class TextLayer extends Layer {
  const TextLayer({
    required String id,
    Rect rect = const Rect.fromLTWH(50, 50, 300, 150),
    Alignment? alignment,
    double rotation = 0.0,
    double scale = 1.0,
    double opacity = 1.0,
    bool isVisible = true,
    bool isLocked = false,
    this.text = 'Hello, World!',
    this.style = const TextStyle(
      fontSize: 48,
      color: Colors.black,
      fontFamily: 'OppoSans',
    ),
    this.textAlign = TextAlign.center,
    this.hasStroke = false,
    this.strokeColor = Colors.white,
    this.strokeWidth = 2.0,
  }) : super(
         id: id,
         rect: rect,
         alignment: alignment,
         rotation: rotation,
         scale: scale,
         opacity: opacity,
         isVisible: isVisible,
         isLocked: isLocked,
       );

  factory TextLayer.initial() {
    const defaultText = 'Hello, World!';
    const defaultStyle = TextStyle(
      fontSize: 48,
      color: Colors.black,
      fontFamily: 'OppoSans',
    );
    const defaultTextAlign = TextAlign.center;

    // A reasonable initial max width for text, assuming a typical phone screen width.
    // This can be adjusted or made dynamic based on canvas size if needed.
    const initialMaxWidth = 800.0;

    final initialSize = _calculateTextSize(
      defaultText,
      defaultStyle,
      defaultTextAlign,
      initialMaxWidth,
    );

    return TextLayer(
      id: _generateUniqueId(),
      text: defaultText,
      style: defaultStyle,
      textAlign: defaultTextAlign,
      rect: Rect.fromLTWH(50, 50, initialSize.width, initialSize.height),
    );
  }

  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final bool hasStroke;
  final Color strokeColor;
  final double strokeWidth;

  @override
  TextLayer copyWith({
    String? id,
    Rect? rect,
    double? rotation,
    double? scale,
    double? opacity,
    Alignment? alignment,
    String? text,
    TextStyle? style,
    TextAlign? textAlign,
    bool? isVisible,
    bool? isLocked,
    bool? hasStroke,
    Color? strokeColor,
    double? strokeWidth,
  }) {
    return TextLayer(
      id: id ?? this.id,
      rect: rect ?? this.rect,
      alignment: alignment ?? this.alignment,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      opacity: opacity ?? this.opacity,
      text: text ?? this.text,
      style: style ?? this.style,
      textAlign: textAlign ?? this.textAlign,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      hasStroke: hasStroke ?? this.hasStroke,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
}

@immutable
class ImageLayer extends Layer {
  const ImageLayer({
    required String id,
    required this.image,
    Rect rect = const Rect.fromLTWH(100, 100, 200, 200),
    Alignment? alignment,
    double rotation = 0.0,
    double scale = 1.0,
    double opacity = 1.0,
    bool isVisible = true,
    bool isLocked = false,
  }) : super(
         id: id,
         rect: rect,
         alignment: alignment,
         rotation: rotation,
         scale: scale,
         opacity: opacity,
         isLocked: isLocked,
         isVisible: isVisible,
       );

  factory ImageLayer.fromImage(ui.Image image) {
    return ImageLayer(
      id: _generateUniqueId(),
      image: image,
      rect: Rect.fromLTWH(
        100,
        100,
        image.width.toDouble(),
        image.height.toDouble(),
      ),
    );
  }

  final ui.Image image;

  @override
  ImageLayer copyWith({
    String? id,
    Rect? rect,
    double? rotation,
    double? scale,
    double? opacity,
    bool? isVisible,
    bool? isLocked,
    Alignment? alignment,
    ui.Image? image,
  }) {
    return ImageLayer(
      id: id ?? this.id,
      rect: rect ?? this.rect,
      alignment: alignment ?? this.alignment,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      opacity: opacity ?? this.opacity,
      image: image ?? this.image,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

/// 定义了支持的形状类型
enum ShapeType { rectangle, circle }

/// 一个代表可编辑形状的图层
@immutable
class ShapeLayer extends Layer {
  const ShapeLayer({
    required String id,
    Rect rect = const Rect.fromLTWH(100, 100, 200, 150),
    double rotation = 0.0,
    double scale = 1.0,
    double opacity = 1.0,
    Alignment? alignment,
    bool isVisible = true,
    bool isLocked = false,
    this.shapeType = ShapeType.rectangle,
    this.color = Colors.blue,
    this.paintStyle = PaintingStyle.fill,
    this.strokeWidth = 2.0, // **新增属性**
  }) : super(
         id: id,
         rect: rect,
         rotation: rotation,
         scale: scale,
         opacity: opacity,
         alignment: alignment,
         isVisible: isVisible,
         isLocked: isLocked,
       );

  factory ShapeLayer.initial() {
    return ShapeLayer(
      id: _generateUniqueId(),
      rect: const Rect.fromLTWH(100, 100, 200, 150),
      rotation: 0.0,
      scale: 1.0,
      opacity: 1.0,
      alignment: null,
      shapeType: ShapeType.rectangle,
      color: Colors.blue,
      paintStyle: PaintingStyle.fill,
      strokeWidth: 2.0,
    );
  }

  final ShapeType shapeType;
  final Color color;
  final PaintingStyle paintStyle;
  final double? strokeWidth;

  @override
  ShapeLayer copyWith({
    String? id,
    Rect? rect,
    double? rotation,
    double? scale,
    double? opacity,
    Alignment? alignment,
    ShapeType? shapeType,
    Color? color,
    PaintingStyle? paintStyle,
    double? strokeWidth,
    bool? isVisible,
    bool? isLocked,
  }) {
    return ShapeLayer(
      id: id ?? this.id,
      rect: rect ?? this.rect,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      opacity: opacity ?? this.opacity,
      alignment: alignment ?? this.alignment,
      shapeType: shapeType ?? this.shapeType,
      color: color ?? this.color,
      paintStyle: paintStyle ?? this.paintStyle,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}
