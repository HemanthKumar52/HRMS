import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_theme_extensions.dart';

class EmployeeStatusCard extends StatelessWidget {
  const EmployeeStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Employee Status & Type',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'View All',
                    style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Custom Visual Bar
            Container(
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1054,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF8A65), // Orange
                        borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: 568,
                    child: Container(
                      color: const Color(0xFF455A64), // Blue Grey
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: 80,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0E0E0), // Grey
                        borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem(context, '1054', 'Full-Time', const Color(0xFFFF8A65)),
                _buildLegendItem(context, '568', 'Contract', const Color(0xFF455A64)),
                _buildLegendItem(context, '80', 'Probation', const Color(0xFF9E9E9E)), // Used Grey for Probation based on mockup hint
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String count, String label, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 3,
              height: 12,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
