import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class TicketsByCategoryChart extends StatelessWidget {
  const TicketsByCategoryChart({super.key});

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
                 Text('Tickets By Category', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                   decoration: BoxDecoration(border: Border.all(color: AppColors.grey300), borderRadius: BorderRadius.circular(4)),
                   child: Row(
                     children: [
                       const Icon(Icons.calendar_today, size: 12, color: AppColors.grey600),
                       const SizedBox(width: 4),
                       Text('Monthly', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey600)),
                     ],
                   ),
                 ),
               ],
             ),
             const SizedBox(height: 20),
             SizedBox(
               height: 120,
               child: Stack(
                 alignment: Alignment.bottomCenter,
                 children: [
                   PieChart(
                     PieChartData(
                       startDegreeOffset: 180,
                       centerSpaceRadius: 60,
                       sectionsSpace: 4,
                       sections: [
                         PieChartSectionData(color: Colors.deepOrange, value: 30, showTitle: false, radius: 25), // IT Support
                         PieChartSectionData(color: const Color(0xFF264653), value: 25, showTitle: false, radius: 25), // HR
                         PieChartSectionData(color: Colors.amber, value: 20, showTitle: false, radius: 25), // Payroll
                         PieChartSectionData(color: Colors.blue, value: 15, showTitle: false, radius: 25), // Hardware
                         PieChartSectionData(color: Colors.red, value: 10, showTitle: false, radius: 25), // Other
                         PieChartSectionData(color: Colors.transparent, value: 100, showTitle: false, radius: 25), // Bottom half
                       ],
                     ),
                     swapAnimationDuration: const Duration(milliseconds: 800),
                     swapAnimationCurve: Curves.easeInOutCubic,
                   ),
                   const Padding(
                     padding: EdgeInsets.only(bottom: 20),
                     child: Text('Compliance', style: TextStyle(fontSize: 12, color: Colors.grey)),
                   ),
                 ],
               ),
             ),
             const SizedBox(height: 16),
             Wrap(
               spacing: 24,
               runSpacing: 16,
               alignment: WrapAlignment.center,
               children: [
                 _legend('IT Support', '435', Colors.deepOrange),
                 _legend('HR', '342', const Color(0xFF264653)),
                 _legend('Payroll', '268', Colors.amber),
                 _legend('Access', '195', Colors.blue), // Using Blue for Hardware/Access
                 _legend('Hardware', '412', Colors.blue), 
                 _legend('Other', '145', Colors.red),
               ],
             ),
          ],
        ),
      ),
    );
  }

  Widget _legend(String label, String val, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Container(width: 2, height: 10, color: color, margin: const EdgeInsets.symmetric(vertical: 4)),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}
