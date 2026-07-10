import 'package:flutter/material.dart';

abstract final class AppTheme {
  // ── Bay Wash customer palette ─────────────────────────────────────────────
  static const bayInk = Color(0xFF061E25);
  static const bayTeal = Color(0xFF00A88A);
  static const bayAqua = Color(0xFF44D7C5);
  static const bayMist = Color(0xFFEAF4F1);
  static const bayCream = Color(0xFFFAF7EF);
  static const baySand = Color(0xFFC69B64);
  static const brandFontFallback = <String>[
    'Inter',
    'SF Pro Display',
    'SF Pro Text',
    'Roboto',
    'Arial',
  ];

  // ── User portal legacy colors ─────────────────────────────────────────────
  static const googleBlue = Color(0xFF1A73E8);
  static const nextbikeBlue = Color(0xFF005AA9);
  static const nextbikeDarkBlue = Color(0xFF003F7D);
  static const statusFree = Color(0xFF34A853);
  static const statusBusy = Color(0xFFFBBC04);
  static const statusFull = Color(0xFFEA4335);
  static const textPrimary = Color(0xFF202124);
  static const textSecondary = Color(0xFF5F6368);
  static const divider = Color(0xFFE8EAED);

  // ── Bay Wash station portal (Teal / UAE) ────────────────────────────────────
  static const vPrimary = Color(0xFF0A4D4A);
  static const vPrimary600 = Color(0xFF0E5F5B);
  static const vPrimary700 = Color(0xFF073D3B);
  static const vPrimaryTint = Color(0xFFE2EEEB);
  static const vGold = Color(0xFFC9A961);
  static const vInk = Color(0xFF0D1F2D);
  static const vInk2 = Color(0xFF29384A);
  static const vInk3 = Color(0xFF5B6B7C);
  static const vInk4 = Color(0xFF8895A4);
  static const vLine = Color(0xFFE6E2D7);
  static const vLine2 = Color(0xFFEFECE3);
  static const vSurface = Color(0xFFFFFFFF);
  static const vSurface2 = Color(0xFFFBF8F1);
  static const vSurface3 = Color(0xFFF4EFE2);
  static const vStatusFree = Color(0xFF1F8A56);
  static const vStatusFreeBg = Color(0xFFE2F2E9);
  static const vStatusBusy = Color(0xFFC28A12);
  static const vStatusBusyBg = Color(0xFFF8EDD0);
  static const vStatusFull = Color(0xFFB23A2A);
  static const vStatusFullBg = Color(0xFFF6E1DC);

  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: bayTeal,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.white,
      foregroundColor: bayInk,
      elevation: 4,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      surfaceTintColor: Colors.transparent,
    ),
  );
}
