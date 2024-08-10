class ImageAssetsStore {
  // 图标路径
  static const String _iconPath = 'assets/icons/';
  static const String _imagePath = 'assets/images/';

  // 图标资源
  static const String topLeft = '${_iconPath}top_left.svg';
  static const String topRight = '${_iconPath}top_right.svg';
  static const String bottomLeft = '${_iconPath}bottom_left.svg';
  static const String bottomRight = '${_iconPath}bottom_right.svg';
  static const String topCenter = '${_iconPath}top_center.svg';
  static const String bottomCenter = '${_iconPath}bottom_center.svg';
  static const String center = '${_iconPath}center.svg';
  static const String centerLeft= '${_iconPath}center_left.svg';
  static const String centerRight = '${_iconPath}center_right.svg';
  static const String githubMark = '${_iconPath}github-mark.png';
  static const String githubMarkWhite = '${_iconPath}github-mark-white.png';
  static const String wxPay = '${_imagePath}wechat_pay.jpg';
  static const String wxTip = '${_imagePath}wechat_tip.jpg';

  static String?  getImage(String name) {
    switch (name) {
      case 'topLeft':
        return topLeft;
      case 'topRight':
        return topRight;
      case 'bottomLeft':
        return bottomLeft;
      case 'bottomRight':
        return bottomRight;
      case 'topCenter':
        return topCenter;
      case 'bottomCenter':
        return bottomCenter;
      case 'center':
        return center;
      case 'centerLeft':
        return centerLeft;
      case 'centerRight':
        return centerRight;
      case 'githubMark':
        return githubMark;
    }
    return null;
  }
}
