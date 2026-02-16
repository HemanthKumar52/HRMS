import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/responsive.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/providers/work_mode_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Responsive.init(context);
    final themeMode = ref.watch(themeModeProvider);
    final workMode = ref.watch(workModeProvider);

    return SafeScaffold(
      appBar: AdaptiveAppBar(title: 'Settings'),
      backgroundColor: const Color(0xFFF3F4F6),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Responsive.horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preferences',
              style: GoogleFonts.poppins(
                fontSize: Responsive.sp(18),
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ).animate().fadeIn(),
            SizedBox(height: Responsive.value(mobile: 12.0, tablet: 16.0)),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Responsive.cardRadius),
                border: Border.all(color: AppColors.grey200),
              ),
              child: Column(
                children: [
                  // Dark Mode Toggle
                  SwitchListTile(
                    secondary: Container(
                      padding: EdgeInsets.all(
                          Responsive.value(mobile: 8.0, tablet: 10.0)),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(Responsive.cardRadius * 0.6),
                      ),
                      child: Icon(
                        themeMode == ThemeMode.dark
                            ? Icons.dark_mode
                            : Icons.light_mode,
                        color: AppColors.secondary,
                        size: Responsive.sp(20),
                      ),
                    ),
                    title: Text(
                      'Dark Mode',
                      style: GoogleFonts.poppins(
                        fontSize: Responsive.sp(15),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      themeMode == ThemeMode.dark
                          ? 'Dark theme enabled'
                          : themeMode == ThemeMode.light
                              ? 'Light theme enabled'
                              : 'Following system',
                      style: GoogleFonts.poppins(
                        fontSize: Responsive.sp(12),
                        color: AppColors.grey500,
                      ),
                    ),
                    value: themeMode == ThemeMode.dark,
                    onChanged: (value) {
                      ref.read(themeModeProvider.notifier).toggleDarkMode();
                    },
                    activeColor: AppColors.primary,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),

                  // Change Work Mode
                  ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(
                          Responsive.value(mobile: 8.0, tablet: 10.0)),
                      decoration: BoxDecoration(
                        color: _getWorkModeColor(workMode).withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(Responsive.cardRadius * 0.6),
                      ),
                      child: Icon(
                        _getWorkModeIcon(workMode),
                        color: _getWorkModeColor(workMode),
                        size: Responsive.sp(20),
                      ),
                    ),
                    title: Text(
                      'Change Work Mode',
                      style: GoogleFonts.poppins(
                        fontSize: Responsive.sp(15),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Current: ${_getWorkModeLabel(workMode)}',
                      style: GoogleFonts.poppins(
                        fontSize: Responsive.sp(12),
                        color: AppColors.grey500,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: AppColors.grey400,
                      size: Responsive.sp(24),
                    ),
                    onTap: () => context.go('/work-mode'),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),

                  // Privacy & Policies
                  ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(
                          Responsive.value(mobile: 8.0, tablet: 10.0)),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(Responsive.cardRadius * 0.6),
                      ),
                      child: Icon(
                        Icons.privacy_tip_outlined,
                        color: AppColors.info,
                        size: Responsive.sp(20),
                      ),
                    ),
                    title: Text(
                      'Privacy & Policies',
                      style: GoogleFonts.poppins(
                        fontSize: Responsive.sp(15),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Terms of service and privacy policy',
                      style: GoogleFonts.poppins(
                        fontSize: Responsive.sp(12),
                        color: AppColors.grey500,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: AppColors.grey400,
                      size: Responsive.sp(24),
                    ),
                    onTap: () => _showPrivacyPolicy(context),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

            SizedBox(height: Responsive.value(mobile: 24.0, tablet: 32.0)),

            // App Info
            Text(
              'About',
              style: GoogleFonts.poppins(
                fontSize: Responsive.sp(18),
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ).animate().fadeIn(delay: 200.ms),
            SizedBox(height: Responsive.value(mobile: 12.0, tablet: 16.0)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(Responsive.horizontalPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Responsive.cardRadius),
                border: Border.all(color: AppColors.grey200),
              ),
              child: Column(
                children: [
                  _buildInfoRow('App Version', '1.0.0'),
                  const Divider(height: 24),
                  _buildInfoRow('Build', '2026.02'),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: Responsive.sp(14),
            color: AppColors.grey600,
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
    );
  }

  IconData _getWorkModeIcon(String? mode) {
    switch (mode) {
      case 'OFFICE':
        return Icons.business;
      case 'REMOTE':
        return Icons.home;
      case 'ON_DUTY':
        return Icons.directions_car;
      default:
        return Icons.help_outline;
    }
  }

  Color _getWorkModeColor(String? mode) {
    switch (mode) {
      case 'OFFICE':
        return Colors.blue;
      case 'REMOTE':
        return Colors.green;
      case 'ON_DUTY':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getWorkModeLabel(String? mode) {
    switch (mode) {
      case 'OFFICE':
        return 'Office';
      case 'REMOTE':
        return 'Remote';
      case 'ON_DUTY':
        return 'On Duty';
      default:
        return 'Not Set';
    }
  }

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Responsive.cardRadius * 1.5),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: EdgeInsets.all(Responsive.horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Privacy & Policies',
                style: GoogleFonts.poppins(
                  fontSize: Responsive.sp(20),
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey900,
                ),
              ),
              SizedBox(height: Responsive.value(mobile: 16.0, tablet: 20.0)),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(
                    'This HRMS application collects and processes employee data '
                    'including personal information, attendance records, leave history, '
                    'and financial data for the purpose of human resource management.\n\n'
                    'Data Protection:\n'
                    '- All personal data is encrypted in transit and at rest\n'
                    '- Access to employee data is role-based and restricted\n'
                    '- Biometric data (if collected) is stored securely and used only for attendance verification\n'
                    '- Location data is collected only during active work hours when required by work mode\n\n'
                    'Employee Rights:\n'
                    '- Right to access your personal data\n'
                    '- Right to request correction of inaccurate data\n'
                    '- Right to request deletion of data (subject to legal requirements)\n'
                    '- Right to data portability\n\n'
                    'For questions about data privacy, please contact your HR administrator.',
                    style: GoogleFonts.poppins(
                      fontSize: Responsive.sp(14),
                      color: AppColors.grey600,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
