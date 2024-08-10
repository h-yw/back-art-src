import 'package:flutter/material.dart';

class SelectFiled extends StatefulWidget {
  final String? label;
  final List<SelectOption> options;
  final dynamic value;
  final double? height;
  final InputBorder? enabledBorder;
  final BoxConstraints? constraints;
  final ValueChanged<dynamic> onChanged;
  final bool showArrow;
  final String placeholder;

  const SelectFiled({
    Key? key,
    required this.options,
    required this.onChanged,
    this.value,
    this.label,
    this.height = 40,
    this.constraints,
    this.enabledBorder,
    this.showArrow = true,
    this.placeholder = "请选择",
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SelectFiledState();
  }
}

class _SelectFiledState extends State<SelectFiled> {
  final TextEditingController _controller = TextEditingController();
  final MenuController _menuController = MenuController();
  final textKey = GlobalKey(debugLabel: 'select_field_key');
  final _focusNode = FocusNode();
  late dynamic currentValue;
  SelectOption? currentOption;
  bool isOpen = false;

  @override
  void initState() {
    super.initState();
    currentValue = widget.value ?? "";
    _controller.text = currentValue.toString();
    if (widget.value != null) {
      print("widget====>${widget.value}");
      currentOption = widget.options.firstWhere((e) => e.value == widget.value);
    }
  }

  @override
  void didUpdateWidget(covariant SelectFiled oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onChanged(SelectOption option) {
    _controller.text = option.value.toString();
    setState(() {
      currentValue = option.value;
      currentOption = option;
      // _controller
    });
    _menuController.close();
    widget.onChanged(option.value);
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: MenuStyle(
          maximumSize: MaterialStateProperty.all(const Size.fromHeight(200)),
          padding: MaterialStateProperty.all(EdgeInsets.zero)),
      crossAxisUnconstrained: false,
      controller: _menuController,
      builder: (context, controller, child) {
        return Container(
          child: GestureDetector(
            onTap: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
              // FocusScope.of(context).requestFocus(_focusNode);
            },
            child: AbsorbPointer(
              child: TextField(
                focusNode: _focusNode,
                key: textKey,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.transparent),
                controller: _controller,
                maxLines: 1,
                decoration: InputDecoration(
                    constraints: BoxConstraints(minWidth: 0, maxWidth: 0),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    isDense: true,
                    label: widget.label != null ? Text(widget.label!) : null,
                    // border: const OutlineInputBorder(),
                    enabledBorder: widget.enabledBorder ??
                        OutlineInputBorder(
                            borderSide: isOpen
                                ? BorderSide(
                                    width: 2,
                                    color: Theme.of(context).primaryColor)
                                : const BorderSide(color: Colors.grey)),
                    suffixIcon: widget.showArrow
                        ? Icon(
                            isOpen
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down,
                            color:
                                isOpen ? Theme.of(context).primaryColor : null,
                          )
                        : null,
                    prefixIcon: currentOption != null
                        ? currentOption?.label
                        : Text(
                      widget.placeholder,
                      style: TextStyle(
                          color: Theme.of(context).disabledColor),
                    ),
                    labelStyle: TextStyle(
                        color: isOpen
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                        fontWeight: FontWeight.w500),
                    filled: false),
              ),
            ),
          ),
        );
      },
      menuChildren: [
        for (SelectOption option in widget.options)
          GestureDetector(
            child: DefaultTextStyle(
              style: currentValue == option.value
                  ? TextStyle(color: Theme.of(context).primaryColor)
                  : const TextStyle(color: Colors.black),
              child: Container(
                  // width: double.infinity,
                  decoration: BoxDecoration(
                      // color: Colors.black54
                      border: widget.options.last.value == option.value
                          ? null
                          : Border(
                              bottom: BorderSide(
                                  width: 0.5,
                                  color: Theme.of(context).highlightColor),
                            )),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: option),
            ),
            onTap: () {
              _onChanged(option);
            },
          )
      ],
      onClose: () {
        setState(() {
          isOpen = false;
        });
      },
      onOpen: () {
        setState(() {
          isOpen = true;
          FocusScope.of(context).unfocus();
        });
      },
    );
  }
}

class SelectOption extends StatelessWidget {
  final Widget label;
  final dynamic value;

  const SelectOption({Key? key, required this.value, required this.label})
      : super(key: key);

  // label和labelWidget必须有一个

  @override
  Widget build(BuildContext context) {
    // assert(label != null || labelWidget != null);
    return  SizedBox(width: double.infinity,child: label);
  }
}
