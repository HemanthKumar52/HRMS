import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/safe_scaffold.dart';
import 'widgets/attendance_dashboard/employee_attendance_dashboard.dart';
import 'widgets/dashboard_drawer.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  // Mock Data
  final List<Map<String, dynamic>> _projects = [
    {'title': 'Office Management', 'lead': 'Anthony Lewis', 'leadImg': 'assets/images/user1.png', 'date': '14 Jan 2024', 'tasks': '8/10', 'progress': 0.8},
    {'title': 'Clinic Management', 'lead': 'Brian Villalobos', 'leadImg': 'assets/images/user2.png', 'date': '21 Feb 2024', 'tasks': '5/12', 'progress': 0.4},
    {'title': 'HR System V2', 'lead': 'Sarah Doe', 'leadImg': null, 'date': '10 Mar 2024', 'tasks': '2/20', 'progress': 0.1},
  ];

  final List<Map<String, dynamic>> _tasks = [
    {'title': 'Patient appointment booking', 'status': 'On Hold', 'assignees': 2},
    {'title': 'Appointment booking with payment', 'status': 'InProgress', 'assignees': 1},
    {'title': 'Patient and Doctor video conferencing', 'status': 'Completed', 'assignees': 3},
    {'title': 'Private chat module', 'status': 'Pending', 'assignees': 2},
  ];

  bool _showAllProjects = false;

  @override
  Widget build(BuildContext context) {
    return SafeScaffold(
      drawer: const DashboardDrawer(),
      backgroundColor: context.scaffoldBg,
      appBar: AdaptiveAppBar(
        title: 'My Tasks',
        actions: [
          IconButton(onPressed: (){}, icon: const Icon(Icons.notifications_none, color: AppColors.grey900)),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(backgroundColor: Colors.blue, child: Text('J', style: TextStyle(color: Colors.white))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Attendance Section (Merged)
            const EmployeeAttendanceDashboard(),
            const SizedBox(height: 24),

            // Projects Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Projects', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: 'Ongoing Projects',
                  underline: const SizedBox(),
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey600),
                  items: const [
                    DropdownMenuItem(value: 'Ongoing Projects', child: Text('Ongoing Projects')),
                    DropdownMenuItem(value: 'All Projects', child: Text('All Projects')),
                  ], 
                  onChanged: (val) {},
                  icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Projects Horizontal List
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _projects.length,
                separatorBuilder: (ctx, i) => const SizedBox(width: 16),
                itemBuilder: (ctx, i) => _buildProjectCard(_projects[i]),
              ),
            ),

            const SizedBox(height: 24),
            
            // Tasks Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tasks', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: 'All Projects',
                  underline: const SizedBox(),
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey600),
                  items: const [
                    DropdownMenuItem(value: 'All Projects', child: Text('All Projects')),
                  ], 
                  onChanged: (val) {},
                  icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Task List
            GlassCard(
              blur: 12,
              opacity: 0.15,
              borderRadius: 16,
              padding: EdgeInsets.zero,
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _tasks.length,
                separatorBuilder: (ctx, i) => Divider(height: 1, color: AppColors.grey200),
                itemBuilder: (ctx, i) => _buildTaskItem(_tasks[i]),
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 24),
            
            const SizedBox(height: 24),
            
            // Timesheet Logs (New Section)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text('Timesheet Logs', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                 TextButton.icon(
                   onPressed: (){}, 
                   icon: const Icon(Icons.add, size: 16),
                   label: Text('Log Time', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.blue))
                 ),
              ],
            ),
            const SizedBox(height: 8),
            
            GlassCard(
              blur: 12,
              opacity: 0.15,
              borderRadius: 16,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                   _buildTimesheetItem('HR System V2', 'Developing API endpoints', '4h 30m'),
                   Divider(height: 1, color: AppColors.grey200),
                   _buildTimesheetItem('Office Management', 'Team meeting & Planning', '1h 15m'),
                   Divider(height: 1, color: AppColors.grey200),
                   _buildTimesheetItem('Clinic Management', 'Bug fixes for payment gateway', '2h 45m'),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms),
             const SizedBox(height: 80), // Bottom padding for navbar
          ],
        ),
      ),
    );
  }

  Widget _buildTimesheetItem(String project, String task, String time) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(task, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(time, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildProjectCard(Map<String, dynamic> project) {
    return SizedBox(
      width: 280,
      child: GlassCard(
      blur: 12,
      opacity: 0.15,
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text(project['title'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
               const Icon(Icons.more_vert, color: Colors.grey, size: 20),
             ],
           ),
           const SizedBox(height: 16),
           Row(
             children: [
               CircleAvatar(
                 radius: 16,
                 backgroundColor: Colors.orange.withOpacity(0.2),
                 // backgroundImage: project['leadImg'] != null ? AssetImage(project['leadImg']) : null, // removed asset usage for safety
                 child: project['leadImg'] == null ? const Icon(Icons.person, color: Colors.orange, size: 16) : null, 
               ),
               const SizedBox(width: 12),
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Text(project['lead'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('Project Leader', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                 ],
               ),
             ],
           ),
           const SizedBox(height: 12),
           Row(
             children: [
                _buildTag(Icons.calendar_today, project['date'], Colors.blue),
                const SizedBox(width: 8),
                _buildTag(Icons.playlist_add_check, 'Tasks : ${project['tasks']}', Colors.green),
             ],
           ),
           const SizedBox(height: 12),
           ClipRRect(
             borderRadius: BorderRadius.circular(2),
             child: LinearProgressIndicator(
               value: project['progress'],
               backgroundColor: AppColors.grey200,
               valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
               minHeight: 4,
             ),
           ),
        ],
      ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey700)),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task) {
    Color statusColor = Colors.grey;
    Color statusBg = Colors.grey.withOpacity(0.1);
    
    switch(task['status']) {
      case 'On Hold': 
        statusColor = Colors.red; 
        statusBg = Colors.red.withOpacity(0.1);
        break;
      case 'InProgress': 
        statusColor = Colors.purple; 
        statusBg = Colors.purple.withOpacity(0.1);
        break;
      case 'Completed': 
        statusColor = Colors.green; 
        statusBg = Colors.green.withOpacity(0.1);
        break;
       case 'Pending': 
        statusColor = Colors.blue; 
        statusBg = Colors.blue.withOpacity(0.1);
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            height: 24, width: 24,
            child: Checkbox(
              value: false, 
              onChanged: (val){},
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(task['title'], style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
             decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
             child: Text(task['status'], style: GoogleFonts.poppins(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          // Stacked avatars
          SizedBox(
            width: 40,
            height: 24, // simplified
            child: Stack(
              children: [
                 Positioned(left: 0, child: CircleAvatar(radius: 12, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 12, color: Colors.white))),
                 Positioned(left: 15, child: CircleAvatar(radius: 12, backgroundColor: Colors.black, child: Icon(Icons.person, size: 12, color: Colors.white))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
