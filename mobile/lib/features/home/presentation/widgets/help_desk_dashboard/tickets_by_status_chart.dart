import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class TicketsByStatusChart extends StatelessWidget {
  const TicketsByStatusChart({super.key});

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
                 Text('Tickets By Status', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                 // Filter
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
             Row(
               children: [
                 // Radial Chart Simulation (Nested Pies/Rings)
                 SizedBox(
                   width: 150,
                   height: 150,
                   child: Stack(
                     children: [
                       PieChart(
                         PieChartData(
                           centerSpaceRadius: 55,
                           startDegreeOffset: 270,
                           sectionsSpace: 0,
                           sections: [
                             PieChartSectionData(color: Colors.deepOrange, value: 40, showTitle: false, radius: 10),
                             PieChartSectionData(color: Colors.transparent, value: 60, showTitle: false, radius: 10),
                           ],
                         ),
                       ),
                        PieChart(
                         PieChartData(
                           centerSpaceRadius: 40,
                           startDegreeOffset: 270,
                           sectionsSpace: 0,
                           sections: [
                             PieChartSectionData(color: Colors.blue, value: 30, showTitle: false, radius: 10),
                             PieChartSectionData(color: Colors.transparent, value: 70, showTitle: false, radius: 10),
                           ],
                         ),
                       ),
                        PieChart(
                         PieChartData(
                           centerSpaceRadius: 25,
                           startDegreeOffset: 270,
                           sectionsSpace: 0,
                           sections: [
                             PieChartSectionData(color: Colors.amber, value: 20, showTitle: false, radius: 10),
                             PieChartSectionData(color: Colors.transparent, value: 80, showTitle: false, radius: 10),
                           ],
                         ),
                       ),
                       // Purple Ring
                        PieChart(
                         PieChartData(
                           centerSpaceRadius: 10,
                           startDegreeOffset: 270,
                           sectionsSpace: 0,
                           sections: [
                             PieChartSectionData(color: Colors.purple, value: 10, showTitle: false, radius: 10),
                             PieChartSectionData(color: Colors.transparent, value: 90, showTitle: false, radius: 10),
                           ],
                         ),
                       ),
                     ],
                   ),
                 ),
                 const SizedBox(width: 24),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.end,
                     children: [
                       Text('Total Tickets', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey600)),
                       Text('968', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 16),
                       _legendItem('Open', '465', Colors.deepOrange),
                       _legendItem('In Progress', '342', Colors.blue),
                       _legendItem('On Hold', '185', Colors.amber),
                       _legendItem('Closed', '67', Colors.purple),
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

  Widget _legendItem(String label, String val, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
           Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
           const SizedBox(width: 8),
           SizedBox(width: 70, child: Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey600))),
           SizedBox(width: 30, child: Text(val, textAlign: TextAlign.right, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
