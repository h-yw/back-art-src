import 'package:flutter/material.dart';

// Pre-defined M3 light color scheme
const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xff365e9d),
  surfaceTint: Color(0xff365e9d),
  onPrimary: Color(0xffffffff),
  primaryContainer: Color(0xff82a8ec),
  onPrimaryContainer: Color(0xff001c40),
  secondary: Color(0xff515f79),
  onSecondary: Color(0xffffffff),
  secondaryContainer: Color(0xffd9e4ff),
  onSecondaryContainer: Color(0xff3c4962),
  tertiary: Color(0xff814a87),
  onTertiary: Color(0xffffffff),
  tertiaryContainer: Color(0xffd091d4),
  onTertiaryContainer: Color(0xff36013f),
  error: Color(0xffba1a1a),
  onError: Color(0xffffffff),
  errorContainer: Color(0xffffdad6),
  onErrorContainer: Color(0xff410002),
  surface: Color(0xfff9f9ff),
  onSurface: Color(0xff1a1c20),
  onSurfaceVariant: Color(0xff434750),
  outline: Color(0xff737781),
  outlineVariant: Color(0xffc3c6d2),
  shadow: Color(0xff000000),
  scrim: Color(0xff000000),
  inverseSurface: Color(0xff2f3035),
  inversePrimary: Color(0xffaac7ff),
);

// Pre-defined M3 dark color scheme
const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xffaac7ff),
  surfaceTint: Color(0xffaac7ff),
  onPrimary: Color(0xff002f64),
  primaryContainer: Color(0xff6e94d6),
  onPrimaryContainer: Color(0xff000000),
  secondary: Color(0xffb9c7e5),
  onSecondary: Color(0xff233148),
  secondaryContainer: Color(0xff323f58),
  onSecondaryContainer: Color(0xffc6d4f3),
  tertiary: Color(0xfff2b0f5),
  onTertiary: Color(0xff4d1a55),
  tertiaryContainer: Color(0xffbc7fc0),
  onTertiaryContainer: Color(0xff000000),
  error: Color(0xffffb4ab),
  onError: Color(0xff690005),
  errorContainer: Color(0xff93000a),
  onErrorContainer: Color(0xffffdad6),
  surface: Color(0xff1a1c20),
  onSurface: Color(0xffe2e2e8),
  onSurfaceVariant: Color(0xffc3c6d2),
  outline: Color(0xff8d909b),
  outlineVariant: Color(0xff434750),
  shadow: Color(0xff000000),
  scrim: Color(0xff000000),
  inverseSurface: Color(0xffe2e2e8),
  inversePrimary: Color(0xff365e9d),
);

// Create a base TextTheme with a default font
final TextTheme baseTextTheme = ThemeData.light().textTheme.apply(
      fontFamily: 'OppoSans', // Set default font
    );

// Create ThemeData instances from the color scheme and apply the text theme
final lightTheme = ThemeData.from(
  colorScheme: lightColorScheme,
  textTheme: baseTextTheme.apply(bodyColor: lightColorScheme.onSurface),
  useMaterial3: true,
);

final darkTheme = ThemeData.from(
  colorScheme: darkColorScheme,
  textTheme: baseTextTheme.apply(bodyColor: darkColorScheme.onSurface),
  useMaterial3: true,
);