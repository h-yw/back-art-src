import 'package:flutter/material.dart';

/// 一个用于颜色相关操作的工具类。
class ColorUtils {
  /// 为给定的 [color] 计算一个对比色（黑色或白色）。
  ///
  /// 这对于确保文本在彩色背景上的可读性非常有用。
  static Color getContrastingColor(Color color) {
    // 亮度公式为 0.299*R + 0.587*G + 0.114*B。
    // 使用 128 作为阈值是一种常见的做法。
    final double luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue);

    // 当亮度值大于128时，背景偏亮，应使用黑色文字；否则使用白色文字。
    return luminance > 128 ? Colors.black : Colors.white;
  }
}