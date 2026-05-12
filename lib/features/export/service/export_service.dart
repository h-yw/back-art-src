// lib/features/export/service/export_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  Future<Uint8List?> captureCanvasPng(
    GlobalKey boundaryKey, {
    required double pixelRatio,
  }) async {
    try {
      final boundary =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        return null;
      }

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing canvas: $e');
      return null;
    }
  }

  Future<bool> savePngBytes(Uint8List bytes, {String? fileName}) async {
    try {
      final result = await SaverGallery.saveImage(
        bytes,
        quality: 100,
        fileName:
            fileName ?? 'back_art_${DateTime.now().millisecondsSinceEpoch}.png',
        skipIfExists: false,
      );
      return result.isSuccess;
    } catch (e) {
      debugPrint('Error saving canvas: $e');
      return false;
    }
  }

  Future<bool> sharePngBytes(Uint8List bytes, {String? fileName}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final resolvedFileName =
          fileName ?? 'back_art_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$resolvedFileName');
      await file.writeAsBytes(bytes);
      final params = ShareParams(
        text: '分享来自 BackArt：https://github.com/xiaoxiao-xiao/back_art',
        subject: 'BackArt',
        files: [XFile(file.path, bytes: bytes, mimeType: 'image/png')],
      );
      final result = await SharePlus.instance.share(params);
      return result.status != ShareResultStatus.unavailable;
    } catch (e) {
      debugPrint('Error sharing canvas: $e');
      return false;
    }
  }
}
