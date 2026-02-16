import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/responsive.dart';
import '../theme/app_colors.dart';

/// A scaffold wrapper that properly handles safe areas for iOS and Android
/// Includes proper handling for notches, status bars, and navigation bars
class SafeScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool resizeToAvoidBottomInset;

  /// Whether to use safe area for the body
  final bool useSafeArea;

  /// Whether to use safe area for the top
  final bool safeTop;

  /// Whether to use safe area for the bottom
  final bool safeBottom;

  /// Whether to use safe area for the left
  final bool safeLeft;

  /// Whether to use safe area for the right
  final bool safeRight;

  /// Custom padding to apply on top of safe area
  final EdgeInsetsGeometry? padding;

  /// Status bar brightness (for iOS)
  final Brightness? statusBarBrightness;

  /// Status bar icon brightness
  final Brightness? statusBarIconBrightness;

  /// System navigation bar color (for Android)
  final Color? systemNavigationBarColor;

  const SafeScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset = true,
    this.useSafeArea = true,
    this.safeTop = true,
    this.safeBottom = true,
    this.safeLeft = true,
    this.safeRight = true,
    this.padding,
    this.statusBarBrightness,
    this.statusBarIconBrightness,
    this.systemNavigationBarColor,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    // Set system UI overlay style
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: statusBarBrightness ?? (isDark ? Brightness.dark : Brightness.light),
      statusBarIconBrightness: statusBarIconBrightness ?? (isDark ? Brightness.light : Brightness.dark),
      systemNavigationBarColor: systemNavigationBarColor ?? (Platform.isAndroid ? (backgroundColor ?? AppColors.background) : null),
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        bottomNavigationBar: bottomNavigationBar,
        drawer: drawer,
        endDrawer: endDrawer,
        backgroundColor: backgroundColor,
        extendBody: extendBody,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    Widget content = body;

    // Apply custom padding if provided
    if (padding != null) {
      content = Padding(
        padding: padding!,
        child: content,
      );
    }

    // Wrap with SafeArea if enabled
    if (useSafeArea) {
      content = SafeArea(
        top: safeTop && appBar == null, // Don't add top safe area if appBar handles it
        bottom: safeBottom && bottomNavigationBar == null, // Don't add bottom safe area if bottomNav handles it
        left: safeLeft,
        right: safeRight,
        child: content,
      );
    }

    return content;
  }
}

/// A screen wrapper with common configurations for responsive and safe handling
class ResponsiveScreen extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Color? backgroundColor;
  final bool useSafeArea;
  final EdgeInsetsGeometry? padding;

  const ResponsiveScreen({
    super.key,
    required this.child,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.backgroundColor,
    this.useSafeArea = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return SafeScaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      backgroundColor: backgroundColor ?? AppColors.background,
      useSafeArea: useSafeArea,
      padding: padding ?? EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding,
      ),
      body: child,
    );
  }
}

/// Adaptive app bar that adjusts based on platform and screen size
class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;

  const AdaptiveAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle = false,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    // Adjust title based on device type
    Widget? titleContent;
    if (titleWidget != null) {
      titleContent = titleWidget;
    } else if (title != null) {
      titleContent = Text(
        title!,
        style: TextStyle(
          fontSize: Responsive.sp(Responsive.value(mobile: 18.0, tablet: 20.0, desktop: 22.0)),
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return AppBar(
      title: titleContent,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor ?? Colors.white,
      foregroundColor: foregroundColor ?? AppColors.grey900,
      elevation: elevation ?? 0,
      centerTitle: centerTitle || Platform.isIOS,
      surfaceTintColor: Colors.transparent,
      bottom: bottom,
    );
  }
}

/// Platform-aware back button
class AdaptiveBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;

  const AdaptiveBackButton({
    super.key,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Platform.isIOS ? Icons.arrow_back_ios : Icons.arrow_back,
        color: color,
      ),
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
    );
  }
}

/// Responsive container with max width constraints for tablets
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    // For tablets and desktop, constrain the width
    final double effectiveMaxWidth = maxWidth ?? Responsive.value<double>(
      mobile: double.infinity,
      tablet: 600.0,
      desktop: 800.0,
    );

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        padding: padding,
        child: child,
      ),
    );
  }
}

/// A card that adapts its size and padding based on screen size
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    final effectivePadding = padding ?? EdgeInsets.all(
      Responsive.value(mobile: 16.0, tablet: 20.0, desktop: 24.0),
    );

    final effectiveMargin = margin ?? EdgeInsets.symmetric(
      horizontal: Responsive.horizontalPadding,
      vertical: 8,
    );

    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(
      Responsive.cardRadius,
    );

    Widget card = Container(
      margin: effectiveMargin,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: effectiveBorderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: elevation ?? 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: effectivePadding,
        child: child,
      ),
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: effectiveBorderRadius,
        child: card,
      );
    }

    return card;
  }
}
