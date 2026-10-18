import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Legacy color getters for the older views; values come from [AppColors]
/// where the two palettes agree.
class PalaTheme {
  static const Color accent = AppColors.primary;

  /// Set by AppModel whenever the dark/light preference changes. Widgets
  /// across the app read the PalaTheme.background/card/text/etc. getters
  /// below directly (not via Theme.of(context)), so this single flag is
  /// what actually re-skins the app for light mode without touching every
  /// call site.
  static bool isLight = false;

  static const Color _darkBackground = AppColors.darkSurfaceContainerLowest;
  static const Color _darkSidebar = Color(0xFF151518);
  static const Color _darkCard = AppColors.darkSurfaceContainerLow;
  static const Color _darkBorder = AppColors.darkSurfaceContainerHigh;
  static const Color _darkText = Color(0xFFF3F3F6);
  static const Color _darkTextMuted = Color(0xFF8C8C94);

  static Color get background => isLight ? lightBackground : _darkBackground;
  static Color get sidebar => isLight ? lightSidebar : _darkSidebar;
  static Color get card => isLight ? lightCard : _darkCard;
  static Color get border => isLight ? lightBorder : _darkBorder;
  static Color get text => isLight ? lightText : _darkText;
  static Color get textMuted => isLight ? lightTextMuted : _darkTextMuted;

  // The bright status colours are unreadable as text on white, so light mode
  // gets darker variants that clear 4.5:1.
  static Color get success => isLight ? const Color(0xFF1B7F3B) : AppColors.success;
  static Color get warning => isLight ? const Color(0xFF8A6100) : AppColors.warning;
  static Color get danger => isLight ? const Color(0xFFC62828) : const Color(0xFFFF453A);

  static const Color lightBackground = Color(0xFFF5F5F7);
  static const Color lightSidebar = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE0E0E3);
  static const Color lightText = Color(0xFF1C1C1E);
  static const Color lightTextMuted = Color(0xFF6E6E76);
}
