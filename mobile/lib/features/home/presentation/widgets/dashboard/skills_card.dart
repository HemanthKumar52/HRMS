import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme_extensions.dart';

class SkillsCard extends StatelessWidget {
  const SkillsCard({super.key});

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
                  'My Skills',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: context.borderColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: context.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '2025',
                        style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSkillItem(context, 'Figma', 'Updated : 15 May 2025', 0.35, Colors.orange, 0),
            _buildSkillItem(context, 'HTML', 'Updated : 12 May 2025', 0.35, AppColors.success, 1),
            _buildSkillItem(context, 'CSS', 'Updated : 12 May 2025', 0.70, Colors.purple, 2),
            _buildSkillItem(context, 'WordPress', 'Updated : 15 May 2025', 0.51, Colors.blue, 3),
            _buildSkillItem(context, 'Javascript', 'Updated : 13 May 2025', 0.50, AppColors.primary, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillItem(BuildContext context, String name, String date, double percentage, Color color, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 40.0),
            duration: Duration(milliseconds: 600 + index * 100),
            curve: Curves.easeOutCubic,
            builder: (context, height, _) => Container(
              width: 3,
              height: height,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                Text(
                  date,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 40,
            height: 40,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: percentage),
              duration: Duration(milliseconds: 800 + index * 150),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Stack(
                children: [
                  Center(
                    child: Text(
                      '${(value * 100).toInt()}%',
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: context.textPrimary),
                    ),
                  ),
                  Center(
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        value: value,
                        strokeWidth: 3,
                        backgroundColor: context.borderColor,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
