import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:BackArt/config/platform.dart';
import 'package:BackArt/main.dart';
import 'package:BackArt/pages/created/painter.dart';
import 'package:BackArt/utils/gradients.dart';
import 'package:BackArt/utils/image_assets.dart';
import 'package:BackArt/utils/launch_url.dart';
import 'package:BackArt/utils/position.dart';
import 'package:BackArt/widgets/select/select.dart';
import 'package:BackArt/widgets/select_filed/select_filed.dart';
import 'package:BackArt/widgets/slide_picker/slide_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../../config/font_list.dart';
import '../../widgets/icon_image/icon_image.dart';

class Created extends StatefulWidget {
  const Created({super.key});

  @override
  State<StatefulWidget> createState() {
    return _Created();
  }
}

class _Created extends State<Created> {
  Map<String, dynamic> map = {
    "background": Colors.amber,
    "fontSize": 32.0,
    "text": "东方欲晓\n莫道君行早\n踏遍青山人未老\n风景那边独好\nI WILL BE OK\nBackArt",
    "fontFamily": "HanaMin",
    "size": null,
    "mark": "BackArt",
    "markPos": PositionEnum.bottomCenter,
    "align": TextAlign.left,
    "lineHeight": 1.0,
    "layout": PositionEnum.topLeft,
  };
  final _boundaryKey = GlobalKey();
  final _tabsKey = GlobalKey();
  late PersistentBottomSheetController colorSheetController;
  late TextEditingController textController =
      TextEditingController(text: map["text"]);
  late TextEditingController fontSizeController =
      TextEditingController(text: "${map["fontSize"]}");
  late TextEditingController markController =
      TextEditingController(text: map["mark"]);
  late TextEditingController linHeightController =
      TextEditingController(text: map["lineHeight"].toStringAsFixed(2));
  final GradientsGenerator gradientsGenerator = GradientsGenerator();
  int selectedSizeIdx = 0;
  Size? paintAreaSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_getSize);
  }

  void _getSize(_) {
    final RenderBox renderBox =
        _boundaryKey.currentContext!.findRenderObject() as RenderBox;
    final size = Size(renderBox.size.width, renderBox.size.height);
    setState(() {
      paintAreaSize = size;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (map["size"] == null) {
      map["size"] = Size(MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.height);
    }
    var win = MediaQuery.of(context).size;
    var paintArea = Size(MediaQuery.of(context).size.width - 32,
        MediaQuery.of(context).size.height - 32 - 60 - 10 - 20);
    var size = calculateScaledSize(
        originalSize: map["size"], targetSize: paintAreaSize ?? paintArea);
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          height: win.height,
          child: Column(
            children: [
              Container(
                width: size.width,
                height: size.height,
                // padding: EdgeInsets.all(16),
                decoration: BoxDecoration(boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3), // 阴影颜色
                    offset: const Offset(0, 4), // 阴影偏移量
                    blurRadius: 8, // 模糊半径
                    spreadRadius: 2, // 扩展半径
                  )
                ]),
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: LayoutBuilder(
                    builder: (ctx, box) {
                      return CustomPaint(
                        key: ValueKey(map["size"]),
                        size: map["size"],
                        painter: Painter(
                            map,
                            MediaQuery.of(context).devicePixelRatio,
                            paintAreaSize ?? paintArea),
                      );
                    },
                  ),
                ),
              ),
              const Expanded(child: SizedBox()),
              Container(
                padding: const EdgeInsets.only(bottom: 4),
                key: _tabsKey,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(85, 85, 85, 1), // 阴影颜色
                      offset: Offset(0, 4), // 阴影偏移量
                      blurRadius: 8, // 模糊半径
                      spreadRadius: 2, // 扩展半径
                    )
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    toolItemWidget(
                        title: context.l10n.nav_platform,
                        iconData: Icons.phone_android_outlined,
                        onPressed: () {
                          _onPlatform(context);
                        }),
                    toolItemWidget(
                      iconData: Icons.palette_outlined,
                      title: context.l10n.nav_color,
                      onPressed: () {
                        _onColor(context);
                      },
                    ),
                    toolItemWidget(
                        title: context.l10n.nav_text,
                        iconData: Icons.text_fields_outlined,
                        onPressed: () {
                          _onAddText(context);
                        }),
                    toolItemWidget(
                        title: context.l10n.nav_export,
                        iconData: Icons.download_outlined,
                        onPressed: () {
                          _onExport(context);
                        }),
                    toolItemWidget(
                        title: context.l10n.app_setting,
                        iconData: Icons.settings_outlined,
                        onPressed: () {
                          Navigator.pushNamed(context, "/setting");
                        })
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget toolItemWidget({
    required IconData iconData,
    title,
    onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              iconData,
              size: 28,
              color: Theme.of(context).primaryColor,
              weight: 0.5,
            ),
            const SizedBox(
              height: 2,
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ]),
    );
  }

  void _onPlatform(BuildContext context) {
    final sizeList = platformSize.keys
        .map((e) {
          final platform = platformSize[e]!.map((item) {
            item["platform"] = e;
            return item;
          });
          return platform;
        })
        .expand((element) => element)
        .toList();
    var size = Size(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
    sizeList.insert(0, {
      "name": "Current",
      "platform": Platform.operatingSystem,
      "size": size,
    });
    Widget widget = ListView.separated(
      restorationId: selectedSizeIdx.toString(),
      primary: true,
      padding: const EdgeInsets.only(bottom: 80),
      itemBuilder: (buildContext, idx) {
        return ListTile(
          // selectedColor: Colors.orange,
          // selected: idx == selectedSizeIdx,
          style: ListTileStyle.values[0],
          contentPadding: const EdgeInsets.only(left: 12),
          onTap: () {
            setState(() {
              selectedSizeIdx = idx;
            });
            map["size"] = Size(
                sizeList[idx]["size"].width /
                    MediaQuery.of(context).devicePixelRatio,
                sizeList[idx]["size"].height /
                    MediaQuery.of(context).devicePixelRatio); //;
          },
          dense: true,
          leading: Text(
            sizeList[idx]["platform"],
          ),
          title: Text(sizeList[idx]["name"]),
          subtitle: Text(
              "${sizeList[idx]["size"].width}X${sizeList[idx]["size"].height}"),
        );
      },
      itemCount: sizeList.length,
      separatorBuilder: (BuildContext context, int index) {
        return Divider(height: 1, color: Theme.of(context).highlightColor);
      },
    );
    _createBottomSheet(widget);
  }

  void _onColor(context) async {
    Widget widget = Container(
      padding: const EdgeInsets.all(16),
      // decoration: BoxDecoration(border: Border.all(width: 2)),
      child: Column(
        children: [
          SlidePicker(
            pickerColor: map["background"],
            onColorChanged: (color) {
              setState(() {
                map["background"] = color;
              });
            },
          ),
        ],
      ),
    );
    _createBottomSheet(widget);
  }

  void _onAddText(BuildContext context) async {
    Widget widget = Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 16),
      child: Column(
        children: [
          TextField(
            controller: textController,
            decoration: InputDecoration(
              isDense: true,
              hintText: context.l10n.hint_content,
              labelText: context.l10n.filed_content,
              contentPadding: const EdgeInsets.all(12),
              // fillColor: Colors.transparent,
              border: OutlineInputBorder(
                  // borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(8)),
              // filled: true,
            ),
            onChanged: (String val) {
              setState(() {
                map["text"] = val;
              });
            },
            minLines: 2,
            maxLines: 20,
            style: const TextStyle(
                fontSize: 14, height: 1.2, fontWeight: FontWeight.w500),
          ),
          const SizedBox(
            height: 8,
          ),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SelectFiled(
                  label: context.l10n.filed_align,
                  options: const [
                    SelectOption(
                        value: TextAlign.left,
                        label: Icon(
                          Icons.format_align_left,
                          size: 24,
                        )),
                    SelectOption(
                        value: TextAlign.center,
                        label: Icon(
                          Icons.format_align_center,
                          size: 24,
                        )),
                    SelectOption(
                        value: TextAlign.right,
                        label: Icon(
                          Icons.format_align_right,
                          size: 24,
                        )),
                  ],
                  onChanged: (val) {
                    setState(() {
                      map["align"] = val;
                    });
                  },
                  value: map.containsKey("align") ? map["align"] : null,
                ),
              ),
              SizedBox(
                width: 8,
              ),
              Expanded(
                flex: 1,
                child: SelectFiled(
                  placeholder: context.l10n.filed_layout,
                  label: context.l10n.filed_layout,
                  options: [
                    for (var item in PositionEnum.values.map((e) => e.name))
                      SelectOption(
                          value: AlignLayout.getPositionEnum(item),
                          label: IconImage(
                            assetName: ImageAssetsStore.getImage(item)!,
                            size: 32,
                          )),
                  ],
                  onChanged: (val) {
                    setState(() {
                      map["layout"] = val;
                    });
                  },
                  value: map.containsKey("layout") ? map["layout"] : null,
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: linHeightController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.only(
                          left: 12, right: 12, top: 15.5, bottom: 15.5),
                      border: OutlineInputBorder(),
                      labelText: context.l10n.filed_line_height,
                      suffixIcon: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                            border: Border(
                                left: BorderSide(
                                    color: Theme.of(context)
                                        .dividerColor
                                        .withOpacity(0.5),
                                    width: 1))),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: IconButton(
                                    padding: EdgeInsets.zero,
                                    style: ButtonStyle(
                                        padding: MaterialStateProperty.all(
                                            EdgeInsets.zero)),
                                    onPressed: () {
                                      setState(() {
                                        map["lineHeight"] += 0.05;
                                        linHeightController.text =
                                            map["lineHeight"]
                                                .toStringAsFixed(2);
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.arrow_drop_up_outlined,
                                      size: 24,
                                    )),
                              ),
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: IconButton(
                                    iconSize: 24,
                                    padding: EdgeInsets.zero,
                                    style: ButtonStyle(
                                        padding: MaterialStateProperty.all(
                                            EdgeInsets.zero)),
                                    onPressed: () {
                                      setState(() {
                                        if (map["lineHeight"] - 0.05 <= 1.0) {
                                          map["lineHeight"] = 1.00;
                                          linHeightController.text = "1.00";
                                        } else {
                                          map["lineHeight"] -= 0.05;
                                          linHeightController.text =
                                              map["lineHeight"]
                                                  .toStringAsFixed(2);
                                        }
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.arrow_drop_down_outlined,
                                      size: 24,
                                    )),
                              ),
                            ]),
                      )),
                  onChanged: (val) {
                    setState(() {
                      map["lineHeight"] = double.parse(val);
                    });
                  },
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          Row(
            children: [
              Expanded(
                  flex: 2,
                  child: SelectFiled(
                    label: context.l10n.filed_font_family,
                    onChanged: (val) {
                      setState(() {
                        map["fontFamily"] = val;
                      });
                    },
                    value: map["fontFamily"],
                    options: [
                      for (String name in fontNameList)
                        SelectOption(
                          value: name,
                          label: Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                      fontFamily: name,
                                      fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    //   测试英语
                                    Text(
                                      "BackArt",
                                      style: TextStyle(
                                          fontFamily: name,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color:
                                              Theme.of(context).disabledColor),
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    Text(
                                      "背景艺术",
                                      style: TextStyle(
                                          fontFamily: name,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color:
                                              Theme.of(context).disabledColor),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        )
                    ],
                  )),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: fontSizeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.only(
                          left: 12, right: 12, top: 15.5, bottom: 15.5),
                      border: const OutlineInputBorder(),
                      labelText: context.l10n.filed_font_size,
                      suffixIcon: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                            border: Border(
                                left: BorderSide(
                                    color: Theme.of(context)
                                        .dividerColor
                                        .withOpacity(0.5),
                                    width: 1))),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: IconButton(
                                    padding: EdgeInsets.zero,
                                    style: ButtonStyle(
                                        padding: MaterialStateProperty.all(
                                            EdgeInsets.zero)),
                                    onPressed: () {
                                      setState(() {
                                        map["fontSize"] += 1;
                                        fontSizeController.text =
                                            map["fontSize"].toString();
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.arrow_drop_up_outlined,
                                      size: 24,
                                    )),
                              ),
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: IconButton(
                                    iconSize: 24,
                                    padding: EdgeInsets.zero,
                                    style: ButtonStyle(
                                        padding: MaterialStateProperty.all(
                                            EdgeInsets.zero)),
                                    onPressed: () {
                                      setState(() {
                                        if (map["fontSize"] - 1 <= 0) {
                                          map["fontSize"] = 10;
                                          fontSizeController.text = "10";
                                        } else {
                                          map["fontSize"] -= 1;
                                          fontSizeController.text =
                                              map["fontSize"].toString();
                                        }
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.arrow_drop_down_outlined,
                                      size: 24,
                                    )),
                              ),
                            ]),
                      )),
                  onChanged: (val) {
                    setState(() {
                      map["fontSize"] = double.parse(val);
                    });
                  },
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: markController,
                  decoration: InputDecoration(
                      contentPadding: const EdgeInsets.fromLTRB(12, 13, 0, 13),
                      isDense: true,
                      prefixText: "@",
                      border: const OutlineInputBorder(),
                      labelText: context.l10n.filed_mark,
                      suffixIcon: Container(
                        // padding: EdgeInsets.only(right: 12),
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          border: Border(left: BorderSide(color: Colors.grey)),
                        ),
                        child: SelectFiled(
                          // label: "位置",
                          enabledBorder: InputBorder.none,
                          showArrow: false,
                          options: [
                            for (PositionEnum item in [
                              ...AlignLayout.getPosition(PositionType.top),
                              ...AlignLayout.getPosition(PositionType.bottom)
                            ])
                              SelectOption(
                                value: item,
                                label: IconImage(
                                  size: 32,
                                  assetName:
                                      ImageAssetsStore.getImage(item.name)!,
                                ),
                              )
                          ],
                          value: map["markPos"],
                          onChanged: (val) {
                            setState(() {
                              map["markPos"] = val;
                            });
                          },
                        ),
                      )),
                  onChanged: (val) {
                    setState(() {
                      map["mark"] = val;
                    });
                  },
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    _createBottomSheet(widget);
  }

  void _onExport(BuildContext context) async {
    try {
      showDialog(
          barrierDismissible: false,
          barrierColor:
              Theme.of(context).dialogBackgroundColor.withOpacity(0.5),
          context: context,
          builder: (builder) {
            return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "正在导出",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Theme.of(context).shadowColor,
                        decoration: TextDecoration.none),
                  ),
                ]);
          });
      final boundary = _boundaryKey.currentContext?.findRenderObject();
      if (boundary != null && boundary is RenderRepaintBoundary) {
        var scaled = calculateScaled(
            originalSize: map["size"], targetSize: paintAreaSize!);
        final image = await boundary.toImage(
            pixelRatio: MediaQuery.of(context).devicePixelRatio * 5 / scaled);
        ByteData? byteData =
            await image.toByteData(format: ImageByteFormat.png);
        if (byteData != null) {
          var res = await ImageGallerySaver.saveImage(
              byteData.buffer.asUint8List(),
              quality: 100,
              name: "back_art_${map["background"]}");
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              dismissDirection: DismissDirection.up,
              content: Text("保存成功"),
              action: SnackBarAction(
                  label: "查看",
                  onPressed: () {
                    print("res====>$res ");
                    // launchUri("geo:37.7749,-122.4194");
                    launchUri(res["filePath"]);
                  })));

          /*Fluttertoast.showToast(
              // ignore: use_build_context_synchronously
              msg: res?.isSuccess?context.l10n.save_success_msg:"保存失败",
              gravity: ToastGravity.CENTER);*/
        }
      }
      // });
    } catch (e) {
      // ignore: avoid_print
    }
  }

  void _createBottomSheet(Widget widget) {
    colorSheetController = showBottomSheet(
        backgroundColor: Colors.transparent,
        // isDismissible: true,
        elevation: 8,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        context: _tabsKey.currentContext!,
        // useSafeArea: true,
        builder: (buildContext) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: Container(
              height: MediaQuery.of(context).size.height / 2,
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12))),
              child: Stack(
                alignment: AlignmentDirectional.centerStart,
                children: [
                  Positioned(
                      top: 0,
                      right: 0,
                      height: 42,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 32,
                        ),
                        onPressed: () {
                          colorSheetController.close();
                        },
                        iconSize: 32,
                      )),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 40,
                    child: Divider(
                      color: Theme.of(context).cardColor,
                      height: 4,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 42,
                    height: MediaQuery.of(context).size.height / 2,
                    child: widget,
                  )
                ],
              ),
            ),
          );
        });
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

  double calculateScaled(
      {required Size originalSize, // 原始内容的大小
      required Size targetSize}) {
    // 计算缩放比例
    final double scaleX = targetSize.width / originalSize.width;
    final double scaleY = targetSize.height / originalSize.height;
    return scaleX < scaleY ? scaleX : scaleY; // 保持内容的比例
  }
}
