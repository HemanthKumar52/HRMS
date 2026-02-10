import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';

class TasksList extends StatelessWidget {
  const TasksList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tasks',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ),
             Row(
               children: [
                 Text('All Projects', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey600)),
                 const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.grey600),
               ],
             ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Column(
            children: [
              _TaskItem(
                title: 'Patient appointment booking',
                status: 'On Hold',
                statusColor: Colors.pink,
                participants: const ['https://i.pravatar.cc/150?u=2', 'https://i.pravatar.cc/150?u=3'],
              ),
              const Divider(height: 1, color: AppColors.grey100),
              _TaskItem(
                title: 'Appointment booking with payment',
                status: 'InProgress',
                statusColor: Colors.purple,
                participants: const ['https://i.pravatar.cc/150?u=4'],
              ),
              const Divider(height: 1, color: AppColors.grey100),
              _TaskItem(
                title: 'Patient and Doctor video conferencing',
                status: 'Completed',
                statusColor: Colors.green,
                participants: const ['https://i.pravatar.cc/150?u=5', 'https://i.pravatar.cc/150?u=6', 'https://i.pravatar.cc/150?u=7'],
              ),
              const Divider(height: 1, color: AppColors.grey100),
              _TaskItem(
                title: 'Private chat module',
                status: 'Pending',
                statusColor: Colors.blue,
                participants: const ['https://i.pravatar.cc/150?u=8', 'https://i.pravatar.cc/150?u=9'],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TaskItem extends StatelessWidget {
  final String title;
  final String status;
  final Color statusColor;
  final List<String> participants;

  const _TaskItem({
    required this.title,
    required this.status,
    required this.statusColor,
    required this.participants,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
           Container(
             width: 16,
             height: 16,
             decoration: BoxDecoration(
               border: Border.all(color: AppColors.grey300),
               borderRadius: BorderRadius.circular(4),
             ),
             child: const Icon(Icons.check, size: 12, color: Colors.transparent), // Checkbox placeholder
           ),
           const SizedBox(width: 12),
           Expanded(
             child: Text(
               title,
               style: GoogleFonts.poppins(
                 fontSize: 13,
                 color: AppColors.grey800,
                 fontWeight: FontWeight.w500,
               ),
             ),
           ),
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
             decoration: BoxDecoration(
               color: statusColor.withOpacity(0.1),
               borderRadius: BorderRadius.circular(12),
             ),
             child: Text(
               status,
               style: GoogleFonts.poppins(
                 fontSize: 10,
                 color: statusColor,
                 fontWeight: FontWeight.w600,
               ),
             ),
           ),
           const SizedBox(width: 8),
           SizedBox(
             width: 40,
             height: 24,
             child: Stack(
               children: List.generate(
                 participants.length > 2 ? 3 : participants.length,
                 (index) => Positioned(
                   left: index * 12.0,
                   child: CircleAvatar(
                     radius: 12,
                     backgroundColor: Colors.white,
                     child: CircleAvatar(
                       radius: 10,
                       backgroundImage: NetworkImage(participants[index]),
                     ),
                   ),
                 ),
               ),
             ),
           ),
        ],
      ),
    );
  }
}
