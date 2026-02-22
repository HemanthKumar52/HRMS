import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/safe_scaffold.dart';
import 'widgets/recruitment_dashboard/candidates_analysis_card.dart';
import 'widgets/recruitment_dashboard/recruitment_overview_card.dart';
import 'widgets/recruitment_dashboard/quick_reminder_card.dart';
import 'widgets/recruitment_dashboard/upcoming_schedules_list.dart';
import 'widgets/dashboard_drawer.dart';

class RecruitmentDashboardScreen extends StatelessWidget {
  const RecruitmentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeScaffold(
      drawer: const DashboardDrawer(),
      backgroundColor: context.scaffoldBg,
      appBar: AdaptiveAppBar(
        title: 'Recruitment Dashboard',
        actions: [
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add New Job'),
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
            // Stage Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStageStat(Icons.work_outline, '47', 'Open Positions', Colors.deepOrange),
                _buildStageStat(Icons.people_outline, '2,384', 'Total Candidates', const Color(0xFF004D40)),
                _buildStageStat(Icons.calendar_today, '12', 'Interviews Today', const Color(0xFF455A64)),
                _buildStageStat(Icons.check_circle_outline, '28', 'Offers Released', Colors.blue),
              ].map((e) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: e))).toList(),
            ).animate().fadeIn().slideX(),
            const SizedBox(height: 16),
            
            const CandidatesAnalysisCard().animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            const SizedBox(height: 16),
            
            // Overview & Schedules Column
            const RecruitmentOverviewCard().animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
            const SizedBox(height: 16),
            const QuickReminderCard().animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: 16),
            
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: UpcomingSchedulesList(),
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
            
            const SizedBox(height: 16),
            
            // AI Assistant
             GlassCard(
               blur: 12,
               opacity: 0.15,
               borderRadius: 16,
               padding: const EdgeInsets.all(16),
               child: Column(
                 children: [
                   Container(
                     padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(color: Colors.deepOrange.withOpacity(0.1), shape: BoxShape.circle),
                     child: const Icon(Icons.psychology, color: Colors.deepOrange),
                   ),
                   const SizedBox(height: 8),
                   Text('How can I help you today?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                   Text('AI Recruitment Assistant', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey600)),
                   const SizedBox(height: 16),
                   Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(8)),
                     child: Row(
                       children: [
                         const Icon(Icons.auto_awesome, size: 16, color: Colors.deepOrange),
                         const SizedBox(width: 8),
                         Expanded(child: Text('Generate hiring report for Senior Developer role', style: GoogleFonts.poppins(fontSize: 12))),
                       ],
                     ),
                   ),
                 ],
               ),
             ).animate().fadeIn(delay: 600.ms),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStageStat(IconData icon, String value, String label, Color color) {
    return GlassCard(
      blur: 12,
      opacity: 0.15,
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.grey900)),
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey500), textAlign: TextAlign.center, maxLines: 1),
        ],
      ),
    );
  }
}
