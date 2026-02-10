import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class ActivityFeedCard extends StatelessWidget {
  const ActivityFeedCard({super.key});

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
                Text('Activity Feed', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                Container(
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                   decoration: BoxDecoration(border: Border.all(color: AppColors.grey300), borderRadius: BorderRadius.circular(4)),
                   child: Row(
                     children: [
                       const Icon(Icons.calendar_today, size: 12, color: AppColors.grey600),
                       const SizedBox(width: 4),
                       Text('Today', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey600)),
                     ],
                   ),
                 ),
              ],
            ),
          ),
          const Divider(height: 1),
          _item('Michael Chen replied to TK-1247', 'Added troubleshooting steps for connect', '5 min ago', Colors.deepOrange, Icons.chat_bubble_outline),
          _item('New ticket assigned to Sarah Johnson', 'TK-1248: Network connectivity issues', '12 min ago', Colors.blue, Icons.assignment_ind_outlined),
          _item('TK-1240 marked as resolved', 'Password reset completed successfully', '34 min ago', Colors.green, Icons.check_circle_outline),
          _item('SLA deadline approaching', 'TK-1239 has 2 hours remaining', '45 min ago', Colors.red, Icons.timer_outlined),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
               width: double.infinity,
               child: OutlinedButton(
                 onPressed: (){},
                 child: const Text('View All Activity'),
               ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(String title, String sub, String time, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(title, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                 Text(sub, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.grey600)),
                 const SizedBox(height: 4),
                 Text(time, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey400)),
               ],
            ),
          ),
        ],
      ),
    );
  }
}
