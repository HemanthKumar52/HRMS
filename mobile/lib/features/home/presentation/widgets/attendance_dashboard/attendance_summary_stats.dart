import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/widgets/glass_card.dart';

class AttendanceSummaryStats extends StatelessWidget {
  const AttendanceSummaryStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total Employees',
                value: '2,847',
                trend: '+12% vs yesterday',
                icon: Icons.people,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Present Today',
                value: '2,458',
                trend: '+3.2% vs yesterday',
                icon: Icons.check_circle,
                color: const Color(0xFF004D40), // Dark Green
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Late Arrivals',
                value: '89',
                trend: '+12% vs yesterday',
                icon: Icons.access_time_filled,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Absent Today',
                value: '124',
                trend: '-1.4% vs yesterday',
                icon: Icons.cancel,
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.trend,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
              Text(label, style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: context.textPrimary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
               color: trend.contains('-') ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
               borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              trend,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: trend.contains('-') ? Colors.red : Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
