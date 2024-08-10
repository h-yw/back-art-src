import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      background: Colors.white,
      onBackground: Colors.white,
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
      /* primaryFixed: Color(4292273151),
      onPrimaryFixed: Color(4278197054),
      primaryFixedDim: Color(4289382399),
      onPrimaryFixedVariant: Color(4279846531),
      secondaryFixed: Color(4292273151),
      onSecondaryFixed: Color(4279049266),
      secondaryFixedDim: Color(4290365413),
      onSecondaryFixedVariant: Color(4282009440),
      tertiaryFixed: Color(4294956798),
      onTertiaryFixed: Color(4281663806),
      tertiaryFixedDim: Color(4294095093),
      onTertiaryFixedVariant: Color(4284953197),
      surfaceDim: Color(4292532703),
      surfaceBright: Color(4294572543),
      surfaceContainerLowest: Color(4294967295),
      surfaceContainerLow: Color(4294177785),
      surfaceContainer: Color(4293848563),
      surfaceContainerHigh: Color(4293453805),
      surfaceContainerHighest: Color(4293059304),*/
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      background: Colors.white,
      onBackground: Colors.white,
      brightness: Brightness.light,
      primary: Color(0xff12427f),
      surfaceTint: Color(0xff365e9d),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff4e75b5),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff36435c),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff677590),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff622e69),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff99609f),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff8c0009),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffda342e),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff9f9ff),
      onSurface: Color(0xff1a1c20),
      onSurfaceVariant: Color(0xff3f434c),
      outline: Color(0xff5b5f69),
      outlineVariant: Color(0xff777b85),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2f3035),
      inversePrimary: Color(0xffaac7ff),
      /* primaryFixed: Color(4283332021),
      onPrimaryFixed: Color(4294967295),
      primaryFixedDim: Color(4281556122),
      onPrimaryFixedVariant: Color(4294967295),
      secondaryFixed: Color(4284970384),
      onSecondaryFixed: Color(4294967295),
      secondaryFixedDim: Color(4283391094),
      onSecondaryFixedVariant: Color(4294967295),
      tertiaryFixed: Color(4288241823),
      onTertiaryFixed: Color(4294967295),
      tertiaryFixedDim: Color(4286465924),
      onTertiaryFixedVariant: Color(4294967295),
      surfaceDim: Color(4292532703),
      surfaceBright: Color(4294572543),
      surfaceContainerLowest: Color(4294967295),
      surfaceContainerLow: Color(4294177785),
      surfaceContainer: Color(4293848563),
      surfaceContainerHigh: Color(4293453805),
      surfaceContainerHighest: Color(4293059304),*/
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      background: Colors.white,
      onBackground: Colors.white,
      brightness: Brightness.light,
      primary: Color(0xff00214a),
      surfaceTint: Color(0xff365e9d),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff12427f),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff142239),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff36435c),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff3d0846),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff622e69),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff4e0002),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff8c0009),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff9f9ff),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff20242c),
      outline: Color(0xff3f434c),
      outlineVariant: Color(0xff3f434c),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2f3035),
      inversePrimary: Color(0xffe5ecff),
      /*primaryFixed: Color(4279386751),
      onPrimaryFixed: Color(4294967295),
      primaryFixedDim: Color(4278201438),
      onPrimaryFixedVariant: Color(4294967295),
      secondaryFixed: Color(4281746268),
      onSecondaryFixed: Color(4294967295),
      secondaryFixedDim: Color(4280233285),
      onSecondaryFixedVariant: Color(4294967295),
      tertiaryFixed: Color(4284624489),
      onTertiaryFixed: Color(4294967295),
      tertiaryFixedDim: Color(4282979921),
      onTertiaryFixedVariant: Color(4294967295),
      surfaceDim: Color(4292532703),
      surfaceBright: Color(4294572543),
      surfaceContainerLowest: Color(4294967295),
      surfaceContainerLow: Color(4294177785),
      surfaceContainer: Color(4293848563),
      surfaceContainerHigh: Color(4293453805),
      surfaceContainerHighest: Color(4293059304),*/
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      background: Colors.black,
      onBackground: Colors.black,
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
      surface: Color(0xff121317),
      onSurface: Color(0xffe2e2e8),
      onSurfaceVariant: Color(0xffc3c6d2),
      outline: Color(0xff8d909b),
      outlineVariant: Color(0xff434750),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe2e2e8),
      inversePrimary: Color(0xff365e9d),
      /* primaryFixed: Color(4292273151),
      onPrimaryFixed: Color(4278197054),
      primaryFixedDim: Color(4289382399),
      onPrimaryFixedVariant: Color(4279846531),
      secondaryFixed: Color(4292273151),
      onSecondaryFixed: Color(4279049266),
      secondaryFixedDim: Color(4290365413),
      onSecondaryFixedVariant: Color(4282009440),
      tertiaryFixed: Color(4294956798),
      onTertiaryFixed: Color(4281663806),
      tertiaryFixedDim: Color(4294095093),
      onTertiaryFixedVariant: Color(4284953197),
      surfaceDim: Color(4279374615),
      surfaceBright: Color(4281874750),
      surfaceContainerLowest: Color(4278980114),
      surfaceContainerLow: Color(4279901216),
      surfaceContainer: Color(4280164388),
      surfaceContainerHigh: Color(4280822318),
      surfaceContainerHighest: Color(4281546041),*/
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      background: Colors.black,
      onBackground: Colors.black,
      brightness: Brightness.dark,
      primary: Color(0xffb1cbff),
      surfaceTint: Color(0xffaac7ff),
      onPrimary: Color(0xff001634),
      primaryContainer: Color(0xff6e94d6),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffbdcbe9),
      onSecondary: Color(0xff07162d),
      secondaryContainer: Color(0xff8391ad),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xfff7b4fa),
      onTertiary: Color(0xff2d0035),
      tertiaryContainer: Color(0xffbc7fc0),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffbab1),
      onError: Color(0xff370001),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff121317),
      onSurface: Color(0xfffbfaff),
      onSurfaceVariant: Color(0xffc7cad6),
      outline: Color(0xff9fa3ae),
      outlineVariant: Color(0xff7f838d),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe2e2e8),
      inversePrimary: Color(0xff1a4785),
      /*  primaryFixed: Color(4292273151),
      onPrimaryFixed: Color(4278194475),
      primaryFixedDim: Color(4289382399),
      onPrimaryFixedVariant: Color(4278203759),
      secondaryFixed: Color(4292273151),
      onSecondaryFixed: Color(4278391079),
      secondaryFixedDim: Color(4290365413),
      onSecondaryFixedVariant: Color(4280890959),
      tertiaryFixed: Color(4294956798),
      onTertiaryFixed: Color(4280614956),
      tertiaryFixedDim: Color(4294095093),
      onTertiaryFixedVariant: Color(4283703387),
      surfaceDim: Color(4279374615),
      surfaceBright: Color(4281874750),
      surfaceContainerLowest: Color(4278980114),
      surfaceContainerLow: Color(4279901216),
      surfaceContainer: Color(4280164388),
      surfaceContainerHigh: Color(4280822318),
      surfaceContainerHighest: Color(4281546041),*/
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      background: Colors.black,
      onBackground: Colors.black,
      brightness: Brightness.dark,
      primary: Color(0xfffbfaff),
      surfaceTint: Color(0xffaac7ff),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xffb1cbff),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xfffbfaff),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffbdcbe9),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xfffff9fa),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xfff7b4fa),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xfffff9f9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffbab1),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff121317),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xfffbfaff),
      outline: Color(0xffc7cad6),
      outlineVariant: Color(0xffc7cad6),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe2e2e8),
      inversePrimary: Color(0xff002959),
      /*primaryFixed: Color(4292732927),
      onPrimaryFixed: Color(4278190080),
      primaryFixedDim: Color(4289842175),
      onPrimaryFixedVariant: Color(4278195764),
      secondaryFixed: Color(4292732927),
      onSecondaryFixed: Color(4278190080),
      secondaryFixedDim: Color(4290628585),
      onSecondaryFixedVariant: Color(4278654509),
      tertiaryFixed: Color(4294958333),
      onTertiaryFixed: Color(4278190080),
      tertiaryFixedDim: Color(4294423802),
      onTertiaryFixedVariant: Color(4281139253),
      surfaceDim: Color(4279374615),
      surfaceBright: Color(4281874750),
      surfaceContainerLowest: Color(4278980114),
      surfaceContainerLow: Color(4279901216),
      surfaceContainer: Color(4280164388),
      surfaceContainerHigh: Color(4280822318),
      surfaceContainerHighest: Color(4281546041),*/
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
        useMaterial3: true,
        brightness: colorScheme.brightness,
        colorScheme: colorScheme,
        textTheme: textTheme.apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        ),
        scaffoldBackgroundColor: colorScheme.background,
        canvasColor: colorScheme.surface,
      );

  List<ExtendedColor> get extendedColors => [];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
