import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/widgets/glass_card.dart';

class DashboardStatsGrid extends StatelessWidget {
  const DashboardStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          icon: Icons.access_time_filled,
          iconColor: Colors.orange,
          value: '8.36 / 9',
          label: 'Total Hours Today',
          subValue: '5% This Week',
          isPositive: true,
        ),
        _buildStatCard(
          context,
          icon: Icons.calendar_view_week,
          iconColor: context.isDark ? Colors.white : Colors.black,
          value: '10 / 40',
          label: 'Total Hours Week',
          subValue: '7% Last Week',
          isPositive: true,
        ),
        _buildStatCard(
          context,
          icon: Icons.calendar_month,
          iconColor: Colors.blue,
          value: '75 / 98',
          label: 'Total Hours Month',
          subValue: '8% Last Month',
          isPositive: false,
        ),
        _buildStatCard(
          context,
          icon: Icons.timer,
          iconColor: Colors.pink,
          value: '16 / 28',
          label: 'Overtime this Month',
          subValue: '6% Last Month',
          isPositive: false,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required String subValue,
    required bool isPositive,
  }) {
    return GlassCard(
      blur: 12,
      opacity: 0.15,
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
             Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
             Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12,
                  color: isPositive ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  subValue,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: context.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }
}
