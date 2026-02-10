import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class AssetsByDepartmentChart extends StatelessWidget {
  const AssetsByDepartmentChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
       shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.grey200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Assets by Department', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                const Icon(Icons.refresh, size: 16, color: AppColors.grey500),
              ],
            ),
            const SizedBox(height: 20),
            // Custom implementation since Horizontal Bar Chart in FL Chart requires rotation which might be tricky with axis titles.
            // Custom implementation since Horizontal Bar Chart in FL Chart requires rotation which might be tricky with axis titles.
            _buildBarRow('HR', 0.7, const Color(0xFF264653)),
            const SizedBox(height: 12),
            _buildBarRow('Finance', 0.9, const Color(0xFF264653)),
            const SizedBox(height: 12),
            _buildBarRow('Operations', 0.6, const Color(0xFF264653)),
            const SizedBox(height: 12),
            _buildBarRow('Sales', 0.2, const Color(0xFF264653)),
          ],
        ),
      ),
    );
  }

  Widget _buildBarRow(String label, double pct, Color color) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey600))),
        Expanded(
          child: Stack(
            children: [
              Container(height: 20, decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(4))),
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
