import 'package:flutter/material.dart';

/// Semantic colors and palette definitions for Pala Material Design 3 themes.
class AppColors {
  AppColors._();

  // Brand Accent
  static const Color primary = Color(0xFFFF8800);
  static const Color onPrimary = Color(0xFF000000);
  static const Color primaryContainer = Color(0xFF5A2C00);
  static const Color onPrimaryContainer = Color(0xFFFFDCBE);

  // Light-mode accents: the bright oranges above are about 2.4:1 on white, so
  // light mode uses darker shades that pass 4.5:1 as text and under white text.
  static const Color lightPrimary = Color(0xFF964A00);
  static const Color lightSecondary = Color(0xFF8F5200);
  static const Color lightTertiary = Color(0xFF805A00);

  // Secondary
  static const Color secondary = Color(0xFFE08600);
  static const Color onSecondary = Color(0xFF000000);
  static const Color secondaryContainer = Color(0xFF4A2B00);
  static const Color onSecondaryContainer = Color(0xFFFFDDB8);

  // Tertiary (used for substitutions and pending states)
  static const Color tertiary = Color(0xFFE5A000);
  static const Color onTertiary = Color(0xFF241500);
  static const Color tertiaryContainer = Color(0xFF4D3400);
  static const Color onTertiaryContainer = Color(0xFFFFE0A8);

  // Error / Danger (cancellations, unexcused absences, failing grades)
  static const Color error = Color(0xFFFF5449);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // Success
  static const Color success = Color(0xFF30D158);
  static const Color onSuccess = Color(0xFF003912);
  static const Color successContainer = Color(0xFF00531D);
  static const Color onSuccessContainer = Color(0xFF75FB8E);

  // Warning
  static const Color warning = Color(0xFFFFD60A);
  static const Color onWarning = Color(0xFF261C00);
  static const Color warningContainer = Color(0xFF574300);
  static const Color onWarningContainer = Color(0xFFFFE088);

  // Dark Neutral Surfaces (M3 surface container roles)
  static const Color darkSurface = Color(0xFF131316);
  static const Color darkOnSurface = Color(0xFFE4E1E6);
  static const Color darkSurfaceContainerLowest = Color(0xFF0E0E11);
  static const Color darkSurfaceContainerLow = Color(0xFF1B1B1F);
  static const Color darkSurfaceContainer = Color(0xFF222227);
  static const Color darkSurfaceContainerHigh = Color(0xFF28282D);
  static const Color darkSurfaceContainerHighest = Color(0xFF333339);
  // Outline doubles as the muted text colour across the app, so it must reach 4.5:1.
  static const Color darkOutline = Color(0xFF9A97A0);
  static const Color darkOutlineVariant = Color(0xFF3A383E);

  // Light Neutral Surfaces
  static const Color lightSurface = Color(0xFFFBF8FF);
  static const Color lightOnSurface = Color(0xFF1A1B1F);
  static const Color lightSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainerLow = Color(0xFFF5F3FA);
  static const Color lightSurfaceContainer = Color(0xFFEFEFF4);
  static const Color lightSurfaceContainerHigh = Color(0xFFEAE7F0);
  static const Color lightSurfaceContainerHighest = Color(0xFFE4E1E9);
  static const Color lightOutline = Color(0xFF615E66);
  static const Color lightOutlineVariant = Color(0xFFCAC4D0);

  // Grade color mappings
  static Color getGradeColor(num? value) {
    if (value == null) return darkOutline;
    final intVal = value.round();
    switch (intVal) {
      case 5:
        return success;
      case 4:
        return const Color(0xFF45C465);
      case 3:
        return warning;
      case 2:
        return primary;
      case 1:
        return error;
      default:
        return darkOutline;
    }
  }
}
