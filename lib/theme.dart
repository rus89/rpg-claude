// ABOUTME: Centralised app theme — defines all visual tokens in one place.
// ABOUTME: Screens inherit from this theme; no hardcoded colors in widgets.

import 'package:flutter/material.dart';

const _primary = Color(0xFF5C7A45);
const _background = Color(0xFFF5F2EC);
const _surface = Color(0xFFFFFFFF);
const _textPrimary = Color(0xFF1A1A1A);
const _textSecondary = Color(0xFF6B6B6B);

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: _primary,
    primary: _primary,
    surface: _surface,
    onSurface: _textPrimary,
  ),
  scaffoldBackgroundColor: _background,
  appBarTheme: const AppBarTheme(
    backgroundColor: _primary,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 0,
    color: _surface,
    shadowColor: Colors.transparent,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: _surface,
    indicatorColor: _primary.withValues(alpha: 0.15),
    labelTextStyle: const WidgetStatePropertyAll(
      TextStyle(fontSize: 12, color: _textSecondary),
    ),
  ),
  chipTheme: const ChipThemeData(
    backgroundColor: _background,
    selectedColor: _primary,
    labelStyle: TextStyle(color: _textPrimary),
    secondaryLabelStyle: TextStyle(color: Colors.white),
    showCheckmark: true,
    checkmarkColor: Colors.white,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _textSecondary.withValues(alpha: 0.2)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _textSecondary.withValues(alpha: 0.2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _primary),
    ),
  ),
  textTheme: const TextTheme(
    headlineSmall: TextStyle(fontWeight: FontWeight.w800, color: _textPrimary),
    titleMedium: TextStyle(fontWeight: FontWeight.w700, color: _textPrimary),
    bodyMedium: TextStyle(fontWeight: FontWeight.w400, color: _textPrimary),
    bodySmall: TextStyle(fontWeight: FontWeight.w500, color: _textSecondary),
  ),
);

/// Amber accent for secondary highlights (chart accents, badges).
const accentColor = Color(0xFFC47B2B);

/// Card-like container decoration with custom shadow.
final cardDecoration = BoxDecoration(
  color: _surface,
  borderRadius: BorderRadius.circular(12),
  boxShadow: const [
    BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
  ],
);
