import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/models/user_model.dart';
import '../providers/directory_provider.dart';

class EmployeeDetailScreen extends ConsumerWidget {
  final String employeeId;

  const EmployeeDetailScreen({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(employeeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Details'),
      ),
      body: userAsync.when(
        data: (user) => _buildContent(context, user),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? Text(
                            user.initials,
                            style: const TextStyle(
                              fontSize: 32,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName,
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (user.designation != null)
                    Text(
                      user.designation!,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: AppColors.grey600,
                      ),
                    ),
                  if (user.department != null)
                    Text(
                      user.department!,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: AppColors.grey500,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getRoleColor(user.role).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role.capitalize,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getRoleColor(user.role),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                _buildContactTile(
                  context,
                  Icons.email_outlined,
                  'Email',
                  user.email,
                  onTap: () => _launchEmail(user.email),
                ),
                const Divider(height: 1),
                if (user.phone != null) ...[
                  _buildContactTile(
                    context,
                    Icons.phone_outlined,
                    'Phone',
                    user.phone!,
                    onTap: () => _launchPhone(user.phone!),
                  ),
                  const Divider(height: 1),
                ],
                if (user.manager != null)
                  _buildContactTile(
                    context,
                    Icons.person_outline,
                    'Manager',
                    user.manager!.fullName,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launchEmail(user.email),
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Email'),
                ),
              ),
              if (user.phone != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchPhone(user.phone!),
                    icon: const Icon(Icons.phone_outlined),
                    label: const Text('Call'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.grey600),
      title: Text(
        label,
        style: context.textTheme.bodySmall?.copyWith(
          color: AppColors.grey500,
        ),
      ),
      subtitle: Text(
        value,
        style: context.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: onTap != null
          ? const Icon(
              Icons.chevron_right,
              color: AppColors.grey400,
            )
          : null,
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'HR_ADMIN':
        return AppColors.error;
      case 'MANAGER':
        return AppColors.primary;
      default:
        return AppColors.success;
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
