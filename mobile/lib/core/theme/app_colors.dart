import 'package:flutter/material.dart';

abstract final class AppColors {
  static const navy950 = Color(0xFF0F172A);
  static const navy900 = Color(0xFF172033);
  static const navy800 = Color(0xFF26364F);
  static const teal700 = Color(0xFF0D9488);
  static const teal600 = Color(0xFF14B8A6);
  static const teal100 = Color(0xFFCCFBF1);
  static const teal50 = Color(0xFFF0FDFA);
  static const medicalBlue = Color(0xFF2563EB);
  static const cyan = Color(0xFF22D3EE);
  static const purple = Color(0xFF8B5CF6);
  static const medicalBlueBackground = Color(0xFFEFF6FF);
  static const documentAmber = Color(0xFFD97706);
  static const documentAmberBackground = Color(0xFFFEF3C7);
  static const evidenceIndigo = Color(0xFF4F46E5);
  static const evidenceIndigoBackground = Color(0xFFEEF2FF);

  static const surface = Color(0xFFF8FAFC);
  static const surfaceContainer = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF1F5F9);
  static const border = Color(0xFFE2E8F0);
  static const text = Color(0xFF172033);
  static const textMuted = Color(0xFF64748B);
  static const success = Color(0xFF16A34A);
  static const successBackground = Color(0xFFE4F5EC);
  static const warning = Color(0xFF9A6700);
  static const warningBackground = Color(0xFFFFF4D6);
  static const danger = Color(0xFFDC2626);
  static const dangerBackground = Color(0xFFFFEDEA);
  static const info = Color(0xFF1769AA);
  static const infoBackground = Color(0xFFE7F1FB);

  static BoxShadow get softShadow => BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 16,
        offset: const Offset(0, 6),
      );

  static BoxShadow get cardShadow => BoxShadow(
        color: navy950.withValues(alpha: 0.07),
        blurRadius: 20,
        offset: const Offset(0, 8),
      );

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
