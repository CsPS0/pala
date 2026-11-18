import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/pala_tokens.dart';

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

  static const Color _darkBackground = PalaTokens.darkBg;
  static const Color _darkSidebar = PalaTokens.darkSidebar;
  static const Color _darkCard = PalaTokens.darkCard;
  static const Color _darkBorder = PalaTokens.darkBorder;
  static const Color _darkText = PalaTokens.darkText;
  static const Color _darkTextMuted = PalaTokens.darkTextMuted;

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

  static const Color lightBackground = PalaTokens.lightBg;
  static const Color lightSidebar = PalaTokens.lightSidebar;
  static const Color lightCard = PalaTokens.lightCard;
  static const Color lightBorder = PalaTokens.lightBorder;
  static const Color lightText = PalaTokens.lightText;
  static const Color lightTextMuted = PalaTokens.lightTextMuted;
}
