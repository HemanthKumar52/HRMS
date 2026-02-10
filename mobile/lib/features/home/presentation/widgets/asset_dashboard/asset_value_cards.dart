import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class AssetValueCards extends StatelessWidget {
  const AssetValueCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildValueCard('Asset Value', '\$2.4M', '+22%', Colors.green),
        const SizedBox(height: 16),
        _buildValueCard('Depreciated Value', '\$1.8M', '+22%', Colors.red), // Red based on mockup direction
      ],
    );
  }

  Widget _buildValueCard(String label, String value, String trend, Color trendColor) {
    final isNegative = trendColor == Colors.red;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.grey200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                   decoration: BoxDecoration(border: Border.all(color: AppColors.grey300), borderRadius: BorderRadius.circular(4)),
                   child: Text('Weekly', style: GoogleFonts.poppins(fontSize: 10)),
                 ),
               ],
             ),
             const SizedBox(height: 8),
             Row(
               children: [
                 Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                 const SizedBox(width: 8),
                 Icon(isNegative ? Icons.arrow_downward : Icons.arrow_upward, size: 14, color: trendColor),
                 Text(trend, style: GoogleFonts.poppins(fontSize: 12, color: trendColor, fontWeight: FontWeight.bold)),
                 Text(' vs last month', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey500)),
               ],
             ),
             const SizedBox(height: 12),
             // Progress or mini chart. Image shows a dash-line progress
             Row(
               children: List.generate(20, (index) => 
                 Container(
                   margin: const EdgeInsets.only(right: 4),
                   width: 8,
                   height: 4,
                   decoration: BoxDecoration(
                     color: index < 12 ? (isNegative ? Colors.orange : Colors.deepOrange) : AppColors.grey200,
                     borderRadius: BorderRadius.circular(2),
                   ),
                 )
               ),
             ),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text('0', style: GoogleFonts.poppins(fontSize: 8)),
                 Text('2M', style: GoogleFonts.poppins(fontSize: 8)),
                 Text('4M', style: GoogleFonts.poppins(fontSize: 8)),
               ],
             ),
          ],
        ),
      ),
    );
  }
}
