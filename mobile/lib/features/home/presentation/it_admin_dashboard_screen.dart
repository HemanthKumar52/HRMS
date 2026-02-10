import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';
import 'widgets/it_admin_dashboard/system_uptime_card.dart';
import 'widgets/it_admin_dashboard/storage_usage_chart.dart';
import 'widgets/it_admin_dashboard/peak_hours_card.dart';
import 'widgets/it_admin_dashboard/login_count_chart.dart';
import 'widgets/it_admin_dashboard/security_compliance_stats.dart';
import 'widgets/it_admin_dashboard/hrms_usage_trend_chart.dart';
import 'widgets/dashboard_drawer.dart';

class ItAdminDashboardScreen extends StatelessWidget {
  const ItAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DashboardDrawer(),
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          'IT Admin Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.grey900),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          _buildStatusChip('Active Users', '248', Colors.green),
          const SizedBox(width: 8),
          _buildStatusChip('Security Alerts', '3', Colors.red),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SystemUptimeCard().animate().fadeIn().slideX(),
            const SizedBox(height: 16),
            
            // Storage and MFA side by side on large screens
            LayoutBuilder(builder: (context, constraints) {
               if (constraints.maxWidth > 900) {
                 return Row(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Expanded(flex: 2, child: StorageUsageChart()),
                     const SizedBox(width: 16),
                     // Placeholder for MFA Enabled Users Card if separate, or Quick Actions
                     Expanded(child: _buildQuickActionsCard()),
                   ],
                 );
               } else {
                 return Column(
                   children: [
                     const StorageUsageChart(),
                     const SizedBox(height: 16),
                     _buildQuickActionsCard(),
                   ],
                 );
               }
            }).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 16),
            
            // User Access (Peak Hours)
            const PeakHoursCard().animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            const SizedBox(height: 16),
            
            // Login Count Analysis
            const LoginCountChart().animate().fadeIn(delay: 300.ms),
             const SizedBox(height: 16),

            // Bottom Grid: Usage Trend, Roles, Security, Integration Errors
             LayoutBuilder(builder: (context, constraints) {
               // On wide screens we can do 2 columns
               if (constraints.maxWidth > 900) {
                 return Column(
                   children: [
                     Row(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         const Expanded(flex: 3, child: HrmsUsageTrendChart()), // Usage Trend
                         const SizedBox(width: 16),
                         Expanded(flex: 2, child: _buildUserRolesCard()), // User Roles
                       ],
                     ),
                     const SizedBox(height: 16),
                     Row(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          const Expanded(flex: 1, child: SecurityComplianceStats()),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: _buildIntegrationErrorHeatmap()),
                       ],
                     ),
                   ],
                 );
               } else {
                 return Column(
                   children: [
                     const HrmsUsageTrendChart(),
                     const SizedBox(height: 16),
                     _buildUserRolesCard(),
                     const SizedBox(height: 16),
                     const SecurityComplianceStats(),
                     const SizedBox(height: 16),
                     _buildIntegrationErrorHeatmap(),
                   ],
                 );
               }
             }).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.grey200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick IT Actions', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: [
                _buildActionBtn('Restart Services', Icons.refresh),
                _buildActionBtn('Clear Cache', Icons.cleaning_services),
                _buildActionBtn('Run Backup', Icons.backup),
                _buildActionBtn('Sync Biometric', Icons.fingerprint),
                _buildActionBtn('Schedule Maint.', Icons.schedule),
                _buildActionBtn('Stop Jobs', Icons.stop_circle_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRolesCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.grey200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User Roles Distribution', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            // Simple stacked bar or just color bars
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  Expanded(flex: 60, child: Container(height: 20, color: Colors.deepOrange)), // Employees
                  Expanded(flex: 20, child: Container(height: 20, color: const Color(0xFF264653))), // Managers
                  Expanded(flex: 10, child: Container(height: 20, color: Colors.black87)), // Ops
                  Expanded(flex: 5, child: Container(height: 20, color: Colors.amber)), // Admins
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              children: [
                _legendItem('Employees', '2145', Colors.deepOrange),
                _legendItem('Managers', '234', const Color(0xFF264653)),
                _legendItem('Ops', '45', Colors.black87),
                _legendItem('Admins', '12', Colors.amber),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegrationErrorHeatmap() {
    // Placeholder for grid
    return Card(
      elevation: 0,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.grey200)),
      child: Padding(
         padding: const EdgeInsets.all(20),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text('Integration Error Counts (24h)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
             const SizedBox(height: 16),
             // A simple grid of colored boxes
             GridView.builder(
               shrinkWrap: true,
               physics: const NeverScrollableScrollPhysics(),
               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                 crossAxisCount: 12,
                 crossAxisSpacing: 4,
                 mainAxisSpacing: 4,
               ),
               itemCount: 48, // 4 rows x 12
               itemBuilder: (context, index) {
                  // Randomly color some boxes
                  Color color = AppColors.grey100;
                  if (index % 7 == 0) color = Colors.orange;
                  if (index % 11 == 0) color = Colors.deepOrange;
                  
                  return Container(
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                  );
               },
             ),
           ],
         ),
      ),
    );
  }

  Widget _legendItem(String label, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Container(height: 2, width: 20, color: color, margin: const EdgeInsets.only(top: 2, bottom: 2)),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildStatusChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 4),
          Text('$label $value', style: GoogleFonts.poppins(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  
  Widget _buildActionBtn(String label, IconData icon) {
    return Column(
      children: [
        CircleAvatar(
           backgroundColor: AppColors.grey900,
           child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 10)),
      ],
    );
  }
}
