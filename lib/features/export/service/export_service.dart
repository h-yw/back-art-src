// lib/features/export/service/export_service.dart

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  Future<bool> saveCanvas(
      GlobalKey boundaryKey, {
        // 接受一个 pixelRatio 参数，默认为 3.0
        required double pixelRatio,
      }) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
      if (boundary == null) {
        return false;
      }

      // 使用传入的 pixelRatio 来生成图像
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final result = await SaverGallery.saveImage(
          byteData.buffer.asUint8List(),
          quality: 100,
          fileName: 'back_art_${DateTime.now().millisecondsSinceEpoch}.png',
          skipIfExists: false,
        );
        return result.isSuccess;
      }
      return false;
    } catch (e) {
      debugPrint('Error saving canvas: $e');
      return false;
    }
  }
  /// 新增的分享方法
  Future<void> shareCanvas(
      GlobalKey boundaryKey, {
        required double pixelRatio,
      }) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
      if (boundary == null) {
        return;
      }

      // 使用传入的 pixelRatio 来生成图像
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return;
      }
      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/back_art_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      ShareParams params =ShareParams(
          text:'分享来自额BackArt来自：https://github.com/xiaoxiao-xiao/back_art',
        subject: 'BackArt',
        files: [XFile(file.path,bytes:bytes ,mimeType: 'image/png')]
      );
      await SharePlus.instance.share(params);
    } catch (e) {
      debugPrint('Error sharing canvas: $e');
    }
  }
}