import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class AgentPerformanceList extends StatelessWidget {
  const AgentPerformanceList({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.grey200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Agent Performance', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
          ),
          const Divider(height: 1),
          // List
          _buildAgentRow('Michael Johnson', '4.6', '1.8h', 0.70),
          const Divider(height: 1),
          _buildAgentRow('Emily Davis', '4.8', '1.4h', 0.93),
          const Divider(height: 1),
          _buildAgentRow('Robert Martinez', '4.3', '1.1h', 0.60),
          const Divider(height: 1),
          _buildAgentRow('Megan Walker', '4.5', '1.5h', 0.80),
        ],
      ),
    );
  }

  Widget _buildAgentRow(String name, String rating, String avgTime, double rate) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            radius: 18,
            child: Text(name[0], style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(rating, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey600)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Avg Resolution Time', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey500)),
                Text(avgTime, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Resolution Rate', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey500)),
                    Text('${(rate * 100).toInt()}%', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                // Dots progress bar
                Row(
                  children: List.generate(20, (index) {
                     Color color;
                     if (index < rate * 20) {
                        color = Colors.deepOrange;
                     } else {
                        color = AppColors.grey200;
                     }
                     return Container(
                       margin: const EdgeInsets.only(right: 2),
                       width: 4, height: 4, 
                       decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                     );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
