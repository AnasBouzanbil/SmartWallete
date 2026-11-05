import 'package:flutter/widgets.dart';

/// Spacing scale, corner radii and fixed control sizes.
/// Never use raw paddings or radii outside lib/core/theme.
class AppSpacing {
  const AppSpacing._();

  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space24 = 24;
  static const double space32 = 32;

  static const double radius12 = 12;
  static const double radius20 = 20;

  static const double controlHeight = 48;

  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 28;
  static const double iconXl = 40;

  static const EdgeInsets page = EdgeInsets.all(space16);
  static const EdgeInsets card = EdgeInsets.all(space16);
  static const EdgeInsets field = EdgeInsets.symmetric(
    horizontal: space16,
    vertical: space12,
  );
  static const EdgeInsets section = EdgeInsets.symmetric(vertical: space24);
}
