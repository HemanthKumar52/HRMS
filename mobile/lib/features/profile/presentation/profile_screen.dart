import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/responsive.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/presentation/widgets/dashboard/skills_card.dart';
import '../../home/presentation/widgets/dashboard/performance_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Responsive.init(context);
    final user = ref.watch(currentUserProvider);

    return SafeScaffold(
      appBar: AdaptiveAppBar(
        title: 'My Profile',
      ),
      backgroundColor: context.scaffoldBg,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Responsive.horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(Responsive.value(mobile: 20.0, tablet: 28.0)),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(Responsive.cardRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: Responsive.value(mobile: 45.0, tablet: 55.0),
                    backgroundColor: Colors.white,
                    child: Text(
                      user?.initials ?? 'U',
                      style: GoogleFonts.poppins(
                        fontSize: Responsive.sp(28),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.value(mobile: 16.0, tablet: 20.0)),
                  Text(
                    user?.fullName ?? 'User',
                    style: GoogleFonts.poppins(
                      fontSize: Responsive.sp(22),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: Responsive.value(mobile: 4.0, tablet: 6.0)),
                  Text(
                    user?.designation ?? 'Employee',
                    style: GoogleFonts.poppins(
                      fontSize: Responsive.sp(14),
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  SizedBox(height: Responsive.value(mobile: 8.0, tablet: 12.0)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.value(mobile: 12.0, tablet: 16.0),
                      vertical: Responsive.value(mobile: 6.0, tablet: 8.0),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user?.role ?? 'EMPLOYEE',
                      style: GoogleFonts.poppins(
                        fontSize: Responsive.sp(12),
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1),

            SizedBox(height: Responsive.value(mobile: 24.0, tablet: 32.0)),

            // Personal Details
            Text(
              'Personal Details',
              style: GoogleFonts.poppins(
                fontSize: Responsive.sp(18),
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ).animate().fadeIn(delay: 100.ms),
            SizedBox(height: Responsive.value(mobile: 12.0, tablet: 16.0)),
            GlassCard(
              blur: 12,
              opacity: 0.15,
              borderRadius: Responsive.cardRadius,
              padding: EdgeInsets.all(Responsive.horizontalPadding),
              child: Column(
                children: [
                  _buildDetailRow(Icons.email_outlined, 'Email', user?.email ?? 'N/A'),
                  const Divider(height: 24),
                  _buildDetailRow(Icons.phone_outlined, 'Phone', user?.phone ?? 'N/A'),
                  const Divider(height: 24),
                  _buildDetailRow(Icons.business_outlined, 'Department', user?.department ?? 'N/A'),
                  const Divider(height: 24),
                  _buildDetailRow(Icons.work_outline, 'Designation', user?.designation ?? 'N/A'),
                  const Divider(height: 24),
                  _buildDetailRow(Icons.person_outline, 'Manager', user?.manager?.fullName ?? 'N/A'),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

            SizedBox(height: Responsive.value(mobile: 24.0, tablet: 32.0)),

            // Employee Directory
            GlassCard(
              blur: 12,
              opacity: 0.15,
              borderRadius: Responsive.cardRadius,
              padding: EdgeInsets.all(Responsive.horizontalPadding),
              onTap: () => context.push('/directory'),
              child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(Responsive.value(mobile: 10.0, tablet: 14.0)),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(Responsive.cardRadius * 0.6),
                        ),
                        child: Icon(
                          Icons.people_outline,
                          color: AppColors.primary,
                          size: Responsive.sp(24),
                        ),
                      ),
                      SizedBox(width: Responsive.value(mobile: 12.0, tablet: 16.0)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Employee Directory',
                              style: GoogleFonts.poppins(
                                fontSize: Responsive.sp(15),
                                fontWeight: FontWeight.w600,
                                color: AppColors.grey900,
                              ),
                            ),
                            Text(
                              'Browse and search colleagues',
                              style: GoogleFonts.poppins(
                                fontSize: Responsive.sp(12),
                                color: AppColors.grey500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.grey400,
                        size: Responsive.sp(24),
                      ),
                    ],
                  ),
            ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

            SizedBox(height: Responsive.value(mobile: 24.0, tablet: 32.0)),

            // Performance Section
            Text(
              'Performance',
              style: GoogleFonts.poppins(
                fontSize: Responsive.sp(18),
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ).animate().fadeIn(delay: 300.ms),
            SizedBox(height: Responsive.value(mobile: 12.0, tablet: 16.0)),
            const PerformanceCard().animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

            SizedBox(height: Responsive.value(mobile: 24.0, tablet: 32.0)),

            // Skills Section
            Text(
              'Skills',
              style: GoogleFonts.poppins(
                fontSize: Responsive.sp(18),
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ).animate().fadeIn(delay: 500.ms),
            SizedBox(height: Responsive.value(mobile: 12.0, tablet: 16.0)),
            const SkillsCard().animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

            SizedBox(height: Responsive.value(mobile: 24.0, tablet: 32.0)),

            // Connected Apps
            Text(
              'Connected Apps',
              style: GoogleFonts.poppins(
                fontSize: Responsive.sp(18),
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ).animate().fadeIn(delay: 700.ms),
            SizedBox(height: Responsive.value(mobile: 12.0, tablet: 16.0)),
            GlassCard(
              blur: 12,
              opacity: 0.15,
              borderRadius: Responsive.cardRadius,
              padding: EdgeInsets.all(Responsive.horizontalPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAppIcon('Slack', Icons.chat_bubble_outline, Colors.purple),
                  _buildAppIcon('Jira', Icons.task_alt, Colors.blue),
                  _buildAppIcon('GitHub', Icons.code, Colors.grey.shade800),
                  _buildAppIcon('Teams', Icons.groups, Colors.indigo),
                ],
              ),
            ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),

            SizedBox(height: Responsive.value(mobile: 80.0, tablet: 100.0)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: Responsive.sp(20)),
        SizedBox(width: Responsive.value(mobile: 12.0, tablet: 16.0)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: Responsive.sp(12),
                  color: AppColors.grey500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: Responsive.sp(14),
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppIcon(String name, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(Responsive.value(mobile: 12.0, tablet: 16.0)),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(Responsive.cardRadius),
          ),
          child: Icon(icon, color: color, size: Responsive.sp(24)),
        ),
        SizedBox(height: Responsive.value(mobile: 8.0, tablet: 12.0)),
        Text(
          name,
          style: GoogleFonts.poppins(
            fontSize: Responsive.sp(12),
            color: AppColors.grey600,
          ),
        ),
      ],
    );
  }
}
