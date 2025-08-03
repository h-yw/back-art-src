// lib/config/templates.dart
import 'package:BackArt/features/canvas/state/canvas_state.dart';
import 'package:BackArt/features/canvas/model/layer.dart';
import 'package:BackArt/config/font_list.dart'; // 引用字体列表
import 'package:BackArt/utils/gradients.dart'; // 引用渐变生成器
import 'package:flutter/material.dart';

/// 定义一个数据类，用于封装模板的背景和内容图层
class Template {
  final BackgroundLayer background;
  final List<Layer> contentLayers;

  Template({required this.background, required this.contentLayers});
}

/// 模板函数：空白模版
/// 特点：
Template blankTemplate(){
  final background = BackgroundLayer.initial().copyWith(
    color: Colors.white, // 白色背景
  );
  final textLayer = TextLayer.initial().copyWith(
    text: '东方欲晓\n莫道君行早；\n',
    alignment: Alignment.center,
    style: const TextStyle(
      fontSize: 80,
      color: Colors.black87,
      fontFamily: AppFonts.lxgwBright,
      fontWeight: FontWeight.w900, // 极粗字体
      height: 1.2,
      letterSpacing: 2.0,
    ),
  );
  return Template(background: background, contentLayers: [textLayer]);
}

/// 模板函数：现代简约风
/// 特点：纯色背景，居中粗体文本，醒目易读。
Template modernMinimalistTemplate(){
  final background = BackgroundLayer.initial().copyWith(
    color: const Color(0xFFF0F2F5), // 浅灰色背景
  );
  final textLayer = TextLayer.initial().copyWith(
    text: '创意\n无限',
    alignment: Alignment.center,
    style: const TextStyle(
      fontSize: 80,
      color: Colors.black87,
      fontFamily: AppFonts.oppoSans,
      fontWeight: FontWeight.w900, // 极粗字体
      height: 1.2,
      letterSpacing: 2.0,
    ),
  );
  final layers =[textLayer];
  return Template(background: background, contentLayers: layers);
}

/// 模板函数：日落渐变诗意风
/// 特点：美丽的渐变背景，带有描边的诗意文本。
Template sunsetGradientTemplate(){
  final gradientsGenerator = GradientsGenerator();
  gradientsGenerator.generatePaletteColors(2);
  final gradient = LinearGradient(
    colors: [
      gradientsGenerator.palette[0].toColor(),
      gradientsGenerator.palette[1].toColor(),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final background = BackgroundLayer.initial().copyWith(
    gradient: gradient,
    setGradient: true,
  );
  final textLayer = TextLayer.initial().copyWith(
    text: '时光荏苒\n岁月静好',
    alignment: Alignment.bottomCenter,
    style: const TextStyle(
      fontSize: 48,
      color: Colors.white,
      fontFamily: AppFonts.lxgwWenKai, // 楷体字体
      height: 1.5,
      letterSpacing: 1.0,
    ),
    hasStroke: true,
    strokeColor: Colors.black.withOpacity(0.5),
    strokeWidth: 2.5,
  );
  return Template(background: background, contentLayers: [textLayer]);
}
/// 模板函数：活泼可爱表情风
/// 特点：多图层组合，包含文本、圆形和表情符号。
Template playfulEmojiTemplate(){
  final background =BackgroundLayer.initial().copyWith(
    color: Colors.yellow.shade100,
  );
  final textLayer = TextLayer.initial().copyWith(
    text: '开心每一天',
    rect: const Rect.fromLTWH(150, 200, 300, 100),
    style: const TextStyle(
      fontSize: 56,
      color: Colors.black,
      fontFamily: AppFonts.smileySans,
    ),
  );
  final shapeLayer = ShapeLayer.initial().copyWith(
    shapeType: ShapeType.circle,
    rect: const Rect.fromLTWH(100, 500, 200, 200),
    color: Colors.pink.shade400.withOpacity(0.8),
    paintStyle: PaintingStyle.fill,
  );
  final emojiLayer = TextLayer.initial().copyWith(
    text: '🎉',
    rect: const Rect.fromLTWH(350, 450, 150, 150),
    style: const TextStyle(fontSize: 150, backgroundColor: Colors.transparent),
  );
  final layers=  [textLayer,shapeLayer,emojiLayer];
  return Template(background: background, contentLayers: layers);
}
/// 模板函数：科技感标题
/// 特点：深色背景，科幻字体，适合用作标题或口号。
Template techTitleTemplate(){
  final background = BackgroundLayer.initial().copyWith(
    color: const Color(0xFF1E212D), // 深色背景
  );
  final textLayer = TextLayer.initial().copyWith(
    text: 'BACK\nART',
    alignment: Alignment.center,
    style: const TextStyle(
      fontSize: 100,
      color: Colors.cyanAccent,
      fontFamily: AppFonts.monoton, // 科技感字体
      height: 1.0,
      letterSpacing: 5.0,
    ),
    hasStroke: true,
    strokeColor: Colors.blueAccent,
    strokeWidth: 4.0,
  );
  return Template(background: background, contentLayers:[textLayer]);
}
/// 模板函数：抽象几何风
/// 特点：通过多个透明、带描边的形状图层叠加，营造出抽象艺术感。
Template abstractGeometryTemplate(){
  final background =BackgroundLayer.initial().copyWith(
    color: const Color(0xFF1E212D), // 深色背景
  );

  final mainText = TextLayer.initial().copyWith(
    text: 'ART',
    rect: const Rect.fromLTWH(350, 800, 400, 200),
    style: const TextStyle(
      fontSize: 180,
      color: Colors.white,
      fontFamily: AppFonts.allertaStencil, // 几何感字体
      height: 1.0,
      letterSpacing: 8.0,
    ),
    hasStroke: true,
    strokeColor: const Color(0xFF45A29E),
    strokeWidth: 4.0,
  );

  // 多个形状图层进行叠加
  final circle1 = ShapeLayer.initial().copyWith(
    shapeType: ShapeType.circle,
    rect: const Rect.fromLTWH(-100, -100, 500, 500),
    color: const Color(0xFFF9F871).withOpacity(0.4),
    paintStyle: PaintingStyle.stroke,
    strokeWidth: 10.0,
  );

  final rectangle1 = ShapeLayer.initial().copyWith(
    shapeType: ShapeType.rectangle,
    rect: const Rect.fromLTWH(600, 600, 400, 400),
    color: const Color(0xFF66BFBF).withOpacity(0.6),
    rotation: 0.5, // 旋转
    paintStyle: PaintingStyle.fill,
  );

  final circle2 = ShapeLayer.initial().copyWith(
    shapeType: ShapeType.circle,
    rect: const Rect.fromLTWH(800, 1200, 400, 400),
    color: const Color(0xFFFFA384).withOpacity(0.7),
    paintStyle: PaintingStyle.fill,
    scale: 0.8, // 缩放
  );
  return Template(background: background, contentLayers:  [circle1, rectangle1, circle2, mainText]);
}


/// 模板函数：复古海报风
/// 特点：通过色彩、字体和布局营造出怀旧的胶片海报感。
Template retroPosterTemplate(){
  final background = BackgroundLayer.initial().copyWith(
    color: const Color(0xFFFFF7E6), // 暖黄色复古背景
  );

  final largeText = TextLayer.initial().copyWith(
    text: 'HELLO',
    rect: const Rect.fromLTWH(50, 400, 980, 200),
    style: const TextStyle(
      fontSize: 160,
      color: Color(0xFF8F5F5F),
      fontFamily: AppFonts.cabinSketch, // 复古手绘字体
      fontWeight: FontWeight.w900,
      height: 1.0,
      letterSpacing: -5.0, // 紧凑字距
    ),
  );

  final subText = TextLayer.initial().copyWith(
    text: 'THE WORLD',
    rect: const Rect.fromLTWH(80, 580, 900, 100),
    style: const TextStyle(
      fontSize: 80,
      color: Color(0xFF8F5F5F),
      fontFamily: AppFonts.cabinSketch,
      fontWeight: FontWeight.w400,
      height: 1.0,
    ),
    hasStroke: true,
    strokeColor: Colors.black.withOpacity(0.2),
    strokeWidth: 1.5,
  );

  final decorativeShape = ShapeLayer.initial().copyWith(
    shapeType: ShapeType.rectangle,
    rect: const Rect.fromLTWH(120, 300, 840, 15),
    color: const Color(0xFF8F5F5F),
    paintStyle: PaintingStyle.fill,
    scale: 1.0,
    rotation: 0.0,
    isVisible: true,
    isLocked: false,
  );
  return Template(background: background, contentLayers: [background, decorativeShape, largeText, subText]);
}

/// 模板函数：赛博朋克风
/// 特点：深色背景、霓虹色调、未来感字体和错位效果。
Template cyberpunkTemplate(){
  final background = BackgroundLayer.initial().copyWith(
    gradient: LinearGradient(
      colors: [
        const Color(0xFF0D0D1A),
        const Color(0xFF1C1C30),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    setGradient: true,
  );

  final mainText = TextLayer.initial().copyWith(
    text: 'GLITCH',
    rect: const Rect.fromLTWH(200, 800, 600, 200),
    style: const TextStyle(
      fontSize: 140,
      color: Color(0xFF00FFF8), // 霓虹青色
      fontFamily: AppFonts.lxgwBright,
      fontWeight: FontWeight.w900,
      height: 1.0,
      letterSpacing: 10.0,
    ),
    hasStroke: true,
    strokeColor: Colors.black.withOpacity(0.2),
    strokeWidth: 4.0,
    rotation: -0.1,
  );

  // 模拟 glitch 效果的错位文本
  final glitchText = TextLayer.initial().copyWith(
    text: 'GLITCH',
    rect: const Rect.fromLTWH(205, 805, 600, 200),
    style: TextStyle(
      fontSize: 140,
      color: const Color(0xFFFF00B3).withOpacity(0.6), // 霓虹粉色
      fontFamily: AppFonts.lxgwBright,
      fontWeight: FontWeight.w900,
      height: 1.0,
      letterSpacing: 10.0,
    ),
    rotation: -0.1,
  );

  final shapeLine = ShapeLayer.initial().copyWith(
    shapeType: ShapeType.rectangle,
    rect: const Rect.fromLTWH(200, 1000, 600, 5),
    color: const Color(0xFF00FFF8),
    paintStyle: PaintingStyle.fill,
    rotation: -0.1,
  );

  return Template(background: background, contentLayers: [background, mainText, glitchText, shapeLine]);
}
enum TemplateEnum {
  modern(modernMinimalistTemplate, '现代简约'),
  sunset(sunsetGradientTemplate, '日落渐变'),
  emoji(playfulEmojiTemplate, '活泼可爱'),
  tech(techTitleTemplate, '科技感标题'),
  abstract(abstractGeometryTemplate,'抽象几何风'),
  retro(retroPosterTemplate,'复古海报风'),
  cyberpunk(cyberpunkTemplate,'赛博朋克风'),
  blank(blankTemplate, '空白模版');

  final Template Function() builder;
  final String label;

  const TemplateEnum(this.builder, this.label);
}