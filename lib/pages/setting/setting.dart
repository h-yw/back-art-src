import 'package:BackArt/main.dart';
import 'package:BackArt/model/setting.dart';
import 'package:BackArt/utils/image_assets.dart';
import 'package:BackArt/widgets/select_filed/select_filed.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';

import '../../utils/launch_url.dart';

class Setting extends StatefulWidget {
  final ValueChanged<Locale> onLocaleChanged;

  const Setting({Key? key, required this.onLocaleChanged}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  String? _appName = "";
  String? _packageName = "";
  String? _version = "";
  String? _buildNumber = "";

  _onLocaleChanged(code) {
    context.settingDb.updateOrInsert({
      SettingModel.languageField: code,
    }).then((value) {
      widget.onLocaleChanged(Locale(code));
    });
  }

  Future<void> _inintPackageInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appName = packageInfo.appName;
      _packageName = packageInfo.packageName;
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  @override
  void initState() {
    super.initState();
    _inintPackageInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.app_setting),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(child: _settingWidget()),
            Positioned(
                bottom: 16,
                left: 12,
                right: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        launchUri("https://hlovez.life");
                      },
                      icon: const Icon(
                        Icons.face,
                        size: 16,
                        color: Colors.black,
                      ),
                      label: const Text(
                        "houyw",
                      ),
                      style: ButtonStyle(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: MaterialStateProperty.all(EdgeInsets.zero),
                        textStyle: MaterialStateProperty.all(TextStyle(
                          color: Theme.of(context).primaryColor,
                        )),
                        enableFeedback: false,
                        shape:
                            MaterialStateProperty.all(RoundedRectangleBorder()),
                        minimumSize: MaterialStateProperty.all(
                          Size(0, 0),
                        ),
                      ),
                    ),
                    /*const SizedBox(
                      height: 8,
                    ),
                    TextButton.icon(
                      onPressed: () {
                        launchUri("mailto:1327603193@qq.com");
                      },
                      label: const Text("1327603193@qq.com"),
                      icon: Icon(
                        Icons.email_outlined,
                        size: 16,
                        color: Colors.black,
                      ),
                      style: ButtonStyle(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: MaterialStateProperty.all(EdgeInsets.zero),
                          textStyle: MaterialStateProperty.all(
                            TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          shape: MaterialStateProperty.all(
                              RoundedRectangleBorder()),
                          minimumSize: MaterialStateProperty.all(
                            Size(0, 0),
                          )),
                    ),*/
                    const SizedBox(
                      height: 8,
                    ),
                    TextButton.icon(
                      onPressed: () {
                        launchUri("https://github.com/h-yw");
                      },
                      icon: Image.asset(ImageAssetsStore.githubMark,
                          width: 16, height: 16),
                      label: const Text("https://github.com/h-yw"),
                      style: ButtonStyle(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: MaterialStateProperty.all(EdgeInsets.zero),
                          textStyle: MaterialStateProperty.all(
                            TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          shape: MaterialStateProperty.all(
                              RoundedRectangleBorder()),
                          minimumSize: MaterialStateProperty.all(
                            Size(0, 0),
                          )),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      "版本: $_version-$_buildNumber",
                      style: TextStyle(color: Theme.of(context).disabledColor),
                    )
                  ],
                ))
          ],
        ),
      ),
    );
  }

  Widget _settingWidget() {
    return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemBuilder: (BuildContext context, int index) {
          return Row(
            children: [
              const Icon(Icons.language_rounded),
              const SizedBox(
                width: 8,
              ),
              Text(context.l10n.app_language),
              const Spacer(),
              SizedBox(
                width: 150,
                child: SelectFiled(
                  value: Localizations.localeOf(context).languageCode,
                  options: const [
                    SelectOption(
                        label: Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text("中文"),
                          ),
                        ),
                        value: "zh"),
                    SelectOption(
                        label: Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text("English"),
                            )),
                        value: "en"),
                  ],
                  onChanged: _onLocaleChanged,
                ),
              )
            ],
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return const Divider();
        },
        itemCount: 1);
  }
}
