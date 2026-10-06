import 'package:flutter/material.dart';

const campusMateOrange = Color(0xFFE64A19);

final campusMateLightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: campusMateOrange, brightness: Brightness.light).copyWith(surface: const Color(0xFFFFF8F4)),
  scaffoldBackgroundColor: const Color(0xFFFFF8F4),
  appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFFFF8F4)),
  cardTheme: const CardThemeData(color: Colors.white, elevation: 0),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFFFFEFD),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: Color(0xFFEAD9D1)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: Color(0xFFEAD9D1)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: campusMateOrange, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: Color(0xFFBA1A1A)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  ),
);

final campusMateDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(seedColor: campusMateOrange, brightness: Brightness.dark).copyWith(primary: campusMateOrange, surface: const Color(0xFF080808)),
  scaffoldBackgroundColor: const Color(0xFF080808),
  cardTheme: const CardThemeData(color: Color(0xFF2E2B29), elevation: 0),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF1F1F1F),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: Color(0xFF393432)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: Color(0xFF393432)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: campusMateOrange, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: Color(0xFFFFB4AB)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: Color(0xFFFFB4AB), width: 1.5),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  ),
);
