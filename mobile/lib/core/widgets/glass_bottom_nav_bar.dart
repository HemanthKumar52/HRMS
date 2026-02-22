import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';

class GlassNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const GlassNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class GlassBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavItem> items;

  const GlassBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            // Liquid glass gradient fill
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      Colors.white.withOpacity(0.12),
                      Colors.white.withOpacity(0.06),
                    ]
                  : [
                      Colors.white.withOpacity(0.85),
                      Colors.white.withOpacity(0.65),
                    ],
            ),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.15 : 0.6),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, -4),
                spreadRadius: -4,
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                top: 10,
                bottom: bottomPadding > 0 ? 0 : 10,
                left: 8,
                right: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (index) {
                  final isActive = index == currentIndex;
                  final item = items[index];

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(index),
                      behavior: HitTestBehavior.opaque,
                      child: _GlassNavItemWidget(
                        item: item,
                        isActive: isActive,
                        key: ValueKey('nav_$index'),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassNavItemWidget extends StatelessWidget {
  final GlassNavItem item;
  final bool isActive;

  const _GlassNavItemWidget({
    super.key,
    required this.item,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Active pill background with glass effect
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isActive ? 18 : 12,
              vertical: isActive ? 8 : 4,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: isActive
                  ? Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 0.5,
                    )
                  : null,
            ),
            child: Icon(
              isActive ? item.activeIcon : item.icon,
              color: isActive ? AppColors.primary : AppColors.grey600,
              size: isActive ? 26 : 23,
            ),
          ).animate(target: isActive ? 1 : 0).scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.0, 1.0),
                duration: 200.ms,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: isActive ? 11 : 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? AppColors.primary : AppColors.grey600,
            ),
            child: Text(item.label),
          ),
          // Active indicator dot
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(top: 3),
            width: isActive ? 5 : 0,
            height: isActive ? 5 : 0,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
