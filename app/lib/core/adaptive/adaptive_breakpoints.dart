import 'package:flutter/material.dart';

/// Standard breakpoint definitions for adaptive layouts across Pala clients.
class AdaptiveBreakpoints {
  AdaptiveBreakpoints._();

  /// 600dp breakpoint threshold separating compact (mobile) and expanded (tablet/desktop) views.
  static const double compactBreakpoint = 600.0;

  /// Touch target minimum size mandated by WCAG 2.1 AA (48dp for Android / 44pt for iOS).
  static const double minTouchTargetAndroid = 48.0;
  static const double minTouchTargetIos = 44.0;

  /// Evaluates whether the current context belongs to a compact viewport (< 600dp).
  static bool isCompact(BuildContext context) {
    return MediaQuery.sizeOf(context).width < compactBreakpoint;
  }

  /// Evaluates whether the given box constraints represent a compact viewport.
  static bool isCompactConstraints(BoxConstraints constraints) {
    return constraints.maxWidth < compactBreakpoint;
  }

  /// Evaluates whether the current context belongs to an expanded viewport (>= 600dp).
  static bool isExpanded(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= compactBreakpoint;
  }

  /// Evaluates whether the given box constraints represent an expanded viewport.
  static bool isExpandedConstraints(BoxConstraints constraints) {
    return constraints.maxWidth >= compactBreakpoint;
  }

  /// Minimum box constraints to enforce accessible touch targets.
  static BoxConstraints touchTargetConstraints(BuildContext context) {
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    final size = isIos ? minTouchTargetIos : minTouchTargetAndroid;
    return BoxConstraints(minWidth: size, minHeight: size);
  }
}
