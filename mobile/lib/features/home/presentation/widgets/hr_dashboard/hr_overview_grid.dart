import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/widgets/glass_card.dart';

class HrOverviewGrid extends StatelessWidget {
  const HrOverviewGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.people_outline,
                iconColor: Colors.orange,
                label: 'Total Employee',
                value: '1,848',
                subLabel: 'Headcount',
                percentage: '+18%',
                isPositive: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.person_add_alt_1_outlined,
                iconColor: const Color(0xFF455A64), // Blue Grey
                label: 'New Joiners',
                value: '1,248',
                subLabel: 'All Department',
                percentage: '+22%',
                isPositive: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.timer_outlined,
                iconColor: Colors.black,
                label: 'Late Arrivals Today',
                value: '12',
                subLabel: 'Delayed Login',
                percentage: '-16%',
                isPositive: false, // Wait, late arrivals decreasing is good, so maybe visually distinct? Mockup handles it with red arrow.
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.monetization_on_outlined,
                iconColor: Colors.purple,
                label: 'Total Payroll Cost',
                value: '\$2.4M',
                subLabel: 'Payroll Outflow',
                percentage: '+16%',
                isPositive: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subLabel;
  final String percentage;
  final bool isPositive;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subLabel,
    required this.percentage,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = percentage.startsWith('-');
    final badgeColor = isNegative ? AppColors.error : AppColors.success;
    final badgeIcon = isNegative ? Icons.arrow_downward : Icons.arrow_upward;

    return GlassCard(
      blur: 12,
      opacity: 0.15,
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              // Badge
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: context.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     value,
                     style: GoogleFonts.poppins(
                       fontSize: 24,
                       fontWeight: FontWeight.bold,
                       color: context.textPrimary,
                     ),
                   ),
                   Text(
                     subLabel,
                     style: GoogleFonts.poppins(
                       fontSize: 10,
                       color: context.textSecondary,
                     ),
                   ),
                 ],
               ),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                 decoration: BoxDecoration(
                   color: badgeColor.withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(12),
                 ),
                 child: Row(
                   children: [
                     Icon(badgeIcon, size: 10, color: badgeColor),
                     const SizedBox(width: 2),
                     Text(
                       percentage,
                       style: GoogleFonts.poppins(
                         fontSize: 10,
                         fontWeight: FontWeight.w600,
                         color: badgeColor,
                       ),
                     ),
                   ],
                 ),
               ),
            ],
          ),
        ],
      ),
    );
  }
}
