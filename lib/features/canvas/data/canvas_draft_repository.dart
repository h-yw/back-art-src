import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:BackArt/features/canvas/model/layer.dart';
import 'package:BackArt/features/canvas/state/canvas_state.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class CanvasDraftRepository {
  CanvasDraftRepository({Directory? baseDirectory})
    : _baseDirectory = baseDirectory;

  final Directory? _baseDirectory;
  Future<void> _pendingSave = Future.value();

  static const _fileName = 'back_art_draft.json';
  static const _version = 1;

  Future<CanvasState?> load() async {
    try {
      final file = await _draftFile();
      if (!await file.exists()) return null;

      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, dynamic>) return null;

      return _canvasStateFromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(CanvasState state) async {
    _pendingSave = _pendingSave
        .catchError((_) {})
        .then((_) => _writeState(state));
    return _pendingSave;
  }

  Future<void> _writeState(CanvasState state) async {
    final file = await _draftFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(await _canvasStateToJson(state)));
  }

  Future<File> _draftFile() async {
    final directory =
        _baseDirectory ?? await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<Map<String, dynamic>> _canvasStateToJson(CanvasState state) async {
    return {
      'version': _version,
      'canvasSize': _sizeToJson(state.canvasSize),
      'layers': [for (final layer in state.layers) await _layerToJson(layer)],
    };
  }

  Future<CanvasState?> _canvasStateFromJson(Map<String, dynamic> json) async {
    final layersJson = json['layers'];
    if (layersJson is! List) return null;

    final layers = <Layer>[];
    for (final layerJson in layersJson) {
      if (layerJson is! Map<String, dynamic>) continue;
      final layer = await _layerFromJson(layerJson);
      if (layer != null) layers.add(layer);
    }

    if (layers.whereType<BackgroundLayer>().isEmpty) {
      layers.insert(0, BackgroundLayer.initial());
    }

    if (layers.length == 1) {
      layers.add(TextLayer.initial());
    }

    return CanvasState(
      canvasSize: _sizeFromJson(json['canvasSize']) ?? const Size(1080, 1920),
      layers: layers,
    );
  }

  Future<Map<String, dynamic>> _layerToJson(Layer layer) async {
    final base = {
      'id': layer.id,
      'rect': _rectToJson(layer.rect),
      'rotation': layer.rotation,
      'scale': layer.scale,
      'opacity': layer.opacity,
      'alignment': _alignmentToJson(layer.alignment),
      'isVisible': layer.isVisible,
      'isLocked': layer.isLocked,
    };

    return switch (layer) {
      BackgroundLayer() => {
        ...base,
        'type': 'background',
        'color': _colorToInt(layer.color),
        'gradient': _gradientToJson(layer.gradient),
      },
      TextLayer() => {
        ...base,
        'type': 'text',
        'text': layer.text,
        'style': _textStyleToJson(layer.style),
        'textAlign': layer.textAlign.index,
        'hasStroke': layer.hasStroke,
        'strokeColor': _colorToInt(layer.strokeColor),
        'strokeWidth': layer.strokeWidth,
      },
      ImageLayer() => {
        ...base,
        'type': 'image',
        'imageBytes': await _imageToBase64(layer.image),
      },
      ShapeLayer() => {
        ...base,
        'type': 'shape',
        'shapeType': layer.shapeType.index,
        'color': _colorToInt(layer.color),
        'paintStyle': layer.paintStyle.index,
        'strokeWidth': layer.strokeWidth,
      },
      _ => base,
    };
  }

  Future<Layer?> _layerFromJson(Map<String, dynamic> json) async {
    final id = json['id'];
    final type = json['type'];
    if (id is! String || type is! String) return null;

    final rect = _rectFromJson(json['rect']);
    final alignment = _alignmentFromJson(json['alignment']);
    final rotation = _doubleFromJson(json['rotation']) ?? 0.0;
    final scale = _doubleFromJson(json['scale']) ?? 1.0;
    final opacity = _doubleFromJson(json['opacity']) ?? 1.0;
    final isVisible = json['isVisible'] as bool? ?? true;
    final isLocked = json['isLocked'] as bool? ?? false;

    switch (type) {
      case 'background':
        return BackgroundLayer(
          id: id,
          color: _colorFromJson(json['color']) ?? Colors.white,
          gradient: _gradientFromJson(json['gradient']),
        );
      case 'text':
        return TextLayer(
          id: id,
          rect: rect ?? const Rect.fromLTWH(50, 50, 300, 150),
          alignment: alignment,
          rotation: rotation,
          scale: scale,
          opacity: opacity,
          isVisible: isVisible,
          isLocked: isLocked,
          text: json['text'] as String? ?? '',
          style: _textStyleFromJson(json['style']),
          textAlign: _enumValue(
            TextAlign.values,
            json['textAlign'],
            TextAlign.center,
          ),
          hasStroke: json['hasStroke'] as bool? ?? false,
          strokeColor: _colorFromJson(json['strokeColor']) ?? Colors.white,
          strokeWidth: _doubleFromJson(json['strokeWidth']) ?? 2.0,
        );
      case 'image':
        final image = await _imageFromBase64(json['imageBytes']);
        if (image == null) return null;
        return ImageLayer(
          id: id,
          image: image,
          rect: rect ?? const Rect.fromLTWH(100, 100, 200, 200),
          alignment: alignment,
          rotation: rotation,
          scale: scale,
          opacity: opacity,
          isVisible: isVisible,
          isLocked: isLocked,
        );
      case 'shape':
        return ShapeLayer(
          id: id,
          rect: rect ?? const Rect.fromLTWH(100, 100, 200, 150),
          alignment: alignment,
          rotation: rotation,
          scale: scale,
          opacity: opacity,
          isVisible: isVisible,
          isLocked: isLocked,
          shapeType: _enumValue(
            ShapeType.values,
            json['shapeType'],
            ShapeType.rectangle,
          ),
          color: _colorFromJson(json['color']) ?? Colors.blue,
          paintStyle: _enumValue(
            PaintingStyle.values,
            json['paintStyle'],
            PaintingStyle.fill,
          ),
          strokeWidth: _doubleFromJson(json['strokeWidth']) ?? 2.0,
        );
    }
    return null;
  }

  Map<String, dynamic> _textStyleToJson(TextStyle style) {
    return {
      'fontSize': style.fontSize,
      'color': style.color == null ? null : _colorToInt(style.color!),
      'fontFamily': style.fontFamily,
      'fontWeight': style.fontWeight == null
          ? null
          : FontWeight.values.indexOf(style.fontWeight!),
      'fontStyle': style.fontStyle?.index,
      'height': style.height,
      'letterSpacing': style.letterSpacing,
      'backgroundColor': style.backgroundColor == null
          ? null
          : _colorToInt(style.backgroundColor!),
    };
  }

  TextStyle _textStyleFromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return const TextStyle(
        fontSize: 48,
        color: Colors.black,
        fontFamily: 'OppoSans',
      );
    }

    return TextStyle(
      fontSize: _doubleFromJson(json['fontSize']) ?? 48,
      color: _colorFromJson(json['color']) ?? Colors.black,
      fontFamily: json['fontFamily'] as String?,
      fontWeight: _enumValue(FontWeight.values, json['fontWeight'], null),
      fontStyle: _enumValue(FontStyle.values, json['fontStyle'], null),
      height: _doubleFromJson(json['height']),
      letterSpacing: _doubleFromJson(json['letterSpacing']),
      backgroundColor: _colorFromJson(json['backgroundColor']),
    );
  }

  Map<String, dynamic>? _gradientToJson(Gradient? gradient) {
    if (gradient == null) return null;

    final colors = gradient.colors.map(_colorToInt).toList();
    final stops = gradient.stops;
    if (gradient is LinearGradient) {
      return {
        'type': 'linear',
        'colors': colors,
        'stops': stops,
        'begin': _alignmentGeometryToJson(gradient.begin),
        'end': _alignmentGeometryToJson(gradient.end),
      };
    }
    if (gradient is RadialGradient) {
      return {
        'type': 'radial',
        'colors': colors,
        'stops': stops,
        'center': _alignmentGeometryToJson(gradient.center),
        'radius': gradient.radius,
      };
    }
    if (gradient is SweepGradient) {
      return {
        'type': 'sweep',
        'colors': colors,
        'stops': stops,
        'center': _alignmentGeometryToJson(gradient.center),
      };
    }
    return null;
  }

  Gradient? _gradientFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;

    final colorsJson = json['colors'];
    if (colorsJson is! List || colorsJson.isEmpty) return null;

    final colors = colorsJson
        .map(_colorFromJson)
        .whereType<Color>()
        .toList(growable: false);
    if (colors.isEmpty) return null;

    final stops = _doubleListFromJson(json['stops']);
    switch (json['type']) {
      case 'linear':
        return LinearGradient(
          colors: colors,
          stops: stops,
          begin: _alignmentFromJson(json['begin']) ?? Alignment.centerLeft,
          end: _alignmentFromJson(json['end']) ?? Alignment.centerRight,
        );
      case 'radial':
        return RadialGradient(
          colors: colors,
          stops: stops,
          center: _alignmentFromJson(json['center']) ?? Alignment.center,
          radius: _doubleFromJson(json['radius']) ?? 0.5,
        );
      case 'sweep':
        return SweepGradient(
          colors: colors,
          stops: stops,
          center: _alignmentFromJson(json['center']) ?? Alignment.center,
        );
    }
    return null;
  }

  Future<String?> _imageToBase64(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;
    return base64Encode(byteData.buffer.asUint8List());
  }

  Future<ui.Image?> _imageFromBase64(Object? value) async {
    if (value is! String || value.isEmpty) return null;
    final bytes = base64Decode(value);
    final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Map<String, double> _sizeToJson(Size size) {
    return {'width': size.width, 'height': size.height};
  }

  Size? _sizeFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final width = _doubleFromJson(json['width']);
    final height = _doubleFromJson(json['height']);
    if (width == null || height == null) return null;
    return Size(width, height);
  }

  Map<String, double> _rectToJson(Rect rect) {
    return {
      'left': rect.left,
      'top': rect.top,
      'width': rect.width,
      'height': rect.height,
    };
  }

  Rect? _rectFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final left = _doubleFromJson(json['left']);
    final top = _doubleFromJson(json['top']);
    final width = _doubleFromJson(json['width']);
    final height = _doubleFromJson(json['height']);
    if (left == null || top == null || width == null || height == null) {
      return null;
    }
    return Rect.fromLTWH(left, top, width, height);
  }

  Map<String, double>? _alignmentToJson(Alignment? alignment) {
    if (alignment == null) return null;
    return {'x': alignment.x, 'y': alignment.y};
  }

  Map<String, double>? _alignmentGeometryToJson(AlignmentGeometry alignment) {
    return _alignmentToJson(alignment as Alignment?);
  }

  Alignment? _alignmentFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final x = _doubleFromJson(json['x']);
    final y = _doubleFromJson(json['y']);
    if (x == null || y == null) return null;
    return Alignment(x, y);
  }

  int _colorToInt(Color color) {
    final a = (color.a * 255).round() & 0xff;
    final r = (color.r * 255).round() & 0xff;
    final g = (color.g * 255).round() & 0xff;
    final b = (color.b * 255).round() & 0xff;
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  Color? _colorFromJson(Object? value) {
    if (value is int) return Color(value);
    return null;
  }

  double? _doubleFromJson(Object? value) {
    if (value is num) return value.toDouble();
    return null;
  }

  List<double>? _doubleListFromJson(Object? value) {
    if (value is! List) return null;
    return value.map(_doubleFromJson).whereType<double>().toList();
  }

  T _enumValue<T>(List<T> values, Object? index, T fallback) {
    if (index is int && index >= 0 && index < values.length) {
      return values[index];
    }
    return fallback;
  }
}
