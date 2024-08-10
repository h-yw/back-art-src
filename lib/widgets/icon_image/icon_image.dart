import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IconImage extends StatelessWidget {
  final String assetName;
  final double size;
  final String semanticsLabel;
  final ColorFilter? colorFilter;
  // final Color color;
  final double padding;

  const IconImage({
    Key? key,
    required this.assetName,
    this.size = 24,
    this.padding = 0,
    this.semanticsLabel = '',
    this.colorFilter,
  }) : super(key: key);

  // 判断图片类型，是svg还是png
  bool get isSvg => assetName.endsWith(".svg");

  // 判断图片是否是网络图片
  bool get isNetwork => assetName.startsWith("http");

  Widget _buildImage() {
    return SvgPicture.asset(
      assetName,
      width: size,
      height: size,
      semanticsLabel: semanticsLabel,
      // fit: BoxFit.fill,
      colorFilter: colorFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildImage();
  }
}
