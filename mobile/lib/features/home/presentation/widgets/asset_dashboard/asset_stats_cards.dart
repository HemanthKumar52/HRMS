import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class AssetStatsCards extends StatelessWidget {
  const AssetStatsCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildCard('Total Assets', '1,247', '+9.25%', const Color(0xFFE65100))), // Orange
        const SizedBox(width: 8),
        Expanded(child: _buildCard('Assets Assigned', '892', '+9.25%', const Color(0xFF004D40))), // Teal
        const SizedBox(width: 8),
        Expanded(child: _buildCard('Assets Available', '287', '-9.25%', const Color(0xFFB71C1C))), // Red-ish/Purple from mockup
      ],
    );
  }

  Widget _buildCard(String label, String value, String trend, Color color) {
    final isNegative = trend.contains('-');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Icon(Icons.inventory_2_outlined, size: 16, color: color),
               Text(trend, style: GoogleFonts.poppins(fontSize: 10, color: isNegative ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey500)),
          const SizedBox(height: 8),
          // Mini Bar Chart simulation
          Row(
             crossAxisAlignment: CrossAxisAlignment.end,
             children: List.generate(10, (index) => 
                Container(
                  margin: const EdgeInsets.only(right: 2),
                  width: 4,
                  height: 4 + (index % 5) * 3.0 + (index == 5 ? 10 : 0),
                  color: index == 5 ? color : AppColors.grey200, // Highlight one bar
                  // border radius
                )
             ),
          ),
        ],
      ),
    );
  }
}
