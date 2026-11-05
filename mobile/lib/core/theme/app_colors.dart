import 'package:flutter/material.dart';

abstract final class AppColors {
  static const navy950 = Color(0xFF071A2B);
  static const navy900 = Color(0xFF0B243B);
  static const navy800 = Color(0xFF123A56);
  static const teal700 = Color(0xFF007C83);
  static const teal600 = Color(0xFF008F95);
  static const teal100 = Color(0xFFD4F3F1);
  static const teal50 = Color(0xFFEAF9F8);

  static const surface = Color(0xFFF7FAFC);
  static const surfaceContainer = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFE7EEF2);
  static const border = Color(0xFFD8E2E8);
  static const text = Color(0xFF12212B);
  static const textMuted = Color(0xFF52636D);
  static const success = Color(0xFF18794E);
  static const successBackground = Color(0xFFE4F5EC);
  static const warning = Color(0xFF9A6700);
  static const warningBackground = Color(0xFFFFF4D6);
  static const danger = Color(0xFFBA1A1A);
  static const dangerBackground = Color(0xFFFFEDEA);
  static const info = Color(0xFF1769AA);
  static const infoBackground = Color(0xFFE7F1FB);

  static const lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: teal700,
    onPrimary: Colors.white,
    primaryContainer: teal100,
    onPrimaryContainer: navy950,
    secondary: navy800,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFDCEAF4),
    onSecondaryContainer: navy950,
    tertiary: Color(0xFF6750A4),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFEADDFF),
    onTertiaryContainer: Color(0xFF21005D),
    error: danger,
    onError: Colors.white,
    errorContainer: dangerBackground,
    onErrorContainer: Color(0xFF410002),
    surface: surface,
    onSurface: text,
    surfaceContainerHighest: Color(0xFFE7EEF2),
    onSurfaceVariant: textMuted,
    outline: Color(0xFF71828C),
    outlineVariant: border,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: navy900,
    onInverseSurface: Colors.white,
    inversePrimary: Color(0xFF5CDBD8),
  );
}
