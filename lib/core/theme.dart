import 'package:flutter/material.dart';

class AppTheme {
  static const MaterialColor orangeMaterial = MaterialColor(
    _orangePrimaryValue,
    <int, Color>{
      50: Color(0xFFFFF3E0),
      100: Color(0xFFFFE0B2),
      200: Color(0xFFFFCC80),
      300: Color(0xFFFFB74D),
      400: Color(0xFFFFA726),
      500: Color(_orangePrimaryValue),
      600: Color(0xFFFB8C00),
      700: Color(0xFFF57C00),
      800: Color(0xFFEF6C00),
      900: Color(0xFFE65100),
    },
  );
  static const int _orangePrimaryValue = 0xFFFF9800;

  static final ThemeData lightTheme = ThemeData(
    primarySwatch: orangeMaterial,
    primaryColor: const Color(_orangePrimaryValue),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(_orangePrimaryValue),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    colorScheme: ColorScheme.fromSwatch(primarySwatch: orangeMaterial)
        .copyWith(secondary:  Color(0xFFFF9800)),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(_orangePrimaryValue),
    ),
  );
}
