import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../core/theme/app_colors.dart';
import 'widgets/payroll_dashboard/payroll_overview_header.dart';
import 'widgets/payroll_dashboard/payroll_charts_section.dart';
import 'widgets/dashboard_drawer.dart';

class PayrollDashboardScreen extends StatelessWidget {
  const PayrollDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DashboardDrawer(),
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          'Payroll Dashboard',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.grey900,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Run Payroll'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE65100), // Orange
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
            const PayrollOverviewHeader().animate().fadeIn().slideY(),
            const SizedBox(height: 16),
             const PayrollChartsSection().animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
             const SizedBox(height: 16),
             // Placeholder for Pipeline/Steps
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: AppColors.grey200),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text('Payroll Processing Pipeline', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    // Simplified visual pipeline
                    LinearProgressIndicator(
                      value: 0.4,
                      backgroundColor: AppColors.grey200,
                      color: const Color(0xFF00695C), // Teal
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Text('Processing 4 to 6', style: GoogleFonts.poppins(color: AppColors.grey600, fontSize: 12)),
                 ],
               ),
             ).animate().fadeIn(delay: 400.ms),
             const SizedBox(height: 16),
             
             // Recent Payslips
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: AppColors.grey200),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text('Recent Payslips', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                       TextButton(onPressed: () {}, child: const Text('View All')),
                     ],
                   ),
                   const SizedBox(height: 8),
                   _buildPayslipItem(context, 'October 2024', '₹ 85,000'),
                   const Divider(),
                   _buildPayslipItem(context, 'September 2024', '₹ 85,000'),
                   const Divider(),
                   _buildPayslipItem(context, 'August 2024', '₹ 82,500'),
                 ],
               ),
             ).animate().fadeIn(delay: 500.ms),
             
             const SizedBox(height: 16),
             // AI Assistant Fab look-alike or card
             Card(
               color: const Color(0xFFFFF3E0), // Light Orange
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.black,
                        child: Icon(Icons.auto_awesome, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('How can I help you today?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                            Text('AI Payroll Assistant', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey700)),
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

  Widget _buildPayslipItem(BuildContext context, String month, String amount) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.picture_as_pdf, color: Colors.red),
      ),
      title: Text(month, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      subtitle: Text('Net Pay: $amount', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
      trailing: IconButton(
        icon: const Icon(Icons.download_rounded, color: AppColors.primary),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloading Payslip for $month...')));
        },
      ),
    );
  }
}
