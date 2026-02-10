import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class UpcomingSchedulesList extends StatelessWidget {
  const UpcomingSchedulesList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Upcoming Schedules', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const Icon(Icons.calendar_today, size: 16, color: AppColors.grey600),
          ],
        ),
        const SizedBox(height: 16),
        _buildItem('Product Designer', '02', 'Mar', 'https://i.pravatar.cc/150?u=20'),
        const SizedBox(height: 12),
        _buildItem('Marketing Manager', '22', 'Apr', 'https://i.pravatar.cc/150?u=21'),
        const SizedBox(height: 12),
        _buildItem('Sr. Data Science', '11', 'May', 'https://i.pravatar.cc/150?u=22'),
        const SizedBox(height: 12),
        _buildItem('Software Engineer', '07', 'Jun', 'https://i.pravatar.cc/150?u=23'),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
            child: const Text('View All Schedule'),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(String role, String day, String month, String imgUrl) {
    return Row(
      children: [
        Container(
          width: 40,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              Text(month, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey600)),
              Text(day, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.grey900)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(role, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
              Text('09:00 AM - 10:30 AM', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.grey500)),
            ],
          ),
        ),
        CircleAvatar(radius: 14, backgroundImage: NetworkImage(imgUrl)),
      ],
    );
  }
}
