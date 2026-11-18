import 'package:flutter/material.dart';

/// Colours by role, for the widgets that follow Kréta Web's component rules
/// (sidebar, top bar, tables, stat tiles). The same values as the CSS tokens
/// in lib/web/pala_web_html.dart and extension/shared/tokens.css.
class PalaTokens {
  final Color bg;
  final Color sidebar;
  final Color card;
  final Color cardHover;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color primary;

  /// Darkens a strip of a surface: table headers, the sidebar footer.
  final Color shade;

  /// Hairlines and resting fills on a surface.
  final Color tint;

  const PalaTokens._({
    required this.bg,
    required this.sidebar,
    required this.card,
    required this.cardHover,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.primary,
    required this.shade,
    required this.tint,
  });

  static const darkBg = Color(0xFF0E0E11);
  static const darkSidebar = Color(0xFF151518);
  static const darkCard = Color(0xFF1B1B1F);
  static const darkBorder = Color(0xFF28282D);
  static const darkText = Color(0xFFF3F3F6);
  static const darkTextMuted = Color(0xFF8C8C94);
  static const lightBg = Color(0xFFF4F4F7);
  static const lightSidebar = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE1E1E6);
  static const lightText = Color(0xFF18181B);
  static const lightTextMuted = Color(0xFF686872);

  static const dark = PalaTokens._(
    bg: darkBg,
    sidebar: darkSidebar,
    card: darkCard,
    cardHover: Color(0xFF222227),
    border: darkBorder,
    text: darkText,
    textMuted: darkTextMuted,
    primary: Color(0xFFFF8800),
    shade: Color(0x47000000),
    tint: Color(0x12FFFFFF),
  );

  static const light = PalaTokens._(
    bg: lightBg,
    sidebar: lightSidebar,
    card: lightCard,
    cardHover: Color(0xFFEFEFF4),
    border: lightBorder,
    text: lightText,
    textMuted: lightTextMuted,
    primary: Color(0xFF964A00),
    shade: Color(0x0A18181B),
    tint: Color(0x1418181B),
  );

  static PalaTokens of(BuildContext context) => Theme.of(context).brightness == Brightness.light ? light : dark;
}
