import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class LoginCountChart extends StatelessWidget {
  const LoginCountChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.grey200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Login Count Analysis', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 300), FlSpot(1, 450), FlSpot(2, 320), FlSpot(3, 500),
                        FlSpot(4, 400), FlSpot(5, 600), FlSpot(6, 550), FlSpot(7, 300),
                        FlSpot(8, 400), FlSpot(9, 600), FlSpot(10, 500), FlSpot(11, 450),
                      ],
                      isCurved: true,
                      color: Colors.deepOrange,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [Colors.deepOrange.withOpacity(0.2), Colors.deepOrange.withOpacity(0.0)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
