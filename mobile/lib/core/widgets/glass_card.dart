import 'package:flutter/material.dart';
import 'dart:ui';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color color;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.1,
    this.color = Colors.white,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // iOS liquid glass parameters
    final effectiveBlur = blur.clamp(15.0, 40.0); // Stronger blur for frosted look
    final bgOpacity = isDark ? 0.18 : 0.55; // Semi-transparent fill
    final borderOpacity = isDark ? 0.3 : 0.6; // Visible light-catching border
    final innerHighlightOpacity = isDark ? 0.05 : 0.35; // Top inner glow
    final shadowOpacity = isDark ? 0.3 : 0.08;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
        child: Container(
          decoration: BoxDecoration(
            // Multi-layer glass fill: base tint + top-to-bottom highlight gradient
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(bgOpacity + innerHighlightOpacity),
                color.withOpacity(bgOpacity),
                color.withOpacity(bgOpacity - 0.05),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            // Double border: outer subtle shadow + inner light stroke
            border: Border.all(
              color: Colors.white.withOpacity(borderOpacity),
              width: 1.0,
            ),
            boxShadow: [
              // Soft outer shadow for depth
              BoxShadow(
                color: Colors.black.withOpacity(shadowOpacity),
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              ),
              // Subtle inner glow (simulated via outer light shadow)
              BoxShadow(
                color: Colors.white.withOpacity(isDark ? 0.03 : 0.15),
                blurRadius: 1,
                offset: const Offset(0, -1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
