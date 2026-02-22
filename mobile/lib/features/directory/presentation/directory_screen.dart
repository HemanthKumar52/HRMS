import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/safe_scaffold.dart';
import '../../../shared/models/user_model.dart';
import '../providers/directory_provider.dart';

import '../../../core/widgets/dynamic_island_notification.dart';

class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen({super.key});

  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends ConsumerState<DirectoryScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchQueryProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final usersAsync = ref.watch(usersProvider(searchQuery));

    // Listen for errors to trigger Dynamic Island
    ref.listen(usersProvider(searchQuery), (previous, next) {
      if (next is AsyncError) {
         final error = next.error;
         String message = "An error occurred";
         if (error.toString().contains("401")) {
           message = "Session Expired"; 
         } else {
           message = "Failed to load directory";
         }
         
         WidgetsBinding.instance.addPostFrameCallback((_) {
            DynamicIslandManager().show(context, message: message, isError: true);
         });
      }
    });

    return SafeScaffold(
      appBar: AdaptiveAppBar(
        title: 'Directory',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search employees...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: usersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return const Center(
                    child: Text('No employees found'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(usersProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      return _EmployeeCard(
                        user: users[index],
                        onTap: () => context.pushNamed(
                          'employee-detail',
                          pathParameters: {'id': users[index].id},
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Failed to load directory', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.refresh(usersProvider(searchQuery)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;

  const _EmployeeCard({required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          backgroundImage:
              user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
          child: user.avatarUrl == null
              ? Text(
                  user.initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.designation != null)
              Text(
                user.designation!,
                style: context.textTheme.bodySmall?.copyWith(
                  color: AppColors.grey600,
                ),
              ),
            if (user.department != null)
              Text(
                user.department!,
                style: context.textTheme.bodySmall?.copyWith(
                  color: AppColors.grey500,
                ),
              ),
          ],
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.grey400,
        ),
      ),
    );
  }
}
