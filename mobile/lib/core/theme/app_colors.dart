import 'package:flutter/material.dart';

abstract final class AppColors {
  // Deep Midnight & Electric Violet Portfolio Palette
  static const obsidian = Color(0xFF0B0A14);
  static const forestSurface = Color(0xFF131122);
  static const forestElevated = Color(0xFF1B1830);
  static const forestBorder = Color(0xFF2B264A);
  static const emerald = Color(0xFF8B5CF6);
  static const emeraldDark = Color(0xFF5B21B6);
  static const emeraldGlow = Color(0xFFA78BFA);
  static const emeraldTint = Color(0xFF1F183D);

  // Legacy constant aliases kept intact so all feature screens compile cleanly
  static const navy950 = Color(0xFF07060D);
  static const navy900 = Color(0xFF0F0D1C);
  static const navy800 = Color(0xFF1B1830);
  static const teal700 = emerald;
  static const teal600 = emeraldGlow;
  static const teal100 = emeraldTint;
  static const teal50 = Color(0xFF141126);
  static const medicalBlue = Color(0xFF38BDF8);
  static const cyan = Color(0xFF818CF8);
  static const purple = Color(0xFFC084FC);
  static const medicalBlueBackground = Color(0xFF151936);
  static const documentAmber = Color(0xFFFBBF24);
  static const documentAmberBackground = Color(0xFF2A210D);
  static const evidenceIndigo = Color(0xFFA78BFA);
  static const evidenceIndigoBackground = Color(0xFF1F183D);

  static const surface = obsidian;
  static const surfaceContainer = forestSurface;
  static const surfaceMuted = forestElevated;
  static const border = forestBorder;
  static const text = Color(0xFFF5F3FF);
  static const textMuted = Color(0xFF9E99BD);
  static const success = emerald;
  static const successBackground = emeraldTint;
  static const warning = Color(0xFFFBBF24);
  static const warningBackground = Color(0xFF2A210D);
  static const danger = Color(0xFFF87171);
  static const dangerBackground = Color(0xFF2E131A);
  static const info = Color(0xFF818CF8);
  static const infoBackground = Color(0xFF171636);

  static BoxShadow get softShadow => BoxShadow(
        color: Colors.black.withValues(alpha: 0.42),
        blurRadius: 20,
        offset: const Offset(0, 8),
      );

  static BoxShadow get cardShadow => BoxShadow(
        color: emerald.withValues(alpha: 0.18),
        blurRadius: 34,
        offset: const Offset(0, 12),
      );

  static const lightScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: emerald,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: emeraldTint,
    onPrimaryContainer: Color(0xFFDDD6FE),
    secondary: forestElevated,
    onSecondary: text,
    secondaryContainer: Color(0xFF221D3D),
    onSecondaryContainer: text,
    tertiary: cyan,
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF1B1A40),
    onTertiaryContainer: Color(0xFFE0E7FF),
    error: danger,
    onError: Color(0xFF2B090B),
    errorContainer: dangerBackground,
    onErrorContainer: Color(0xFFFECACA),
    surface: obsidian,
    onSurface: text,
    surfaceContainerHighest: forestElevated,
    onSurfaceVariant: textMuted,
    outline: Color(0xFF3E3766),
    outlineVariant: forestBorder,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: text,
    onInverseSurface: obsidian,
    inversePrimary: emeraldDark,
  );
}