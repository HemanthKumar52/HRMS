import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../auth/providers/auth_provider.dart';
class DashboardDrawer extends ConsumerWidget {
  const DashboardDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final user = ref.watch(currentUserProvider);
    final role = user?.role;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.firstName != null ? '${user!.firstName} ${user.lastName}' : 'HRMS User',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  role == 'HR_ADMIN' ? 'HR Administrator' :
                  role == 'MANAGER' ? 'Manager' : 'Employee',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Role-Based Menu Items
          ..._buildRoleBasedItems(context, role, currentRoute),
        ],
      ),
    );
  }

  List<Widget> _buildRoleBasedItems(BuildContext context, String? role, String currentRoute) {
    if (role == 'HR_ADMIN') {
      return [
        _buildSectionHeader(context, 'HR Management'),
        _buildDrawerItem(context, icon: Icons.dashboard_outlined, label: 'HR Dashboard', route: '/', isSelected: currentRoute == '/'),
        _buildDrawerItem(context, icon: Icons.chat_bubble_outline, label: 'Chat', route: '/directory', isSelected: currentRoute == '/directory'),
        _buildDrawerItem(context, icon: Icons.attach_money_outlined, label: 'Payroll', route: '/payroll-dashboard', isSelected: currentRoute == '/payroll-dashboard'),
        _buildDrawerItem(context, icon: Icons.analytics_outlined, label: 'Reports', route: '/hr-dashboard', isSelected: currentRoute == '/hr-dashboard'),
        const Divider(),
         _buildSectionHeader(context, 'Personal'),
        _buildDrawerItem(context, icon: Icons.timer_outlined, label: 'My Attendance', route: '/attendance-dashboard', isSelected: currentRoute == '/attendance-dashboard'),
        _buildDrawerItem(context, icon: Icons.calendar_today_outlined, label: 'My Leave', route: '/leave-dashboard', isSelected: currentRoute == '/leave-dashboard'),
      ];
    } else if (role == 'MANAGER') {
      return [
        _buildSectionHeader(context, 'Manager Portal'),
        _buildDrawerItem(context, icon: Icons.dashboard_outlined, label: 'Manager Dashboard', route: '/', isSelected: currentRoute == '/'),
        _buildDrawerItem(context, icon: Icons.chat_bubble_outline, label: 'Team Chat', route: '/directory', isSelected: currentRoute == '/directory'),
        _buildDrawerItem(context, icon: Icons.playlist_add_check, label: 'Approvals', route: '/approvals', isSelected: currentRoute == '/approvals'),
        const Divider(),
        _buildSectionHeader(context, 'Personal'),
        _buildDrawerItem(context, icon: Icons.timer_outlined, label: 'My Attendance', route: '/attendance-dashboard', isSelected: currentRoute == '/attendance-dashboard'),
        _buildDrawerItem(context, icon: Icons.calendar_today_outlined, label: 'My Leave', route: '/leave-dashboard', isSelected: currentRoute == '/leave-dashboard'),
      ];
    } else if (role == 'ADMIN') {
       return [
        _buildSectionHeader(context, 'System Administration'),
        _buildDrawerItem(context, icon: Icons.admin_panel_settings_outlined, label: 'IT Dashboard', route: '/', isSelected: currentRoute == '/'),
        _buildDrawerItem(context, icon: Icons.settings_input_component, label: 'System Config', route: '/it-admin-dashboard', isSelected: currentRoute == '/it-admin-dashboard'),
       ];
    }

    // Default: EMPLOYEE
    return [
      _buildSectionHeader(context, 'Employee Portal'),
      _buildDrawerItem(context, icon: Icons.home_outlined, label: 'Home', route: '/', isSelected: currentRoute == '/'),
      _buildDrawerItem(context, icon: Icons.fingerprint, label: 'My Attendance', route: '/attendance', isSelected: currentRoute == '/attendance'),
      _buildDrawerItem(context, icon: Icons.assignment_outlined, label: 'My Requests', route: '/requests', isSelected: currentRoute == '/requests'),
    ];
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: context.textTertiary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required bool isSelected,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : context.textSecondary,
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          color: isSelected ? AppColors.primary : context.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
      onTap: () {
        context.pop(); // Close drawer
        if (!isSelected) {
          if (route == '/') {
            context.go(route);
          } else {
            context.go(route); // Use go for shell routes to stay within bottom nav
          }
        }
      },
    );
  }
}
