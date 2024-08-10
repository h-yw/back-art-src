import 'dart:typed_data';

import 'package:BackArt/config/font_list.dart';
import 'package:BackArt/utils/gradients.dart';
import 'package:BackArt/utils/position.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math';

class Painter extends CustomPainter {
  final Map<String, dynamic> data;
  final double dpi;
  final Size paintOriginSize;

  Painter(this.data, this.dpi, this.paintOriginSize);

  final double padding = 16;
  final int easingStops = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final resSize = calculateScaledSize(
        originalSize: data["size"], targetSize: paintOriginSize);
    drawAll(canvas, resSize);
  }

  // 返回false, 后面介绍
  @override
  bool shouldRepaint(Painter oldDelegate) {
    return true; //mapsAreEqual(oldDelegate.data , data);
  }

  Rect drawAll(Canvas canvas, Size size) {
    Rect rect = drawBack(canvas, size);
    Size markSize = const Size(0, 0);
    if (data["mark"] != null && data["mark"] != "") {
      markSize = drawMark(canvas, size);
    }
    drawText(canvas, size, markSize);

    return rect;
  }

  drawBack(Canvas canvas, Size size) {
    var paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.transparent;
    var rect = Offset.zero & size;
    // canvas.drawRect(rect, paint);
    paint.color = data["background"];
    canvas.drawRect(rect, paint);
    return rect;
  }

  void drawText(Canvas canvas, Size size, Size markSize) {
    if (data["text"] == null) {
      return;
    }
    Color color = getContrastingTextColor(data["background"]);
    final span = TextSpan(
        text: data["text"],
        style: TextStyle(
            height: data["lineHeight"] ?? 1,
            color: color,
            fontSize: data["fontSize"],
            fontFamily: data["fontFamily"]));
    final textPainter = TextPainter(
      text: span,
      textAlign: TextAlign.start,
      textDirection: TextDirection.ltr,
    );
    if (data["align"] is TextAlign) {
      // span.style.a
      textPainter.textAlign = data["align"];
    }
    textPainter.layout(minWidth: 0, maxWidth: size.width);

    Offset textOffset = Offset(0, 0);
    Offset offset = calculateOffset(
      position: data["layout"],
      contentSize: textPainter.size,
      paintAreaSize: size,
      markPosition: data["markPos"],
      markSize: markSize,
    );
    print("textPainter====>${textPainter}");
    textPainter.paint(canvas, offset);
  }

  Size drawMark(Canvas canvas, Size size) {
    Color color = getContrastingTextColor(data["background"]);
    final span = TextSpan(
        text: "@${data["mark"]}",
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontFamily: FontFamilyName.lXGWBright,
          fontStyle: FontStyle.italic,
        ));

    final textPainter = TextPainter(
        text: span,
        textAlign: TextAlign.start,
        textDirection: TextDirection.ltr);
    textPainter.layout(minWidth: 0, maxWidth: size.width);
    var markPos =
        MarkPos(areaSize: size, textPainter: textPainter, padding: padding);

    textPainter.paint(
        canvas,
        markPos.getMarkOffset(
            PositionEnum.values.firstWhere((v) => v == data["markPos"]))!);
    return textPainter.size;
  }

  bool mapsAreEqual(Map map1, Map map2) {
    if (map1.length != map2.length) {
      return true;
    }

    for (var key in map1.keys) {
      if (map1[key] != map2[key]) {
        return true;
      }
    }

    return false;
  }

  Color getContrastingTextColor(Color backgroundColor) {
    // 计算背景色的相对亮度
    double luminance = calculateLuminance(backgroundColor);

    // 根据亮度选择文字颜色
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  double calculateLuminance(Color color) {
    // 将颜色分量转换为0到1之间的值
    double r = color.red / 255.0;
    double g = color.green / 255.0;
    double b = color.blue / 255.0;

    // 计算相对亮度

    r = (r <= 0.03928) ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4).toDouble();
    g = (g <= 0.03928) ? g / 12.92 : pow(((g + 0.055) / 1.055), 2.4).toDouble();
    b = (b <= 0.03928) ? b / 12.92 : pow(((b + 0.055) / 1.055), 2.4).toDouble();

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  Size calculateScaledSize({
    required Size originalSize, // 原始内容的大小
    required Size targetSize, // 目标区域的大小
  }) {
    // 计算缩放比例
    final double scaleX = targetSize.width / originalSize.width;
    final double scaleY = targetSize.height / originalSize.height;
    final double scale = scaleX < scaleY ? scaleX : scaleY; // 保持内容的比例
    // 计算缩放后的内容尺寸
    double scaledWidth = targetSize.width;
    double scaledHeight = originalSize.height * scale;

    if (scaleX > scaleY) {
      scaledWidth = originalSize.width * scale;

      scaledHeight = targetSize.height;
    }
    return Size(scaledWidth, scaledHeight);
  }

  Offset calculateOffset(
      {required PositionEnum position,
      required Size contentSize, // 目标区域的大小
      required Size paintAreaSize,
      required Size markSize,
      required PositionEnum markPosition // 内容区域的大小
      }) {
    // print("position===>${targetSize} ${contentSize}");
    var pw = paintAreaSize.width;
    var ph = paintAreaSize.height;
    var cw = contentSize.width;
    var ch = contentSize.height;
    var mw = markSize.width;
    var mh = markSize.height;
    var gap = 4;
    var markTop =
        AlignLayout.getPosition(PositionType.top).contains(markPosition)
            ? mh + gap
            : 0;
    var markBottom =
        AlignLayout.getPosition(PositionType.bottom).contains(markPosition)
            ? mh + gap
            : 0;
    switch (position) {
      case PositionEnum.topLeft:
        {
          var left = padding;
          var top = padding + markTop;
          return Offset(left, top);
        }
      case PositionEnum.topCenter:
        {
          var left = (pw - cw) / 2;
          var top = padding + markTop;
          return Offset(left, top);
        }
      case PositionEnum.topRight:
        {
          var left = pw - cw - padding;
          var top = padding + markTop;
          return Offset(left, top);
        }
      case PositionEnum.bottomLeft:
        {
          var left = padding;
          var top = ph - ch - padding - markBottom;
          return Offset(left, top);
        }
      case PositionEnum.bottomCenter:
        {
          var left = (pw - cw) / 2;
          var top = ph - ch - padding - markBottom;
          return Offset(left, top);
        }
      case PositionEnum.bottomRight:
        {
          var left = pw - cw - padding;
          var top = ph - ch - padding - markBottom;
          return Offset(left, top);
        }
      case PositionEnum.center:
        {
          var left = (pw - cw) / 2;
          var top = (ph - ch) / 2;
          return Offset(left, top);
        }
      case PositionEnum.centerLeft:
        {
          var left = padding;
          var top = (ph - ch) / 2;
          return Offset(left, top);
        }
      case PositionEnum.centerRight:
        {
          var left = pw - cw - padding;
          var top = (ph - ch) / 2;
          return Offset(left, top);
        }
      default:
        return Offset(padding, padding);
    }
  }
}

class MarkPos {
  const MarkPos(
      {required this.areaSize, required this.textPainter, this.padding = 0});

  final Size areaSize;
  final TextPainter textPainter;
  final double padding;

  Offset get topLeft => Offset(padding, padding);

  Offset get topCenter =>
      Offset((areaSize.width - textPainter.width) / 2, padding);

  Offset get topRight =>
      Offset(areaSize.width - textPainter.width - padding, padding);

  Offset get bottomLeft =>
      Offset(padding, (areaSize.height - textPainter.height) - padding);

  Offset get bottomCenter => Offset((areaSize.width - textPainter.width) / 2,
      (areaSize.height - textPainter.height) - padding);

  Offset get bottomRight => Offset(areaSize.width - textPainter.width - padding,
      areaSize.height - textPainter.height - padding);

  Offset? getMarkOffset(PositionEnum pos) {
    switch (pos) {
      case PositionEnum.topLeft:
        return topLeft;
      case PositionEnum.topCenter:
        return topCenter;
      case PositionEnum.topRight:
        return topRight;
      case PositionEnum.bottomLeft:
        return bottomLeft;
      case PositionEnum.bottomCenter:
        return bottomCenter;
      case PositionEnum.bottomRight:
        return bottomRight;
    }
    return null;
  }
}

enum MarkPosEnum {
  topLeft,
  topCenter,
  topRight,
  bottomLeft,
  bottomCenter,
  bottomRight
}
