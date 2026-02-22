import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/widgets/glass_card.dart';

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
                color: context.textPrimary,
              ),
            ),
             Row(
               children: [
                 Text('All Projects', style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary)),
                 Icon(Icons.keyboard_arrow_down, size: 16, color: context.textSecondary),
               ],
             ),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          blur: 12,
          opacity: 0.15,
          borderRadius: 16,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              const _TaskItem(
                title: 'Patient appointment booking',
                status: 'On Hold',
                statusColor: Colors.pink,
                participants: ['https://i.pravatar.cc/150?u=2', 'https://i.pravatar.cc/150?u=3'],
              ),
              Divider(height: 1, color: context.dividerColor),
              const _TaskItem(
                title: 'Appointment booking with payment',
                status: 'InProgress',
                statusColor: Colors.purple,
                participants: ['https://i.pravatar.cc/150?u=4'],
              ),
              Divider(height: 1, color: context.dividerColor),
              const _TaskItem(
                title: 'Patient and Doctor video conferencing',
                status: 'Completed',
                statusColor: Colors.green,
                participants: ['https://i.pravatar.cc/150?u=5', 'https://i.pravatar.cc/150?u=6', 'https://i.pravatar.cc/150?u=7'],
              ),
              Divider(height: 1, color: context.dividerColor),
              const _TaskItem(
                title: 'Private chat module',
                status: 'Pending',
                statusColor: Colors.blue,
                participants: ['https://i.pravatar.cc/150?u=8', 'https://i.pravatar.cc/150?u=9'],
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
               border: Border.all(color: context.borderColor),
               borderRadius: BorderRadius.circular(4),
             ),
             child: const Icon(Icons.check, size: 12, color: Colors.transparent),
           ),
           const SizedBox(width: 12),
           Expanded(
             child: Text(
               title,
               style: GoogleFonts.poppins(
                 fontSize: 13,
                 color: context.textPrimary,
                 fontWeight: FontWeight.w500,
               ),
             ),
           ),
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
             decoration: BoxDecoration(
               color: statusColor.withValues(alpha: 0.1),
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
                     backgroundColor: context.surfaceBg,
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
