import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../../core/widgets/dynamic_island_notification.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    // Delayed Announcement - Time-based
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 5), () {
        if (!mounted) return;
        final user = ref.read(currentUserProvider);
        final now = DateTime.now();
        final hour = now.hour;
        
        String message;
        bool isError = false;
        
        // Time-based messages
        if (hour >= 6 && hour < 12) {
          // Morning (6 AM - 12 PM)
          message = user?.role == 'EMPLOYEE' 
              ? "☀️ Good Morning! Don't forget to clock in"
              : "☀️ Good Morning! Check your team's attendance";
        } else if (hour >= 12 && hour < 17) {
          // Afternoon (12 PM - 5 PM)
          message = user?.role == 'EMPLOYEE'
              ? "🌤️ Good Afternoon! Remember to take breaks"
              : "🌤️ Good Afternoon! Review pending approvals";
        } else if (hour >= 17 && hour < 21) {
          // Evening (5 PM - 9 PM)
          message = user?.role == 'EMPLOYEE'
              ? "🌆 Don't forget to clock out before leaving!"
              : "🌆 Review today's team attendance";
          isError = user?.role == 'EMPLOYEE'; // Warning for employees
        } else {
          // Night (9 PM - 6 AM)
          message = "🌙 Working late? Don't forget to clock out!";
          isError = true; // Warning for late work
        }
        
        DynamicIslandManager().show(context, message: message, isError: isError); 
      });
    });
  }

  int _getCurrentIndex(BuildContext context) {
    try {
      final location = GoRouterState.of(context).matchedLocation;
      if (location.startsWith('/leave')) return 1;
      if (location.startsWith('/attendance')) return 2;
      if (location.startsWith('/directory')) return 3;
      return 0;
    } catch (e) {
      // GoRouterState not available yet, return default
      return 0;
    }
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/leave');
        break;
      case 2:
        context.go('/attendance');
        break;
      case 3:
        context.go('/directory');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Global Error Listener for Dynamic Island
    ref.listen<AsyncValue>(notificationsProvider, (previous, next) {
      if (next is AsyncError) {
         final error = next.error;
         String message = "An error occurred";
         if (error.toString().contains("401")) {
           message = "Session Expired. Please login again.";
         } else {
           message = error.toString().replaceAll("Exception: ", "");
         }
         
         WidgetsBinding.instance.addPostFrameCallback((_) {
            DynamicIslandManager().show(context, message: message, isError: true);
         });
      }
    });

    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note),
            label: 'Leave',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time_outlined),
            activeIcon: Icon(Icons.access_time_filled),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Directory',
          ),
        ],
      ),
    );
  }
}
