import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/services/push_notification_service.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/main_shell.dart';
import '../features/leave/presentation/leave_screen.dart';
import '../features/leave/presentation/apply_leave_screen.dart';
import '../features/leave/presentation/leave_detail_screen.dart';
import '../features/leave/presentation/leave_track_screen.dart';
import '../features/attendance/presentation/attendance_screen.dart';
import '../features/directory/presentation/directory_screen.dart';
import '../features/directory/presentation/employee_detail_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/home/presentation/hr_dashboard_screen.dart';
import '../features/home/presentation/payroll_dashboard_screen.dart';
import '../features/home/presentation/attendance_dashboard_screen.dart';
import '../features/home/presentation/it_admin_dashboard_screen.dart';
import '../features/home/presentation/manager_dashboard_screen.dart';
import '../features/home/presentation/my_tasks_screen.dart';
import '../features/home/presentation/create_claim_screen.dart';
import '../features/home/presentation/create_ticket_screen.dart';
import '../features/home/presentation/approvals_screen.dart';
import '../features/home/presentation/onboarding_tasks_screen.dart';
import '../features/auth/presentation/work_mode_selection_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/finance/presentation/finance_screen.dart';
import '../shared/providers/work_mode_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final workMode = ref.watch(workModeProvider);

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.asData?.value != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isSelectingWorkMode = state.matchedLocation == '/work-mode';
      final isSplash = state.matchedLocation == '/splash';
      final hasWorkMode = workMode != null;

      // Allow splash screen to show
      if (isSplash) {
        return null;
      }

      // Not logged in -> go to login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // Logged in but no work mode -> go to work mode selection
      if (isLoggedIn && !hasWorkMode && !isSelectingWorkMode) {
        return '/work-mode';
      }

      // Logged in with work mode but on login screen -> go home
      if (isLoggedIn && hasWorkMode && isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/work-mode',
        name: 'work-mode',
        builder: (context, state) => const WorkModeSelectionScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/leave',
            name: 'leave',
            builder: (context, state) => const LeaveScreen(),
            routes: [
              GoRoute(
                path: 'apply',
                name: 'apply-leave',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const ApplyLeaveScreen(),
              ),
              GoRoute(
                path: ':id/track',
                name: 'leave-track',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return LeaveTrackScreen(leaveId: id);
                },
              ),
              GoRoute(
                path: ':id',
                name: 'leave-detail',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return LeaveDetailScreen(leaveId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/attendance',
            name: 'attendance',
            builder: (context, state) => const AttendanceScreen(),
          ),
          GoRoute(
            path: '/directory',
            name: 'directory',
            builder: (context, state) => const DirectoryScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'employee-detail',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return EmployeeDetailScreen(employeeId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/hr-dashboard',
            name: 'hr-dashboard',
            builder: (context, state) => const HrDashboardScreen(),
          ),
          GoRoute(
            path: '/payroll-dashboard',
            name: 'payroll-dashboard',
            builder: (context, state) => const PayrollDashboardScreen(),
          ),
          GoRoute(
            path: '/attendance-dashboard',
            name: 'attendance-dashboard',
            builder: (context, state) => const AttendanceDashboardScreen(),
          ),
          GoRoute(
            path: '/it-admin-dashboard',
            name: 'it-admin-dashboard',
            builder: (context, state) => const ItAdminDashboardScreen(),
          ),
          GoRoute(
            path: '/manager-dashboard',
            name: 'manager-dashboard',
            builder: (context, state) => const ManagerDashboardScreen(),
          ),
          GoRoute(
            path: '/approvals',
            name: 'approvals',
            builder: (context, state) => const ApprovalsScreen(),
          ),
          GoRoute(
            path: '/tasks',
            name: 'tasks',
            builder: (context, state) => const MyTasksScreen(),
          ),
          GoRoute(
            path: '/onboarding-tasks',
            name: 'onboarding-tasks',
            builder: (context, state) => const OnboardingTasksScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/finance',
            name: 'finance',
            builder: (context, state) => const FinanceScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/create-claim',
        name: 'create-claim',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateClaimScreen(),
      ),
      GoRoute(
        path: '/create-ticket',
        name: 'create-ticket',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateTicketScreen(),
      ),
    ],
  );

  // Listen to notification taps for deep linking
  ref.listen<AsyncValue<NotificationPayload>>(notificationPayloadProvider,
      (previous, next) {
    next.whenData((payload) {
      final deepLink = payload.deepLink;
      if (deepLink != null && router.routerDelegate.currentConfiguration != null) {
        router.go(deepLink);
      }
    });
  });

  return router;
});

// Deep link handler for external deep links
class DeepLinkHandler {
  final GoRouter router;

  DeepLinkHandler(this.router);

  void handleDeepLink(String path) {
    router.go(path);
  }

  void handleNotificationPayload(NotificationPayload payload) {
    final deepLink = payload.deepLink;
    if (deepLink != null) {
      router.go(deepLink);
    }
  }
}

final deepLinkHandlerProvider = Provider<DeepLinkHandler>((ref) {
  final router = ref.watch(routerProvider);
  return DeepLinkHandler(router);
});
