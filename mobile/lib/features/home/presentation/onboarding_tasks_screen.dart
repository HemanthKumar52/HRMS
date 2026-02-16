import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/responsive.dart';
import '../../../core/widgets/glass_card.dart';

class OnboardingTasksScreen extends StatelessWidget {
  const OnboardingTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return SafeScaffold(
      appBar: AdaptiveAppBar(title: 'Onboarding Tasks'),
      backgroundColor: const Color(0xFFF3F4F6),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Responsive.horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Overview
            GlassCard(
              blur: 15,
              opacity: 0.15,
              borderRadius: Responsive.cardRadius,
              padding: EdgeInsets.all(Responsive.horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Onboarding Progress',
                            style: GoogleFonts.poppins(
                              fontSize: Responsive.sp(16),
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '3 of 8 tasks completed',
                            style: GoogleFonts.poppins(
                              fontSize: Responsive.sp(12),
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.assignment_turned_in,
                          color: AppColors.primary,
                          size: Responsive.sp(24),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.value(mobile: 16.0, tablet: 20.0)),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 3 / 8),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(value * 100).toInt()}%',
                              style: GoogleFonts.poppins(
                                fontSize: Responsive.sp(14),
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              '5 remaining',
                              style: GoogleFonts.poppins(
                                fontSize: Responsive.sp(12),
                                color: AppColors.grey500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: value,
                          backgroundColor: AppColors.grey200.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          borderRadius: BorderRadius.circular(4),
                          minHeight: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1),

            SizedBox(height: Responsive.value(mobile: 24.0, tablet: 32.0)),

            Text(
              'Pending Tasks',
              style: GoogleFonts.poppins(
                fontSize: Responsive.sp(18),
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ).animate().fadeIn(delay: 100.ms),
            SizedBox(height: Responsive.value(mobile: 12.0, tablet: 16.0)),

            ..._pendingTasks.asMap().entries.map((entry) {
              final index = entry.key;
              final task = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTaskCard(
                  task['title'] as String,
                  task['subtitle'] as String,
                  task['icon'] as IconData,
                  task['color'] as Color,
                  task['dueDate'] as String,
                  false,
                ),
              ).animate().fadeIn(delay: (200 + index * 80).ms).slideX(begin: 0.1);
            }),

            SizedBox(height: Responsive.value(mobile: 24.0, tablet: 32.0)),

            Text(
              'Completed',
              style: GoogleFonts.poppins(
                fontSize: Responsive.sp(18),
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ).animate().fadeIn(delay: 500.ms),
            SizedBox(height: Responsive.value(mobile: 12.0, tablet: 16.0)),

            ..._completedTasks.asMap().entries.map((entry) {
              final index = entry.key;
              final task = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTaskCard(
                  task['title'] as String,
                  task['subtitle'] as String,
                  task['icon'] as IconData,
                  task['color'] as Color,
                  task['dueDate'] as String,
                  true,
                ),
              ).animate().fadeIn(delay: (600 + index * 80).ms).slideX(begin: 0.1);
            }),

            SizedBox(height: Responsive.value(mobile: 80.0, tablet: 100.0)),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String dueDate,
    bool isCompleted,
  ) {
    return GlassCard(
      blur: 10,
      opacity: 0.15,
      borderRadius: Responsive.cardRadius,
      padding: EdgeInsets.all(Responsive.value(mobile: 16.0, tablet: 20.0)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.value(mobile: 10.0, tablet: 14.0)),
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.success.withOpacity(0.1)
                  : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle : icon,
              color: isCompleted ? AppColors.success : color,
              size: Responsive.sp(22),
            ),
          ),
          SizedBox(width: Responsive.value(mobile: 12.0, tablet: 16.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: Responsive.sp(14),
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? AppColors.grey500 : AppColors.grey900,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: Responsive.sp(12),
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dueDate,
                    style: GoogleFonts.poppins(
                      fontSize: Responsive.sp(10),
                      fontWeight: FontWeight.w500,
                      color: AppColors.warning,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.verified,
                  color: AppColors.success,
                  size: Responsive.sp(20),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static final List<Map<String, dynamic>> _pendingTasks = [
    {
      'title': 'Submit ID Proof Documents',
      'subtitle': 'Upload Aadhaar, PAN & Passport copy',
      'icon': Icons.upload_file,
      'color': Colors.blue,
      'dueDate': 'Due: Feb 20',
    },
    {
      'title': 'Complete Tax Declaration',
      'subtitle': 'Submit Form 12BB for tax savings',
      'icon': Icons.receipt_long,
      'color': Colors.purple,
      'dueDate': 'Due: Feb 22',
    },
    {
      'title': 'Complete Compliance Training',
      'subtitle': 'Workplace safety & data privacy training',
      'icon': Icons.school,
      'color': Colors.teal,
      'dueDate': 'Due: Feb 25',
    },
    {
      'title': 'Set Up Workstation',
      'subtitle': 'Collect laptop, access card & credentials',
      'icon': Icons.computer,
      'color': Colors.indigo,
      'dueDate': 'Due: Feb 18',
    },
    {
      'title': 'Meet Team Members',
      'subtitle': 'Schedule 1:1 with team leads & colleagues',
      'icon': Icons.groups,
      'color': Colors.pink,
      'dueDate': 'Due: Feb 28',
    },
  ];

  static final List<Map<String, dynamic>> _completedTasks = [
    {
      'title': 'Accept Offer Letter',
      'subtitle': 'Digitally signed and submitted',
      'icon': Icons.description,
      'color': Colors.green,
      'dueDate': 'Completed',
    },
    {
      'title': 'Bank Account Details',
      'subtitle': 'Salary account linked successfully',
      'icon': Icons.account_balance,
      'color': Colors.green,
      'dueDate': 'Completed',
    },
    {
      'title': 'Emergency Contact Info',
      'subtitle': 'Contact details submitted',
      'icon': Icons.contact_phone,
      'color': Colors.green,
      'dueDate': 'Completed',
    },
  ];
}
