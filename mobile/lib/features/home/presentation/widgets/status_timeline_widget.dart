import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class StatusTimelineWidget extends StatelessWidget {
  const StatusTimelineWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.grey200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Request Status', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 16),
            _buildTimelineItem(
              title: 'Sick Leave Request',
              date: 'Applied on 24 Oct, 2024',
              status: 'Approved',
              color: Colors.green,
              isLast: false,
            ),
             _buildTimelineItem(
              title: 'October Payslip',
              date: 'Generated on 01 Nov, 2024',
              status: 'Ready',
              color: Colors.blue,
              isLast: false,
            ),
             _buildTimelineItem(
              title: 'IT Support Ticket #204',
              date: 'Raised on 02 Nov, 2024',
              status: 'Pending',
              color: Colors.orange,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({required String title, required String date, required String status, required Color color, required bool isLast}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12, height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            if (!isLast)
              Container(width: 2, height: 40, color: AppColors.grey200),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              Text(date, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey500)),
              const SizedBox(height: 4),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                 decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                 child: Text(status, style: GoogleFonts.poppins(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
               ),
               const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
