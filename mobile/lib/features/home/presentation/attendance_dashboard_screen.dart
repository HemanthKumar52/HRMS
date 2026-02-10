import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';
import 'widgets/attendance_dashboard/employee_attendance_dashboard.dart';
import 'widgets/dashboard_drawer.dart';

class AttendanceDashboardScreen extends StatelessWidget {
  const AttendanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DashboardDrawer(),
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          'Attendance Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.grey900),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          FilledButton.icon(
             onPressed: () {},
             icon: const Icon(Icons.add_task, size: 16),
             label: const Text('Apply Leave'),
             style: FilledButton.styleFrom(
               backgroundColor: Colors.deepOrange,
               visualDensity: VisualDensity.compact,
             ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const EmployeeAttendanceDashboard(),
             const SizedBox(height: 16),
            
            // AI Assistant
             Card(
               color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                        child: const Icon(Icons.auto_awesome, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AI Assistant', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                            Text('Always here to help', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey600)),
                          ],
                        ),
                      ),
                       const Chip(label: Text('Online', style: TextStyle(color: Colors.white, fontSize: 10)), backgroundColor: Colors.green, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                    ],
                  ),
                ),
             ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }
}
