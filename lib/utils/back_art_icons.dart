import 'package:flutter/cupertino.dart';

class PlatformAdaptiveIcons implements BackArtIcons {
  const PlatformAdaptiveIcons._();
}

class BackArtIcons {
  BackArtIcons._();
  static PlatformAdaptiveIcons get adaptive => const PlatformAdaptiveIcons._();
  static const IconData topLeft = IconData(0xe939, fontFamily: "BackArt");
  static const IconData topCenter = IconData(0xe929, fontFamily: "BackArt");
  static const IconData topRight = IconData(0xe947, fontFamily: "BackArt");
  static const IconData bottomLeft = IconData(0xe91b, fontFamily: "BackArt");
  static const IconData bottomCenter = IconData(0xe900, fontFamily: "BackArt");
  static const IconData bottomRight = IconData(0xe90c, fontFamily: "BackArt");
  static Map<String, IconData> iconMap = {
    "topLeft": topLeft,
    "topCenter": topCenter,
    "topRight": topRight,
    "bottomLeft": bottomLeft,
    "bottomCenter": bottomCenter,
    "bottomRight": bottomRight,
  };
}
