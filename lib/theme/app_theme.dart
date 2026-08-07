import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const motionDuration = Duration(milliseconds: 220);

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

  // ── Shared operational colors ─────────────────────────────────────────────
  static const statusFree = Color(0xFF34A853);
  static const statusBusy = Color(0xFFFBBC04);
  static const danger = Color(0xFFEA4335);
  static const textPrimary = Color(0xFF202124);
  static const textSecondary = Color(0xFF5F6368);
  static const divider = Color(0xFFE8EAED);

  // ── Bay Wash station portal ────────────────────────────────────────────────
  static const vPrimary = bayTeal;
  static const vPrimary600 = Color(0xFF008C76);
  static const vPrimary700 = Color(0xFF073D3B);
  static const vPrimaryTint = bayMist;
  static const vGold = baySand;
  static const vInk = bayInk;
  static const vInk2 = Color(0xFF1D3A40);
  static const vInk3 = textSecondary;
  static const vInk4 = Color(0xFF8895A4);
  static const vLine = divider;
  static const vLine2 = Color(0xFFF1F3F4);
  static const vSurface = Color(0xFFFFFFFF);
  static const vSurface2 = Color(0xFFF8FAFA);
  static const vSurface3 = bayMist;
  static const vStatusFree = statusFree;
  static const vStatusFreeBg = Color(0xFFE6F4EA);
  static const vStatusBusy = Color(0xFFD99A00);
  static const vStatusBusyBg = Color(0xFFFFF5D6);
  static const vDanger = danger;
  static const vDangerBg = Color(0xFFFCE8E6);

  static final light = ThemeData(
    useMaterial3: true,
    splashFactory: InkRipple.splashFactory,
    splashColor: bayTeal.withValues(alpha: 0.12),
    highlightColor: bayTeal.withValues(alpha: 0.07),
    hoverColor: bayTeal.withValues(alpha: 0.05),
    focusColor: bayTeal.withValues(alpha: 0.09),
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
      splashColor: Color(0x1F00A88A),
    ),
    filledButtonTheme: const FilledButtonThemeData(
      style: ButtonStyle(animationDuration: motionDuration),
    ),
    elevatedButtonTheme: const ElevatedButtonThemeData(
      style: ButtonStyle(animationDuration: motionDuration),
    ),
    outlinedButtonTheme: const OutlinedButtonThemeData(
      style: ButtonStyle(animationDuration: motionDuration),
    ),
    textButtonTheme: const TextButtonThemeData(
      style: ButtonStyle(animationDuration: motionDuration),
    ),
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(animationDuration: motionDuration),
    ),
    segmentedButtonTheme: const SegmentedButtonThemeData(
      style: ButtonStyle(animationDuration: motionDuration),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      surfaceTintColor: Colors.transparent,
    ),
  );
}
