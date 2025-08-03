import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @app_name.
  ///
  /// In en, this message translates to:
  /// **'BackArt'**
  String get app_name;

  /// No description provided for @app_language.
  ///
  /// In en, this message translates to:
  /// **'language'**
  String get app_language;

  /// No description provided for @app_setting.
  ///
  /// In en, this message translates to:
  /// **'setting'**
  String get app_setting;

  /// No description provided for @nav_platform.
  ///
  /// In en, this message translates to:
  /// **'platform'**
  String get nav_platform;

  /// No description provided for @nav_color.
  ///
  /// In en, this message translates to:
  /// **'color'**
  String get nav_color;

  /// No description provided for @nav_text.
  ///
  /// In en, this message translates to:
  /// **'text'**
  String get nav_text;

  /// No description provided for @nav_export.
  ///
  /// In en, this message translates to:
  /// **'export'**
  String get nav_export;

  /// No description provided for @filed_content.
  ///
  /// In en, this message translates to:
  /// **'content'**
  String get filed_content;

  /// No description provided for @filed_font_family.
  ///
  /// In en, this message translates to:
  /// **'family'**
  String get filed_font_family;

  /// No description provided for @filed_font_size.
  ///
  /// In en, this message translates to:
  /// **'size'**
  String get filed_font_size;

  /// No description provided for @filed_mark.
  ///
  /// In en, this message translates to:
  /// **'mark'**
  String get filed_mark;

  /// No description provided for @hint_content.
  ///
  /// In en, this message translates to:
  /// **'Please enter the content'**
  String get hint_content;

  /// No description provided for @save_success_msg.
  ///
  /// In en, this message translates to:
  /// **'Save successfully'**
  String get save_success_msg;

  /// No description provided for @save_failed_msg.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get save_failed_msg;

  /// No description provided for @nav_about.
  ///
  /// In en, this message translates to:
  /// **'about'**
  String get nav_about;

  /// No description provided for @page_created.
  ///
  /// In en, this message translates to:
  /// **'created'**
  String get page_created;

  /// No description provided for @filed_align.
  ///
  /// In en, this message translates to:
  /// **'align'**
  String get filed_align;

  /// No description provided for @filed_layout.
  ///
  /// In en, this message translates to:
  /// **'layout'**
  String get filed_layout;

  /// No description provided for @filed_line_height.
  ///
  /// In en, this message translates to:
  /// **'height'**
  String get filed_line_height;

  /// No description provided for @page_setting.
  ///
  /// In en, this message translates to:
  /// **'settings'**
  String get page_setting;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
