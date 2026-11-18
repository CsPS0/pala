import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shapes and button looks shared with Kréta Web (lib/web/pala_web_html.dart)
/// and the extension (extension/shared/tokens.css): --radius, --radius-sm,
/// .btn and .btn-primary there.
class AppShapes {
  AppShapes._();

  /// Cards, tables and panels.
  static const double card = 10;

  /// Buttons, inputs, nav items and badges.
  static const double control = 6;

  static const List<Color> _fill = [AppColors.primary, Color(0xFFFF6600)];
  static const List<Color> _fillHover = [Color(0xFFFFA033), Color(0xFFFF7700)];

  /// The orange gradient box behind a primary action.
  static BoxDecoration primaryFill({bool hovered = false, bool enabled = true, Color? disabledColor}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(control),
      gradient: enabled
          ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: hovered ? _fillHover : _fill)
          : null,
      color: enabled ? null : disabledColor,
      boxShadow: enabled
          ? [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: hovered ? 0.35 : 0.2),
                blurRadius: hovered ? 14 : 8,
                offset: Offset(0, hovered ? 4 : 2),
              ),
            ]
          : null,
    );
  }

  /// Primary action: orange gradient with dark text, in both themes.
  static ButtonStyle primaryButton() {
    return ButtonStyle(
      backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(0),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled) ? const Color(0xFF8C8C94) : AppColors.onPrimary,
      ),
      iconColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled) ? const Color(0xFF8C8C94) : AppColors.onPrimary,
      ),
      overlayColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.08)),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(control))),
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      backgroundBuilder: (context, states, child) => DecoratedBox(
        decoration: primaryFill(
          hovered: states.contains(WidgetState.hovered),
          enabled: !states.contains(WidgetState.disabled),
          disabledColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
        ),
        child: child,
      ),
    );
  }

  /// Secondary action: card surface with a one pixel border.
  static ButtonStyle borderedButton(ColorScheme scheme) {
    return OutlinedButton.styleFrom(
      backgroundColor: scheme.surfaceContainerLow,
      foregroundColor: scheme.onSurface,
      side: BorderSide(color: scheme.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(control)),
      minimumSize: const Size(48, 48),
    );
  }
}
