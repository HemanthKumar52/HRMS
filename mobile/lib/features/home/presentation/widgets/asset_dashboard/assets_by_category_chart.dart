import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class AssetsByCategoryChart extends StatelessWidget {
  const AssetsByCategoryChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.grey200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text('Assets By Category', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                 // Text('Monthly', ..)
               ],
             ),
             const SizedBox(height: 16),
             Row(
               children: [
                 // Pie Chart
                 SizedBox(
                   width: 120,
                   height: 120,
                   child: PieChart(
                     PieChartData(
                       sectionsSpace: 0,
                       centerSpaceRadius: 0,
                       sections: [
                         PieChartSectionData(color: const Color(0xFF264653), value: 40, radius: 60, showTitle: false), // Laptops
                         PieChartSectionData(color: const Color(0xFF2A9D8F), value: 20, radius: 60, showTitle: false), // Mouse
                         PieChartSectionData(color: const Color(0xFFE9C46A), value: 15, radius: 60, showTitle: false), // Writing Pad
                         PieChartSectionData(color: const Color(0xFFF4A261), value: 15, radius: 60, showTitle: false), // Keyboard
                         PieChartSectionData(color: const Color(0xFFE76F51), value: 10, radius: 60, showTitle: false), // Chairs
                       ],
                     ),
                     swapAnimationDuration: const Duration(milliseconds: 800),
                     swapAnimationCurve: Curves.easeInOutCubic,
                   ),
                 ),
                 const SizedBox(width: 24),
                 Expanded(
                   child: Column(
                     children: [
                       _legend('Laptops', '40%', const Color(0xFF264653)),
                       _legend('Mouse', '20%', const Color(0xFF2A9D8F)),
                       _legend('Writing Pad', '15%', const Color(0xFFE9C46A)),
                       _legend('Keyboard', '15%', const Color(0xFFF4A261)),
                       _legend('Chairs', '5%', const Color(0xFFE76F51)),
                     ],
                   ),
                 ),
               ],
             ),
          ],
        ),
      ),
    );
  }

  Widget _legend(String label, String pct, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
             decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
             child: Text(pct, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
           ),
           const SizedBox(width: 8),
           Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey700)),
        ],
      ),
    );
  }
}
