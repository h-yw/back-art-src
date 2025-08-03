import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:BackArt/features/editor/view/editor_screen.dart';
import 'package:BackArt/theme/theme.dart'; // Import the simplified theme file
import 'package:BackArt/l10n/app_localizations.dart';
import 'package:BackArt/db/db_manager.dart';

void main() async {
  // Ensure that widget binding is initialized for async calls before runApp
  WidgetsFlutterBinding.ensureInitialized();
  // Wait for the database to be ready
  await DbManager.initialize();
  runApp(const ProviderScope(child: BackArtApp()));
}

class BackArtApp extends StatelessWidget {
  const BackArtApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) {
        return AppLocalizations.of(context)!.app_name;
      },
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      // Use the pre-defined M3 themes directly
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.light,

      home: EditorScreen(),
    );
  }
}