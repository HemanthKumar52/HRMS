import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/widgets/glass_card.dart';
import 'widgets/hr_dashboard/employee_status_card.dart';
import 'widgets/hr_dashboard/hr_overview_grid.dart';
import 'widgets/hr_dashboard/hr_charts_section.dart';
import 'widgets/dashboard_drawer.dart';

class HrDashboardScreen extends StatelessWidget {
  const HrDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DashboardDrawer(),
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          'HR Dashboard',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.grey900,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined, color: AppColors.grey600),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add New'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A65), // Orange
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const EmployeeStatusCard().animate().fadeIn().slideX(),
            const SizedBox(height: 16),
            const HrOverviewGrid().animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            const SizedBox(height: 16),
            const HrChartsSection().animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: 16),
            // Recruitment & Upcoming Interviews could go here
            // Just placeholder for now
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text('Upcoming Interview', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                subtitle: const Text('UI/UX Design Interview - 12:30 PM'),
                trailing: const CircleAvatar(
                   backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=10'),
                ),
              ),
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }
}
