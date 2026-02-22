import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/safe_scaffold.dart';
import '../data/notification_model.dart';
import '../providers/notification_provider.dart';

import '../../../core/widgets/dynamic_island_notification.dart'; // Import created widget

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    // Listen for errors and show Dynamic Island notification
    ref.listen<AsyncValue<List<NotificationModel>>>(notificationsProvider, (previous, next) {
      if (next is AsyncError) {
         // Extract error message cleanly
         final error = next.error;
         String message = "An error occurred";
         if (error.toString().contains("401")) {
           message = "Session Expired. Please login again.";
         } else {
           message = error.toString().replaceAll("Exception: ", "");
         }
         
         // Show Dynamic Island Alert
         // Use a post frame callback to avoid build conflicts if needed, though listen is usually safe.
         WidgetsBinding.instance.addPostFrameCallback((_) {
            DynamicIslandManager().show(context, message: message, isError: true);
         });
      }
    });

    final notificationsAsync = ref.watch(notificationsProvider);

    return SafeScaffold(
      appBar: AdaptiveAppBar(
        title: 'Notifications',
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'mark_all_read') {
                await ref
                    .read(notificationActionsProvider.notifier)
                    .markAllAsRead();
                ref.invalidate(notificationsProvider);
                ref.invalidate(unreadCountProvider);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Text('Mark all as read'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationsProvider);
          ref.invalidate(unreadCountProvider);
        },
        child: notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: AppColors.grey400,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: TextStyle(
                        color: AppColors.grey500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return _NotificationCard(
                  notification: notifications[index],
                  onTap: () async {
                    if (!notifications[index].isRead) {
                      await ref
                          .read(notificationActionsProvider.notifier)
                          .markAsRead(notifications[index].id);
                      ref.invalidate(notificationsProvider);
                      ref.invalidate(unreadCountProvider);
                    }
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Failed to load notifications', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.refresh(notificationsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const _NotificationCard({required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: notification.isRead ? null : AppColors.primary.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getTypeColor(notification.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getTypeIcon(notification.type),
                  size: 20,
                  color: _getTypeColor(notification.type),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: context.textTheme.bodyMedium?.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: AppColors.grey600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(notification.createdAt),
                      style: context.textTheme.labelSmall?.copyWith(
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return dateTime.formatted;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'LEAVE_REQUEST':
      case 'LEAVE_APPROVED':
        return AppColors.success;
      case 'LEAVE_REJECTED':
        return AppColors.error;
      case 'ATTENDANCE':
        return AppColors.primary;
      default:
        return AppColors.info;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'LEAVE_REQUEST':
      case 'LEAVE_APPROVED':
      case 'LEAVE_REJECTED':
        return Icons.event_note;
      case 'ATTENDANCE':
        return Icons.access_time;
      case 'SYSTEM':
        return Icons.info_outline;
      default:
        return Icons.notifications_outlined;
    }
  }
}
