import 'dart:async';

import 'package:BackArt/db/db_manager.dart';
import 'package:BackArt/db/setting_db.dart';
import 'package:BackArt/model/setting.dart';
import 'package:BackArt/pages/setting/setting.dart';
import 'package:BackArt/pages/created/created.dart';
import 'package:BackArt/theme/theme.dart';
import 'package:BackArt/theme/util.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await DbManager.forFeature();
  var setting = await SettingDb.instance().getSettings();
  runApp(BackArt(setting: setting));

  // 这种模式不现实状态栏
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
      overlays: [SystemUiOverlay.top]);
// 这种模式显示状态栏
//   SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
// // 修改状态栏颜色(只能黑和白)
//   SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
}

extension BuildContextExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
  SettingDb get settingDb => SettingDb.instance();
}

class BackArt extends StatefulWidget {
  final SettingModel? setting;
  const BackArt({super.key, this.setting});
  @override
  State<StatefulWidget> createState() => _BackArt();
}

class _BackArt extends State<BackArt> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  // This widget is the root of your application.
  late String? languageCode = widget.setting?.language;
  late Locale? _locale = languageCode != null ? Locale(languageCode!) : null;
  // QuickActions quickActions = const QuickActions();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    // initializeQuickActions();
    super.initState();
    initDeepLinks();
    FlutterNativeSplash.remove();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle links
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('onAppLink: $uri');
      openAppLink(uri);
    });
  }

  void openAppLink(Uri uri) {

    // uri.host
    var named = "/${uri.host.isNotEmpty?"${uri.host}":''}";
    print('named====>: ${named}');
    _navigatorKey.currentState?.pushNamed(named);
  }

  /* initializeQuickActions() {
    quickActions.initialize((type) {
      switch (type) {
        case "created":
          Navigator.pushNamed(context, '/');
          break;
        case "setting":
          Navigator.pushNamed(context, '/setting');
          break;
      }
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'created',
        localizedTitle: "制作",
        icon: 'ic_created',
      ),
      const ShortcutItem(
        type: 'setting',
        localizedTitle: "设置",
        icon: 'ic_setting',
      ),
    ]);
  } */

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = createTextTheme(context, "Actor", "Alumni Sans");

    MaterialTheme theme = MaterialTheme(textTheme);
    return MaterialApp(
      navigatorKey: _navigatorKey,
      onGenerateTitle: (context) {
        return context.l10n.app_name;
      }, // Set the default locale,
      // title: AppLocalizations.of(context)!.title,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      localeListResolutionCallback: (locales, supportedLocales) {
        if (locales?[0].languageCode == "zh") {
          return const Locale('zh');
        }
        if (locales?[0].languageCode == "en") {
          return const Locale('en');
        }
        return const Locale('zh');
      },
      theme: theme.light(),
      locale: _locale,
      routes: {
        '/': (context) => const AnnotatedRegion(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: Brightness.light,
              statusBarIconBrightness: Brightness.light,
            ),
            child: Created()),
        '/setting': (context) => Setting(
              onLocaleChanged: _changeLocale,
            ),
      },
    );
  }

  void _changeLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }
}
