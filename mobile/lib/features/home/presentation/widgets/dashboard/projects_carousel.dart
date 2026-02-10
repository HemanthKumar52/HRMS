import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';

class ProjectsList extends StatelessWidget {
  const ProjectsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Projects',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ),
             Row(
               children: [
                 Text('Ongoing Projects', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey600)),
                 const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.grey600),
               ],
             ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _ProjectCard(
                title: 'Office Management',
                projectLeader: 'Anthony Lewis',
                deadline: '14 Jan 2024',
                tasks: '8/10',
                progress: 0.8,
                color: AppColors.primary,
              ),
              _ProjectCard(
                title: 'Clinic Management',
                projectLeader: 'Brian Villalobos',
                deadline: '21 Feb 2024',
                tasks: '8/15',
                progress: 0.5,
                color: Colors.pink,
              ),
              _ProjectCard(
                title: 'School Management',
                projectLeader: 'David Lee',
                deadline: '01 Mar 2024',
                tasks: '8/20',
                progress: 0.4,
                color: Colors.orange,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final String title;
  final String projectLeader;
  final String deadline;
  final String tasks;
  final double progress;
  final Color color;

  const _ProjectCard({
    required this.title,
    required this.projectLeader,
    required this.deadline,
    required this.tasks,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Icon(Icons.more_vert, size: 18, color: AppColors.grey500),
            ],
          ),
          Row(
            children: [
              const CircleAvatar(
                radius: 12,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=1'), // Placeholder
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    projectLeader,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Project Leader',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _buildDateItem(Icons.calendar_today, deadline, color),
              const SizedBox(width: 16),
              _buildDateItem(Icons.playlist_add_check, 'Tasks : $tasks', Colors.green),
            ],
          ),
           LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.grey200,
              valueColor: AlwaysStoppedAnimation(color),
              borderRadius: BorderRadius.circular(4),
           ),
        ],
      ),
    );
  }

  Widget _buildDateItem(IconData icon, String text, Color color) {
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
       decoration: BoxDecoration(
         color: AppColors.grey50,
         borderRadius: BorderRadius.circular(4),
       ),
       child: Row(
         children: [
           Icon(icon, size: 14, color: color),
           const SizedBox(width: 4),
           Text(
             text,
             style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey700),
           ),
         ],
       ),
     );
  }
}
