import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/responsive.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/dynamic_island_notification.dart';
import '../../../../../shared/providers/announcements_provider.dart';

class AnnouncementsCard extends ConsumerWidget {
  const AnnouncementsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Responsive.init(context);
    final announcements = ref.watch(unreadAnnouncementsProvider);

    if (announcements.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: Responsive.horizontalPadding,
            bottom: 8,
          ),
          child: Row(
            children: [
              Icon(Icons.campaign_outlined,
                  color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Announcements',
                style: GoogleFonts.poppins(
                  fontSize: Responsive.sp(16),
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${announcements.length} new',
                style: GoogleFonts.poppins(
                  fontSize: Responsive.sp(12),
                  color: AppColors.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: Responsive.horizontalPadding),
            ],
          ),
        ),
        ...announcements.asMap().entries.map((entry) {
          final index = entry.key;
          final announcement = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              left: Responsive.horizontalPadding,
              right: Responsive.horizontalPadding,
              bottom: 10,
            ),
            child: GlassCard(
              blur: 12,
              opacity: 0.15,
              borderRadius: Responsive.cardRadius,
              padding: EdgeInsets.all(Responsive.horizontalPadding * 0.8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.notifications_active,
                            color: AppColors.warning, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              announcement.title,
                              style: GoogleFonts.poppins(
                                fontSize: Responsive.sp(14),
                                fontWeight: FontWeight.w600,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              announcement.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: Responsive.sp(12),
                                color: context.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          ref
                              .read(announcementsProvider.notifier)
                              .ignore(announcement.id);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: context.textTertiary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                        ),
                        child: Text(
                          'Ignore',
                          style: GoogleFonts.poppins(
                            fontSize: Responsive.sp(12),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          ref
                              .read(announcementsProvider.notifier)
                              .markAsRead(announcement.id);
                          DynamicIslandManager()
                              .show(context, message: 'Marked as read');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(
                              color: AppColors.primary.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Mark as Read',
                          style: GoogleFonts.poppins(
                            fontSize: Responsive.sp(12),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.05);
        }),
      ],
    );
  }
}
