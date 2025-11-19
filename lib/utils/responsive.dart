import 'package:flutter/widgets.dart';

/// Minimal responsive helper with pragmatic breakpoints and utilities
/// used across screens for layout decisions without introducing a heavy
/// dependency. Prefer valueByWidth and gridColumnsForWidth where possible.
class Responsive {
  static const double mobileSmall = 320;
  static const double mobile = 375;
  static const double mobileLarge = 414;
  static const double tablet = 600;
  static const double tabletLarge = 840;
  static const double desktop = 1024;

  static double width(BuildContext context) => MediaQuery.of(context).size.width;
  static double height(BuildContext context) => MediaQuery.of(context).size.height;

  static bool isMobile(BuildContext context) => width(context) < tablet;
  static bool isTablet(BuildContext context) => width(context) >= tablet && width(context) < desktop;
  static bool isDesktop(BuildContext context) => width(context) >= desktop;

  /// Calculates a sensible number of grid columns for a given width,
  /// clamped between [min] and [max]. Useful for icon grids.
  static int gridColumnsForWidth(double width, {int min = 2, int max = 6, double tileMin = 120}) {
    final int cols = (width / tileMin).floor();
    return cols.clamp(min, max);
  }

  /// Returns a value based on width-tier. Provide at least the mobile value.
  static T valueByWidth<T>(BuildContext context, {required T mobile, T? tablet, T? desktop}) {
    final double w = width(context);
    if (w >= Responsive.desktop && desktop != null) return desktop;
    if (w >= Responsive.tablet && tablet != null) return tablet;
    return mobile;
  }
}


