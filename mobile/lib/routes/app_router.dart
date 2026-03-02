import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/services/push_notification_service.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/main_shell.dart';
import '../features/requests/presentation/request_tracking_screen.dart';
import '../features/leave/presentation/apply_leave_screen.dart';
import '../features/leave/presentation/leave_detail_screen.dart';
import '../features/leave/presentation/leave_track_screen.dart';
import '../features/attendance/presentation/attendance_screen.dart';
import '../features/directory/presentation/directory_screen.dart';
import '../features/directory/presentation/employee_detail_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/home/presentation/hr_dashboard_screen.dart';
import '../features/home/presentation/payroll_dashboard_screen.dart';
import '../features/home/presentation/it_admin_dashboard_screen.dart';
import '../features/home/presentation/manager_dashboard_screen.dart';
import '../features/home/presentation/my_tasks_screen.dart';
import '../features/home/presentation/create_claim_screen.dart';
import '../features/home/presentation/create_ticket_screen.dart';
import '../features/requests/presentation/create_shift_request_screen.dart';
import '../features/home/presentation/approvals_screen.dart';
import '../features/home/presentation/onboarding_tasks_screen.dart';
import '../features/home/presentation/add_employee_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/finance/presentation/finance_screen.dart';
import '../features/home/presentation/timesheet_screen.dart';
import '../shared/providers/work_mode_provider.dart';

/// Smooth fade + slide up transition for full-screen push routes
CustomTransitionPage<T> _slideUpPage<T>(Widget child, GoRouterState state) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

/// Fade-through transition for tab-level navigation
CustomTransitionPage<T> _fadeThrough<T>(Widget child, GoRouterState state) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final workMode = ref.watch(workModeProvider);

  // Auto-set default work mode if not set (skip work mode selection screen)
  if (workMode == null) {
    Future.microtask(() {
      ref.read(workModeProvider.notifier).setWorkMode('OFFICE');
    });
  }

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.asData?.value != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isSplash = state.matchedLocation == '/splash';

      // Allow splash screen to show
      if (isSplash) {
        return null;
      }

      // Not logged in -> go to login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // Logged in but on login screen -> go home
      if (isLoggedIn && isLoggingIn) {
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
        pageBuilder: (context, state) => _fadeThrough(const LoginScreen(), state),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (context, state) => _fadeThrough(const HomeScreen(), state),
          ),
          GoRoute(
            path: '/requests',
            name: 'requests',
            pageBuilder: (context, state) => _fadeThrough(const RequestTrackingScreen(), state),
            routes: [
              GoRoute(
                path: 'apply',
                name: 'apply-leave',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) => _slideUpPage(const ApplyLeaveScreen(), state),
              ),
              GoRoute(
                path: ':id/track',
                name: 'leave-track',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _slideUpPage(LeaveTrackScreen(leaveId: id), state);
                },
              ),
              GoRoute(
                path: ':id',
                name: 'leave-detail',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _slideUpPage(LeaveDetailScreen(leaveId: id), state);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/attendance',
            name: 'attendance',
            pageBuilder: (context, state) => _fadeThrough(const AttendanceScreen(), state),
          ),
          GoRoute(
            path: '/directory',
            name: 'directory',
            pageBuilder: (context, state) => _fadeThrough(const DirectoryScreen(), state),
            routes: [
              GoRoute(
                path: ':id',
                name: 'employee-detail',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _slideUpPage(EmployeeDetailScreen(employeeId: id), state);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            pageBuilder: (context, state) => _fadeThrough(const NotificationsScreen(), state),
          ),
          GoRoute(
            path: '/hr-dashboard',
            name: 'hr-dashboard',
            pageBuilder: (context, state) => _fadeThrough(const HrDashboardScreen(), state),
          ),
          GoRoute(
            path: '/payroll-dashboard',
            name: 'payroll-dashboard',
            pageBuilder: (context, state) => _fadeThrough(const PayrollDashboardScreen(), state),
          ),
          GoRoute(
            path: '/it-admin-dashboard',
            name: 'it-admin-dashboard',
            pageBuilder: (context, state) => _fadeThrough(const ItAdminDashboardScreen(), state),
          ),
          GoRoute(
            path: '/manager-dashboard',
            name: 'manager-dashboard',
            pageBuilder: (context, state) => _fadeThrough(const ManagerDashboardScreen(), state),
          ),
          GoRoute(
            path: '/approvals',
            name: 'approvals',
            pageBuilder: (context, state) => _fadeThrough(const ApprovalsScreen(), state),
          ),
          GoRoute(
            path: '/tasks',
            name: 'tasks',
            pageBuilder: (context, state) => _fadeThrough(const MyTasksScreen(), state),
          ),
          GoRoute(
            path: '/onboarding-tasks',
            name: 'onboarding-tasks',
            pageBuilder: (context, state) => _fadeThrough(const OnboardingTasksScreen(), state),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => _slideUpPage(const ProfileScreen(), state),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => _slideUpPage(const SettingsScreen(), state),
          ),
          GoRoute(
            path: '/finance',
            name: 'finance',
            pageBuilder: (context, state) => _fadeThrough(const FinanceScreen(), state),
          ),
        ],
      ),
      GoRoute(
        path: '/create-claim',
        name: 'create-claim',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideUpPage(const CreateClaimScreen(), state),
      ),
      GoRoute(
        path: '/create-ticket',
        name: 'create-ticket',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideUpPage(const CreateTicketScreen(), state),
      ),
      GoRoute(
        path: '/create-shift-request',
        name: 'create-shift-request',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideUpPage(const CreateShiftRequestScreen(), state),
      ),
      GoRoute(
        path: '/add-employee',
        name: 'add-employee',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) {
          final user = ref.read(currentUserProvider);
          if (user == null || (user.role != 'MANAGER' && user.role != 'HR_ADMIN' && user.role != 'ADMIN')) {
            return '/';
          }
          return null;
        },
        pageBuilder: (context, state) => _slideUpPage(const AddEmployeeScreen(), state),
      ),
      GoRoute(
        path: '/timesheet',
        name: 'timesheet',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _slideUpPage(const TimesheetScreen(), state),
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
