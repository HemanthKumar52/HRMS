import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/providers/work_mode_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../attendance/providers/attendance_provider.dart';
import '../../leave/providers/leave_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import 'widgets/dashboard/attendance_timer_card.dart';
import 'widgets/dashboard/leave_details_card.dart';
import 'widgets/dashboard/dashboard_stats_grid.dart';
import 'widgets/dashboard/performance_card.dart';
import 'widgets/dashboard/skills_card.dart';
import 'widgets/dashboard/projects_carousel.dart';
import 'widgets/dashboard/tasks_list.dart';
import 'widgets/dashboard_drawer.dart';
import 'widgets/status_timeline_widget.dart';
import 'widgets/salary_info_card.dart';
import 'widgets/dashboards/employee_dashboard.dart';
import 'widgets/dashboards/manager_dashboard.dart';
import 'widgets/dashboards/admin_dashboard.dart';
import 'widgets/dashboards/hr_dashboard.dart'; // Add this import

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    // Removed backend providers to prevent 401 errors
    // final todayStatusAsync = ref.watch(todayStatusProvider);
    // final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      drawer: const DashboardDrawer(),
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          user?.role == 'HR_ADMIN' ? 'HR Dashboard' : 
          user?.role == 'MANAGER' ? 'Manager Dashboard' : 
          user?.role == 'ADMIN' ? 'System Admin' :
          'Employee Dashboard',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.grey900,
          ),
        ),
        actions: [
          // Work Mode Indicator
          Consumer(
            builder: (context, ref, child) {
              final workMode = ref.watch(workModeProvider);
              final workModeIcon = workMode == 'OFFICE' ? Icons.business :
                                  workMode == 'REMOTE' ? Icons.home :
                                  workMode == 'ON_DUTY' ? Icons.directions_car :
                                  Icons.help_outline;
              final workModeColor = workMode == 'OFFICE' ? Colors.blue :
                                   workMode == 'REMOTE' ? Colors.green :
                                   workMode == 'ON_DUTY' ? Colors.orange :
                                   Colors.grey;
              
              return IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: workModeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(workModeIcon, color: workModeColor, size: 20),
                ),
                tooltip: 'Work Mode: ${workMode ?? "Not Set"}',
                onPressed: () {
                  // Show dialog to change work mode
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Change Work Mode'),
                      content: Text('Current mode: ${workMode ?? "Not Set"}\n\nDo you want to select a different work mode?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.go('/work-mode');
                          },
                          child: const Text('Change Mode'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),

          IconButton(
            icon: CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 16,
              child: Text(
                user?.firstName?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            onPressed: () => _showProfileMenu(context, ref),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (user == null) return const Center(child: CircularProgressIndicator());
          
          switch (user.role) {
            case 'HR_ADMIN':
              return const HRDashboard();
            case 'ADMIN':
              return const AdminDashboard();
            case 'MANAGER':
              return const ManagerDashboard();
            default:
              return const EmployeeDashboard();
          }
        }
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, dynamic notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: GoogleFonts.poppins(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          notification.body,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            color: AppColors.grey500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
  Widget _buildQuickAction(BuildContext context, String label, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        if (label == 'Raise Ticket') {
          context.push('/create-ticket');
        } else if (label == 'Submit Claim') {
           context.push('/create-claim');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature coming soon!')));
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    final user = ref.read(currentUserProvider);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 40,
              child: Text(
                user?.firstName?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(color: Colors.white, fontSize: 32),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${user?.firstName ?? ''} ${user?.lastName ?? ''}',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user?.role ?? 'EMPLOYEE',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.person_outline, color: AppColors.primary),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                context.push('/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: AppColors.primary),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authStateProvider.notifier).logout();
                await ref.read(workModeProvider.notifier).clearWorkMode();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
