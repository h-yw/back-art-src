import 'dart:math' as math;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:share_plus/share_plus.dart';

enum ExportImageFormat { png, jpg }

extension ExportImageFormatX on ExportImageFormat {
  String get fileExtension => switch (this) {
    ExportImageFormat.png => 'png',
    ExportImageFormat.jpg => 'jpg',
  };

  String get mimeType => switch (this) {
    ExportImageFormat.png => 'image/png',
    ExportImageFormat.jpg => 'image/jpeg',
  };
}

class ExportService {
  Future<Uint8List?> captureCanvasBytes(
    GlobalKey boundaryKey, {
    required Size outputSize,
    required ExportImageFormat format,
    int jpegQuality = 92,
  }) async {
    try {
      final boundary =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        return null;
      }

      final boundarySize = boundary.size;
      final pixelRatio = math.max(
        outputSize.width / boundarySize.width,
        outputSize.height / boundarySize.height,
      );
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      return _encodeImage(image, format: format, jpegQuality: jpegQuality);
    } catch (e) {
      debugPrint('Error capturing canvas: $e');
      return null;
    }
  }

  Future<bool> saveImageBytes(
    Uint8List bytes, {
    required ExportImageFormat format,
    String? fileName,
  }) async {
    try {
      final result = await SaverGallery.saveImage(
        bytes,
        quality: 100,
        fileName: fileName ?? _defaultFileName(format),
        skipIfExists: false,
      );
      return result.isSuccess;
    } catch (e) {
      debugPrint('Error saving canvas: $e');
      return false;
    }
  }

  Future<bool> shareImageBytes(
    Uint8List bytes, {
    required ExportImageFormat format,
    String? fileName,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final resolvedFileName = fileName ?? _defaultFileName(format);
      final file = File('${tempDir.path}/$resolvedFileName');
      await file.writeAsBytes(bytes);
      final params = ShareParams(
        text: '分享来自 BackArt：https://github.com/xiaoxiao-xiao/back_art',
        subject: 'BackArt',
        files: [XFile(file.path, bytes: bytes, mimeType: format.mimeType)],
      );
      final result = await SharePlus.instance.share(params);
      return result.status != ShareResultStatus.unavailable;
    } catch (e) {
      debugPrint('Error sharing canvas: $e');
      return false;
    }
  }

  Future<Uint8List?> _encodeImage(
    ui.Image image, {
    required ExportImageFormat format,
    required int jpegQuality,
  }) async {
    switch (format) {
      case ExportImageFormat.png:
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        return byteData?.buffer.asUint8List();
      case ExportImageFormat.jpg:
        final byteData = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        if (byteData == null) {
          return null;
        }
        final convertedImage = img.Image.fromBytes(
          width: image.width,
          height: image.height,
          bytes: byteData.buffer,
          numChannels: 4,
          order: img.ChannelOrder.rgba,
        );
        return Uint8List.fromList(
          img.encodeJpg(convertedImage, quality: jpegQuality),
        );
    }
  }

  String _defaultFileName(ExportImageFormat format) {
    return 'back_art_${DateTime.now().millisecondsSinceEpoch}.${format.fileExtension}';
  }
}
