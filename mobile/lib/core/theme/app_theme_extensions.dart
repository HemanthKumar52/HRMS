import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Theme-aware color extension on BuildContext.
/// Use `context.scaffoldBg`, `context.textPrimary`, etc. instead of hardcoded colors.
extension AppThemeExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Scaffold / page backgrounds
  Color get scaffoldBg =>
      isDark ? AppColors.backgroundDark : const Color(0xFFF3F4F6);

  // Card / surface backgrounds
  Color get surfaceBg => isDark ? AppColors.surfaceDark : AppColors.white;

  // Glass overlay colors (for bottom sheets, app bar blur)
  Color get glassOverlayStart =>
      isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.85);
  Color get glassOverlayEnd =>
      isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.70);

  // Text colors
  Color get textPrimary => isDark ? AppColors.white : AppColors.grey900;
  Color get textSecondary => isDark ? AppColors.grey400 : AppColors.grey600;
  Color get textTertiary => isDark ? AppColors.grey500 : AppColors.grey500;

  // Border colors
  Color get borderColor => isDark ? AppColors.grey700 : AppColors.grey200;

  // Glass border
  Color get glassBorder =>
      isDark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.6);

  // Chip / badge backgrounds
  Color get chipBg =>
      isDark ? AppColors.grey800 : AppColors.primary.withOpacity(0.1);

  // Divider color
  Color get dividerColor => isDark ? AppColors.grey700 : AppColors.grey200;

  // Handle bar color
  Color get handleBarColor => isDark ? AppColors.grey600 : AppColors.grey300;
}
