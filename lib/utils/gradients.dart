import 'dart:math';

import 'package:flutter/material.dart';
enum GradientType { linear, radial, sweep }

class GradientsGenerator {
  List<HSLColor> _palette = [];
  final List _points = [];

  static num easeInOutCubic(double x) {
    return x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2;
  }

  List<HSLColor> get palette => _palette;

  List get points => _points;

  generateRandomPalette() {
    _palette.clear();
    generateInitialPalette();
    if (_palette.isEmpty) {
      generateInitialPalette();
    }
    regeneratePoints();
  }

  generateInitialPalette() {
    final colorCount = generatorRandomInt(min: 2, max: 6);
    generatePaletteColors(colorCount);
  }

  regeneratePoints() {
    _points.clear();
    defaultPointsGenerator(pointCount: generatorRandomInt(min: 3, max: 13));
  }

  generatePaletteColors(int colorCount) {
    final schemes = [
      'monochromatic',
      'analogous',
      'complement',
      'triad',
      'quad',
      'split-complement',
      'tetrad',
      'square',
      'pentagon',
    ];

    final scheme = schemes[generatorRandomInt(min: 0, max: schemes.length)];
    final baseColor = generateRandomHSLColor();
    final saturation = generatorRandomDouble(min: 0.6, max: 1);
    final lightness = generatorRandomDouble(min: 0.3, max: 0.8);
    switch (scheme) {
      case 'monochromatic':
        _palette = scale(
          colorList: [
            darken(
              baseColor,
              0.25,
            ).withLightness(lightness).withSaturation(saturation),
            baseColor.withSaturation(saturation).withLightness(lightness),
            brighten(
              baseColor,
              0.25,
            ).withLightness(lightness).withSaturation(saturation),
          ],
          num: colorCount,
        );
        break;
      case 'analogous':
        _palette = scale(
          colorList: [
            baseColor
                .withHue(-30 + 360)
                .withSaturation(saturation)
                .withLightness(lightness),
            baseColor.withSaturation(saturation).withLightness(lightness),
            baseColor
                .withHue(30)
                .withSaturation(saturation)
                .withLightness(lightness),
          ],
          num: colorCount,
        );
        break;

      case 'complement':
        _palette = scale(
          colorList: [
            baseColor.withSaturation(saturation).withLightness(lightness),
            baseColor
                .withHue(180)
                .withSaturation(saturation)
                .withLightness(lightness),
          ],
          num: colorCount,
        );
        break;
      case 'triad':
        _palette = scale(
          colorList: [
            baseColor.withSaturation(saturation).withLightness(lightness),
            baseColor
                .withHue(120)
                .withLightness(lightness)
                .withSaturation(saturation),
            baseColor
                .withHue(-120 + 360)
                .withSaturation(saturation)
                .withLightness(lightness),
          ],
          num: colorCount,
        );
        break;
      case 'quad':
        _palette = scale(
          colorList: [
            baseColor.withSaturation(saturation).withLightness(lightness),
            baseColor
                .withHue(90)
                .withSaturation(saturation)
                .withLightness(lightness),
            baseColor
                .withHue(-90 + 360)
                .withSaturation(saturation)
                .withLightness(lightness),
            baseColor
                .withHue(180)
                .withSaturation(saturation)
                .withLightness(lightness),
          ],
          num: colorCount,
        );
        break;
      case 'split-complement':
        _palette = scale(
          colorList: [
            baseColor.withSaturation(saturation).withLightness(lightness),
            baseColor
                .withHue(150)
                .withSaturation(saturation)
                .withLightness(lightness),
            baseColor
                .withHue(-150 + 360)
                .withSaturation(saturation)
                .withLightness(lightness),
          ],
          num: colorCount,
        );
        break;
      case 'tetrad':
        _palette = scale(
          colorList: [
            baseColor.withSaturation(saturation).withLightness(lightness),
            baseColor
                .withHue(90)
                .withSaturation(saturation)
                .withLightness(lightness),
            baseColor
                .withHue(180)
                .withSaturation(saturation)
                .withLightness(lightness),
            baseColor
                .withHue(-90 + 360)
                .withSaturation(saturation)
                .withLightness(lightness),
          ],
          num: colorCount,
        );
        break;
      case 'square':
        _palette = scale(
          colorList: [
            baseColor.withSaturation(saturation).withLightness(lightness),
            baseColor
                .withHue(90)
                .withSaturation(saturation)
                .withLightness(lightness),
            baseColor
                .withHue(180)
                .withSaturation(saturation)
                .withLightness(lightness),
            baseColor
                .withHue(-90 + 360)
                .withSaturation(saturation)
                .withLightness(lightness),
          ],
          num: colorCount,
        );
        break;
      case 'pentagon':
        _palette = scale(
          colorList: [
            baseColor.withSaturation(saturation).withLightness(lightness),
            baseColor
                .withHue(72)
                .withSaturation(saturation)
                .withLightness(lightness),
            baseColor
                .withHue(144)
                .withSaturation(saturation)
                .withLightness(lightness),
            baseColor
                .withHue(-72 + 360)
                .withSaturation(saturation)
                .withLightness(lightness),
            baseColor
                .withHue(-144 + 360)
                .withSaturation(saturation)
                .withLightness(lightness),
          ],
          num: colorCount,
        );
        break;
      default:
        _palette = scale(
          colorList: [
            baseColor.withSaturation(saturation).withLightness(lightness),
            darken(
              baseColor,
              0.15,
            ).withLightness(lightness).withSaturation(saturation),
            brighten(
              baseColor,
              0.15,
            ).withLightness(lightness).withSaturation(saturation),
          ],
          num: colorCount,
        );
        break;
    }
  }

  int generatorRandomInt({required int min, required int max}) {
    assert(max > min);
    return Random().nextInt(max - min) + min;
  }

  double generatorRandomDouble({required double min, required double max}) {
    return Random().nextDouble() * (max - min) + min;
  }

  HSLColor generateRandomHSLColor() {
    final r = generatorRandomInt(min: 0, max: 255);
    final g = generatorRandomInt(min: 0, max: 255);
    final b = generatorRandomInt(min: 0, max: 255);
    final color = HSLColor.fromColor(Color.fromRGBO(r, g, b, 1));
    return color;
  }

  HSLColor darken(HSLColor color, double amount) {
    return color.withLightness((color.lightness - amount).clamp(0.0, 1.0));
  }

  HSLColor brighten(HSLColor color, double amount) {
    return darken(color, -amount);
  }

  List<HSLColor> scale({required List<HSLColor> colorList, required int num}) {
    List<HSLColor> colors = [];
    if (num <= 0 || colorList.isEmpty) return colors;

    if (colorList.length == 1) {
      colors.add(colorList[0]);
      return colors;
    }

    final double step = (colorList.length -1) / (num -1);
    for (int i = 0; i < num; i++) {
      final double index = i * step;
      final int i1 = index.floor();
      final int i2 = index.ceil();
      final double t = index - i1;

      final color1 = colorList[i1].toColor();
      final color2 = colorList[i2].toColor();

      colors.add(HSLColor.fromColor(Color.lerp(color1, color2, t)!));
    }
    return colors;
  }

  defaultPointsGenerator({
    int? seed,
    int pointCount = 8,
    List<double> scaleRange = const [0.5, 0.7],
  }) {
    if (_palette.isEmpty) return; // 安全检查

    for (var i = 0; i < pointCount; i++) {
      final HSLColor color =
      _palette[generatorRandomInt(min: 0, max: _palette.length)];
      _points.add({
        "x": generatorRandomDouble(min: 0, max: 1),
        "y": generatorRandomDouble(min: 0, max: 1),
        "h": color.hue,
        "s": color.saturation,
        "l": color.lightness,
        "scale":
        generatorRandomDouble(min: 0, max: 1) *
            (scaleRange[1] - scaleRange[0]) +
            scaleRange[0],
      });
    }
  }
}