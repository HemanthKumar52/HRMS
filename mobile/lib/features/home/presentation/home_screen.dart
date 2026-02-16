import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/responsive.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/providers/work_mode_provider.dart';
import 'widgets/dashboard_drawer.dart';
import 'widgets/dashboards/employee_dashboard.dart';
import 'widgets/dashboards/manager_dashboard.dart';
import 'widgets/dashboards/admin_dashboard.dart';
import 'widgets/dashboards/hr_dashboard.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Responsive.init(context);
    final user = ref.watch(currentUserProvider);

    return SafeScaffold(
      drawer: const DashboardDrawer(),
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AdaptiveAppBar(
        title: user?.role == 'HR_ADMIN'
            ? 'HR Dashboard'
            : user?.role == 'MANAGER'
                ? 'Manager Dashboard'
                : user?.role == 'ADMIN'
                    ? 'System Admin'
                    : 'Employee Dashboard',
        actions: [
          IconButton(
            icon: CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: Responsive.value(mobile: 16.0, tablet: 18.0),
              child: Text(
                user?.firstName?.substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Responsive.sp(14),
                ),
              ),
            ),
            onPressed: () => _showProfileMenu(context, ref),
          ),
          SizedBox(width: Responsive.horizontalPadding),
        ],
      ),
      body: ResponsiveBuilder(
        builder: (context, deviceType, orientation) {
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Use ResponsiveContainer for tablets to constrain width
          Widget dashboard;
          switch (user.role) {
            case 'HR_ADMIN':
              dashboard = const HRDashboard();
              break;
            case 'ADMIN':
              dashboard = const AdminDashboard();
              break;
            case 'MANAGER':
              dashboard = const ManagerDashboard();
              break;
            default:
              dashboard = const EmployeeDashboard();
          }

          // On tablets, wrap in a constrained container
          if (deviceType == DeviceType.tablet) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: orientation == Orientation.landscape ? 900 : 600,
                ),
                child: dashboard,
              ),
            );
          }

          return dashboard;
        },
      ),
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    final user = ref.read(currentUserProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Responsive.cardRadius * 1.5),
        ),
      ),
      builder: (context) => SafeArea(
        child: Container(
          padding: EdgeInsets.all(Responsive.horizontalPadding * 1.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              CircleAvatar(
                backgroundColor: AppColors.primary,
                radius: Responsive.value(mobile: 40.0, tablet: 48.0),
                child: Text(
                  user?.firstName?.substring(0, 1).toUpperCase() ?? 'U',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.sp(28),
                  ),
                ),
              ),
              SizedBox(height: Responsive.verticalPadding),
              Text(
                '${user?.firstName ?? ''} ${user?.lastName ?? ''}',
                style: GoogleFonts.poppins(
                  fontSize: Responsive.sp(20),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? '',
                style: GoogleFonts.poppins(
                  fontSize: Responsive.sp(14),
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
                    fontSize: Responsive.sp(12),
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: Responsive.verticalPadding * 1.5),
              _buildMenuTile(
                icon: Icons.person_outline,
                title: 'View Profile',
                onTap: () {
                  Navigator.pop(context);
                  context.push('/profile');
                },
              ),
              _buildMenuTile(
                icon: Icons.people_outline,
                title: 'Directory',
                onTap: () {
                  Navigator.pop(context);
                  context.push('/directory');
                },
              ),
              _buildMenuTile(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () {
                  Navigator.pop(context);
                  context.push('/settings');
                },
              ),
              const Divider(),
              _buildMenuTile(
                icon: Icons.logout,
                title: 'Logout',
                iconColor: Colors.red,
                textColor: Colors.red,
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authStateProvider.notifier).logout();
                  await ref.read(workModeProvider.notifier).clearWorkMode();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
              SizedBox(height: Responsive.bottomSafeArea > 0 ? 0 : 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? AppColors.primary,
        size: Responsive.iconSize,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: Responsive.sp(15),
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding * 0.5,
      ),
    );
  }
}
