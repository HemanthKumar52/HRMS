import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class PayrollChartsSection extends StatelessWidget {
  const PayrollChartsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildStatItem('Highest Salary', '\$24,500', Colors.green, Icons.arrow_upward),
            _buildStatItem('Variable Pay', '\$284k', Colors.green, Icons.arrow_upward),
            _buildStatItem('After Deduction', '\$1.99M', Colors.red, Icons.arrow_downward),
            _buildStatItem('Average Salary', '\$78,450', Colors.green, Icons.arrow_upward),
          ],
        ),
        const SizedBox(height: 24),
        // Chart
        Container(
          height: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Salary Range Distribution', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              Text('Average Salary \$78,450', style: GoogleFonts.poppins(color: AppColors.grey600, fontSize: 12)),
              const SizedBox(height: 24),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceBetween,
                    barGroups: [
                      _makeBar(0, 4, Color(0xFFEEEEEE)), // Grey
                      _makeBar(1, 12, Colors.orange), // Highlight
                      _makeBar(2, 6, Color(0xFFEEEEEE)),
                      _makeBar(3, 8, Color(0xFFEEEEEE)),
                      _makeBar(4, 5, Color(0xFFEEEEEE)),
                      _makeBar(5, 7, Color(0xFFEEEEEE)),
                      _makeBar(6, 6, Color(0xFFEEEEEE)),
                      _makeBar(7, 5, Color(0xFFEEEEEE)),
                       _makeBar(8, 9, Color(0xFFEEEEEE)),
                    ],
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  BarChartGroupData _makeBar(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          borderRadius: BorderRadius.circular(4),
          width: 16,
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           Row(
             children: [
               Container(
                 padding: const EdgeInsets.all(6),
                 decoration: BoxDecoration(color: AppColors.grey100, shape: BoxShape.circle),
                 child: const Icon(Icons.attach_money, size: 14),
               ),
               const SizedBox(width: 8),
               Expanded( child: Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey600), overflow: TextOverflow.ellipsis)),
             ],
           ),
           const SizedBox(height: 8),
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
               Icon(icon, size: 16, color: color),
             ],
           ),
        ],
      ),
    );
  }
}
