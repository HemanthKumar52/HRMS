import 'dart:io';
import 'package:flutter/material.dart';

/// Device type enum for responsive design
enum DeviceType { mobile, tablet, desktop }

/// Orientation type
enum DeviceOrientation { portrait, landscape }

/// Responsive utility class for handling different screen sizes
class Responsive {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  static late double safeAreaHorizontal;
  static late double safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;
  static late EdgeInsets padding;
  static late EdgeInsets viewPadding;
  static late EdgeInsets viewInsets;
  static late double textScaleFactor;
  static late double devicePixelRatio;

  /// Initialize responsive values - call this in build method
  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;
    padding = _mediaQueryData.padding;
    viewPadding = _mediaQueryData.viewPadding;
    viewInsets = _mediaQueryData.viewInsets;
    textScaleFactor = _mediaQueryData.textScaleFactor;
    devicePixelRatio = _mediaQueryData.devicePixelRatio;

    safeAreaHorizontal = padding.left + padding.right;
    safeAreaVertical = padding.top + padding.bottom;
    safeBlockHorizontal = (screenWidth - safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - safeAreaVertical) / 100;
  }

  /// Get device type based on screen width
  static DeviceType get deviceType {
    if (screenWidth < 600) {
      return DeviceType.mobile;
    } else if (screenWidth < 1200) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Check if device is mobile
  static bool get isMobile => deviceType == DeviceType.mobile;

  /// Check if device is tablet
  static bool get isTablet => deviceType == DeviceType.tablet;

  /// Check if device is desktop
  static bool get isDesktop => deviceType == DeviceType.desktop;

  /// Check if device is in landscape mode
  static bool get isLandscape => screenWidth > screenHeight;

  /// Check if device is in portrait mode
  static bool get isPortrait => screenHeight > screenWidth;

  /// Get device orientation
  static DeviceOrientation get orientation =>
      isLandscape ? DeviceOrientation.landscape : DeviceOrientation.portrait;

  /// Check if platform is iOS
  static bool get isIOS => Platform.isIOS;

  /// Check if platform is Android
  static bool get isAndroid => Platform.isAndroid;

  /// Get responsive width percentage
  static double wp(double percentage) => screenWidth * (percentage / 100);

  /// Get responsive height percentage
  static double hp(double percentage) => screenHeight * (percentage / 100);

  /// Get responsive font size
  static double sp(double fontSize) {
    final scaleFactor = screenWidth / 375; // Base width (iPhone 11)
    return fontSize * scaleFactor.clamp(0.8, 1.3);
  }

  /// Get safe area aware width percentage
  static double swp(double percentage) =>
      (screenWidth - safeAreaHorizontal) * (percentage / 100);

  /// Get safe area aware height percentage
  static double shp(double percentage) =>
      (screenHeight - safeAreaVertical) * (percentage / 100);

  /// Responsive value based on device type
  static T value<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Responsive value based on orientation
  static T orientation_value<T>({
    required T portrait,
    required T landscape,
  }) {
    return isPortrait ? portrait : landscape;
  }

  /// Get responsive padding
  static EdgeInsets get responsivePadding {
    return EdgeInsets.symmetric(
      horizontal: value(mobile: 16.0, tablet: 24.0, desktop: 32.0),
      vertical: value(mobile: 16.0, tablet: 20.0, desktop: 24.0),
    );
  }

  /// Get responsive horizontal padding
  static double get horizontalPadding =>
      value(mobile: 16.0, tablet: 24.0, desktop: 32.0);

  /// Get responsive vertical padding
  static double get verticalPadding =>
      value(mobile: 16.0, tablet: 20.0, desktop: 24.0);

  /// Get responsive card border radius
  static double get cardRadius =>
      value(mobile: 12.0, tablet: 16.0, desktop: 20.0);

  /// Get responsive button height
  static double get buttonHeight =>
      value(mobile: 48.0, tablet: 52.0, desktop: 56.0);

  /// Get responsive icon size
  static double get iconSize =>
      value(mobile: 24.0, tablet: 28.0, desktop: 32.0);

  /// Get grid column count based on device type
  static int get gridColumns {
    if (isLandscape) {
      return value(mobile: 2, tablet: 4, desktop: 6);
    }
    return value(mobile: 2, tablet: 3, desktop: 4);
  }

  /// Get list item height
  static double get listItemHeight =>
      value(mobile: 72.0, tablet: 80.0, desktop: 88.0);

  /// Get app bar height
  static double get appBarHeight =>
      value(mobile: 56.0, tablet: 64.0, desktop: 72.0);

  /// Check if device has notch (approximation)
  static bool get hasNotch => padding.top > 30;

  /// Get status bar height
  static double get statusBarHeight => padding.top;

  /// Get bottom safe area (for home indicator on iOS)
  static double get bottomSafeArea => padding.bottom;

  /// Get keyboard height
  static double get keyboardHeight => viewInsets.bottom;

  /// Check if keyboard is visible
  static bool get isKeyboardVisible => viewInsets.bottom > 0;
}

/// Extension for responsive sizing on numbers
extension ResponsiveExtension on num {
  /// Responsive width
  double get w => Responsive.wp(toDouble());

  /// Responsive height
  double get h => Responsive.hp(toDouble());

  /// Responsive font size
  double get sp => Responsive.sp(toDouble());

  /// Safe area aware width
  double get sw => Responsive.swp(toDouble());

  /// Safe area aware height
  double get sh => Responsive.shp(toDouble());
}
