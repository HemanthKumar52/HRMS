import 'package:flutter/material.dart';
import '../utils/responsive.dart';

/// A widget that builds different layouts based on screen size
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType, Orientation orientation) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return OrientationBuilder(
      builder: (context, orientation) {
        return builder(context, Responsive.deviceType, orientation);
      },
    );
  }
}

/// A widget that shows different widgets based on device type
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    switch (Responsive.deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }
}

/// A widget that shows different widgets based on orientation
class OrientationLayout extends StatelessWidget {
  final Widget portrait;
  final Widget landscape;

  const OrientationLayout({
    super.key,
    required this.portrait,
    required this.landscape,
  });

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return orientation == Orientation.portrait ? portrait : landscape;
      },
    );
  }
}

/// Responsive grid view that adjusts columns based on screen size
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.mainAxisSpacing = 16,
    this.crossAxisSpacing = 16,
    this.childAspectRatio = 1,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    int columns;
    if (Responsive.isLandscape) {
      columns = Responsive.value(
        mobile: mobileColumns ?? 2,
        tablet: tabletColumns ?? 4,
        desktop: desktopColumns ?? 6,
      );
    } else {
      columns = Responsive.value(
        mobile: mobileColumns ?? 2,
        tablet: tabletColumns ?? 3,
        desktop: desktopColumns ?? 4,
      );
    }

    return GridView.count(
      crossAxisCount: columns,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      childAspectRatio: childAspectRatio,
      padding: padding ?? Responsive.responsivePadding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      children: children,
    );
  }
}

/// Responsive text that scales based on screen size
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontSize,
    this.fontWeight,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    final responsiveFontSize = fontSize != null ? Responsive.sp(fontSize!) : null;

    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(
        fontSize: responsiveFontSize ?? style?.fontSize,
        fontWeight: fontWeight ?? style?.fontWeight,
        color: color ?? style?.color,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Responsive padding widget
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final double? horizontal;
  final double? vertical;
  final double? all;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.horizontal,
    this.vertical,
    this.all,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    EdgeInsets padding;
    if (all != null) {
      padding = EdgeInsets.all(Responsive.wp(all!));
    } else {
      padding = EdgeInsets.symmetric(
        horizontal: horizontal != null ? Responsive.wp(horizontal!) : Responsive.horizontalPadding,
        vertical: vertical != null ? Responsive.hp(vertical!) : Responsive.verticalPadding,
      );
    }

    return Padding(
      padding: padding,
      child: child,
    );
  }
}

/// Responsive SizedBox
class ResponsiveGap extends StatelessWidget {
  final double? width;
  final double? height;

  const ResponsiveGap({
    super.key,
    this.width,
    this.height,
  });

  /// Horizontal gap
  const ResponsiveGap.horizontal(double width, {super.key})
      : width = width,
        height = null;

  /// Vertical gap
  const ResponsiveGap.vertical(double height, {super.key})
      : width = null,
        height = height;

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return SizedBox(
      width: width != null ? Responsive.wp(width!) : null,
      height: height != null ? Responsive.hp(height!) : null,
    );
  }
}
