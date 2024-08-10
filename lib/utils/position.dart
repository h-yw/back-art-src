enum PositionEnum {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

enum PositionType {
  top,
  bottom,
  left,
  right,
  center,
}

class AlignLayout {
  static PositionEnum getPositionEnum(String position) {
    switch (position) {
      case "topLeft":
        return PositionEnum.topLeft;
      case "topRight":
        return PositionEnum.topRight;
      case "bottomLeft":
        return PositionEnum.bottomLeft;
      case "bottomRight":
        return PositionEnum.bottomRight;
      case "topCenter":
        return PositionEnum.topCenter;
      case "bottomCenter":
        return PositionEnum.bottomCenter;
      case "center":
        return PositionEnum.center;
      case "centerLeft":
        return PositionEnum.centerLeft;
      case "centerRight":
        return PositionEnum.centerRight;
      default:
        return PositionEnum.topLeft;
    }
  }

  static List<PositionEnum> getPosition(PositionType position) {
    switch (position) {
      case PositionType.top:
        return [
          PositionEnum.topLeft,
          PositionEnum.topCenter,
          PositionEnum.topRight,
        ];
      case PositionType.center:
        return [
          PositionEnum.centerLeft,
          PositionEnum.center,
          PositionEnum.centerRight,
        ];
      case PositionType.bottom:
        return [
          PositionEnum.bottomLeft,
          PositionEnum.bottomCenter,
          PositionEnum.bottomRight,
        ];
      case PositionType.left:
        return [
          PositionEnum.topLeft,
          PositionEnum.bottomLeft,
          PositionEnum.centerLeft,
        ];
      case PositionType.right:
        return [
          PositionEnum.topRight,
          PositionEnum.bottomRight,
          PositionEnum.centerRight,
        ];
    }
  }
}
