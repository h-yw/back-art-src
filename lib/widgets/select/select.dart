import 'package:BackArt/widgets/icon_image/icon_image.dart';
import 'package:flutter/material.dart';

import '../../utils/camel_to_snake.dart';

class Select extends StatefulWidget {
  const Select(
      {Key? key,
      required this.onSelect,
      required this.items,
      this.value,
      this.height = 40,
      this.borderRadius = const BorderRadius.all(Radius.circular(4))})
      : super(key: key);
  final double height;
  final BorderRadius borderRadius;
  final ValueChanged<String> onSelect;
  final List<String> items;
  final dynamic value;
  @override
  State<StatefulWidget> createState() => _SelectState();
}

class _SelectState extends State<Select> with SingleTickerProviderStateMixin {
  final MenuController _menuController = MenuController();
  final TextEditingController _textController = TextEditingController();
  late dynamic _currentVal;
  @override
  void initState() {
    super.initState();
    _currentVal = widget.value!;
  }

  @override
  void didUpdateWidget(Select oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      setState(() {
        _currentVal = widget.value!;
      });
      _menuController.close();
    }
  }

  _onSelect(String val) {
    widget.onSelect(val);
    _textController.text = val;
    setState(() {
      // print("set====>${val}");
      _currentVal = val;
    });
    _menuController.close();
  }

  List<Widget> _buildMenu() {
    return widget.items
        .map(
          (e) => GestureDetector(
              onTap: () {
                _onSelect(e);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                child: IconImage(
                  colorFilter: _currentVal == e
                      ? ColorFilter.mode(
                          Theme.of(context).primaryColor, BlendMode.srcIn)
                      : null,
                  assetName: "assets/icons/${camelToSnake(e)}.svg",
                  size: 40,
                ),
              )),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _menuController,
      builder: (context, controller, child) {
        return GestureDetector(
          onTap: () {
            controller.isOpen ? controller.close() : controller.open();
          },
          child: child,
        );
      },
      menuChildren: _buildMenu(),
      child: Container(
          // height: widget.height,
          // height: 40,
          // padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: const BorderRadius.all(Radius.circular(4.0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconImage(
                  size: 40,
                  assetName: "assets/icons/${camelToSnake(_currentVal)}.svg"),
            ],
          )),
    );
  }
}
