import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/responsive.dart';
import '../../../core/widgets/dynamic_island_notification.dart';
import '../../../core/widgets/greeting_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/providers/work_mode_provider.dart';
import '../../../shared/providers/greeting_provider.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/providers/face_photo_provider.dart';
import 'widgets/dashboard_drawer.dart';
import 'widgets/dashboards/employee_dashboard.dart';
import 'widgets/dashboards/manager_dashboard.dart';
import 'widgets/dashboards/admin_dashboard.dart';
import 'widgets/dashboards/hr_dashboard.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hasShown = ref.read(greetingShownProvider);
      if (!hasShown && mounted) {
        final user = ref.read(currentUserProvider);
        if (user != null) {
          GreetingDialog.show(context, user.firstName);
          ref.read(greetingShownProvider.notifier).state = true;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final user = ref.watch(currentUserProvider);

    return SafeScaffold(
      drawer: const DashboardDrawer(),
      backgroundColor: context.scaffoldBg,
      extendBodyBehindAppBar: true,
      appBar: _GlassDashboardAppBar(
        userInitial: user?.firstName.substring(0, 1).toUpperCase() ?? 'U',
        isScrolled: _isScrolled,
        onProfileTap: () => _showProfileMenu(context, ref),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          final scrolled = notification.metrics.pixels > 10;
          if (scrolled != _isScrolled) {
            setState(() => _isScrolled = scrolled);
          }
          return false;
        },
        child: ResponsiveBuilder(
          builder: (context, deviceType, orientation) {
            if (user == null) {
              return const Center(child: CircularProgressIndicator());
            }

            Widget dashboard;
            switch (user.role) {
              case 'HR_ADMIN':
                dashboard = const HRDashboard();
                break;
              case 'ADMIN':
                dashboard = const AdminDashboard();
                break;
              case 'MANAGER':
                dashboard = const ManagerDashboard();
                break;
              default:
                dashboard = const EmployeeDashboard();
            }

            if (deviceType == DeviceType.tablet) {
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: orientation == Orientation.landscape ? 900 : 600,
                  ),
                  child: dashboard,
                ),
              );
            }

            return dashboard;
          },
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.3),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Responsive.cardRadius * 1.5),
        ),
      ),
      builder: (sheetContext) => _ProfileSheetContent(ref: ref),
    );
  }
}

// ─── Profile Sheet with Animated Sub-views ─────────────────────────
enum _ProfileView { main, workMode, theme }

class _ProfileSheetContent extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _ProfileSheetContent({required this.ref});

  @override
  ConsumerState<_ProfileSheetContent> createState() =>
      _ProfileSheetContentState();
}

class _ProfileSheetContentState extends ConsumerState<_ProfileSheetContent> {
  _ProfileView _currentView = _ProfileView.main;

  // Work mode picker state
  int _workModeIndex = 0;
  static const _workModes = ['OFFICE', 'REMOTE', 'ON_DUTY'];
  static const _workModeLabels = ['Office', 'Remote', 'On Duty (OD)'];
  static const _workModeIcons = [Icons.business, Icons.home, Icons.directions_car];
  static const _workModeColors = [Colors.blue, Colors.green, Colors.orange];

  // Theme picker state
  int _themeIndex = 0;
  static const _themeLabels = ['Light Mode', 'Dark Mode', 'System'];
  static const _themeIcons = [
    Icons.light_mode,
    Icons.dark_mode,
    Icons.settings_brightness,
  ];
  static const _themeColors = [Colors.amber, Colors.indigo, Colors.teal];

  @override
  void initState() {
    super.initState();
    final currentMode = ref.read(workModeProvider);
    _workModeIndex = _workModes.indexOf(currentMode ?? 'OFFICE');
    if (_workModeIndex < 0) _workModeIndex = 0;
    _themeIndex = ref.read(themeModeProvider.notifier).currentIndex;
  }

  String get _currentWorkModeLabel {
    final mode = ref.read(workModeProvider);
    final idx = _workModes.indexOf(mode ?? 'OFFICE');
    return idx >= 0 ? _workModeLabels[idx] : 'Office';
  }

  String get _currentThemeLabel {
    final idx = ref.read(themeModeProvider.notifier).currentIndex;
    return _themeLabels[idx];
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(Responsive.cardRadius * 1.5),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.glassOverlayStart,
                  context.glassOverlayEnd,
                ],
              ),
            ),
            padding: EdgeInsets.all(Responsive.horizontalPadding * 1.5),
            child: SingleChildScrollView(
              child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  final isForward = _currentView != _ProfileView.main;
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(isForward ? 1.0 : -1.0, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut,
                    )),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: _currentView == _ProfileView.main
                    ? _buildMainView(context, user)
                    : _currentView == _ProfileView.workMode
                        ? _buildWorkModeView(context)
                        : _buildThemeView(context),
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainView(BuildContext context, dynamic user) {
    final facePhoto = ref.watch(facePhotoProvider);

    return Column(
      key: const ValueKey('main'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle bar
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: context.handleBarColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Avatar — shows face photo if verified
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: Responsive.value(mobile: 40.0, tablet: 48.0),
              backgroundImage: facePhoto != null
                  ? FileImage(File(facePhoto))
                  : null,
              child: facePhoto == null
                  ? Text(
                      user?.firstName.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.sp(28),
                      ),
                    )
                  : null,
            ),
            if (facePhoto != null)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
          ],
        ),
        SizedBox(height: Responsive.verticalPadding),
        Text(
          '${user?.firstName ?? ''} ${user?.lastName ?? ''}',
          style: GoogleFonts.poppins(
            fontSize: Responsive.sp(20),
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user?.email ?? '',
          style: GoogleFonts.poppins(
            fontSize: Responsive.sp(14),
            color: context.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: context.chipBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            user?.role ?? 'EMPLOYEE',
            style: GoogleFonts.poppins(
              fontSize: Responsive.sp(12),
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: Responsive.verticalPadding * 1.5),

        // Option 1: View Profile
        _buildOptionTile(
          icon: Icons.person_outline,
          title: 'View Profile',
          subtitle: 'View your details',
          color: AppColors.primary,
          trailing: Icon(Icons.chevron_right, color: context.textTertiary),
          onTap: () {
            Navigator.pop(context);
            context.push('/profile');
          },
        ),
        const SizedBox(height: 10),

        // Option 2: Work Mode
        _buildOptionTile(
          icon: Icons.work_outline,
          title: 'Work Mode',
          subtitle: _currentWorkModeLabel,
          color: Colors.orange,
          trailing: Icon(Icons.chevron_right, color: context.textTertiary),
          onTap: () => setState(() => _currentView = _ProfileView.workMode),
        ),
        const SizedBox(height: 10),

        // Option 3: Settings (Theme)
        _buildOptionTile(
          icon: Icons.palette_outlined,
          title: 'Appearance',
          subtitle: _currentThemeLabel,
          color: AppColors.secondary,
          trailing: Icon(Icons.chevron_right, color: context.textTertiary),
          onTap: () => setState(() => _currentView = _ProfileView.theme),
        ),

        Divider(height: 32, color: context.dividerColor),

        // Logout
        _buildOptionTile(
          icon: Icons.logout,
          title: 'Logout',
          subtitle: 'Sign out of your account',
          color: Colors.red,
          onTap: () async {
            Navigator.pop(context);
            await ref.read(authStateProvider.notifier).logout();
            await ref.read(workModeProvider.notifier).clearWorkMode();
            if (context.mounted) {
              DynamicIslandManager().show(context,
                  message: 'Logged out successfully');
              context.go('/login');
            }
          },
        ),
        SizedBox(height: Responsive.bottomSafeArea > 0 ? 0 : 16),
      ],
    );
  }

  Widget _buildWorkModeView(BuildContext context) {
    return Column(
      key: const ValueKey('workMode'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with back arrow
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () =>
                  setState(() => _currentView = _ProfileView.main),
            ),
            const SizedBox(width: 8),
            Text(
              'Select Work Mode',
              style: GoogleFonts.poppins(
                fontSize: Responsive.sp(18),
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: CupertinoPicker(
            scrollController:
                FixedExtentScrollController(initialItem: _workModeIndex),
            itemExtent: 60,
            diameterRatio: 1.2,
            magnification: 1.1,
            useMagnifier: true,
            onSelectedItemChanged: (index) => _workModeIndex = index,
            children: List.generate(3, (i) {
              return Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_workModeIcons[i],
                        color: _workModeColors[i], size: 28),
                    const SizedBox(width: 14),
                    Text(
                      _workModeLabels[i],
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: Responsive.buttonHeight,
          child: ElevatedButton(
            onPressed: () {
              ref
                  .read(workModeProvider.notifier)
                  .setWorkMode(_workModes[_workModeIndex]);
              Navigator.pop(context);
              DynamicIslandManager().show(context,
                  message:
                      'Work mode changed to ${_workModeLabels[_workModeIndex]}');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(Responsive.cardRadius),
              ),
            ),
            child: Text(
              'Confirm',
              style: GoogleFonts.poppins(
                fontSize: Responsive.sp(15),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: Responsive.bottomSafeArea > 0 ? 0 : 16),
      ],
    );
  }

  Widget _buildThemeView(BuildContext context) {
    return Column(
      key: const ValueKey('theme'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with back arrow
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () =>
                  setState(() => _currentView = _ProfileView.main),
            ),
            const SizedBox(width: 8),
            Text(
              'Appearance',
              style: GoogleFonts.poppins(
                fontSize: Responsive.sp(18),
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: CupertinoPicker(
            scrollController:
                FixedExtentScrollController(initialItem: _themeIndex),
            itemExtent: 60,
            diameterRatio: 1.2,
            magnification: 1.1,
            useMagnifier: true,
            onSelectedItemChanged: (index) => _themeIndex = index,
            children: List.generate(3, (i) {
              return Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_themeIcons[i],
                        color: _themeColors[i], size: 28),
                    const SizedBox(width: 14),
                    Text(
                      _themeLabels[i],
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: Responsive.buttonHeight,
          child: ElevatedButton(
            onPressed: () {
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeModeByIndex(_themeIndex);
              Navigator.pop(context);
              DynamicIslandManager().show(context,
                  message: 'Theme changed to ${_themeLabels[_themeIndex]}');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(Responsive.cardRadius),
              ),
            ),
            child: Text(
              'Apply',
              style: GoogleFonts.poppins(
                fontSize: Responsive.sp(15),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(height: Responsive.bottomSafeArea > 0 ? 0 : 16),
      ],
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Responsive.cardRadius),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.horizontalPadding * 0.8,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(Responsive.cardRadius),
            border: Border.all(
              color: color.withOpacity(0.12),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: Responsive.sp(15),
                        fontWeight: FontWeight.w600,
                        color: title == 'Logout'
                            ? Colors.red
                            : context.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: Responsive.sp(12),
                        color: title == 'Logout'
                            ? Colors.red.withOpacity(0.7)
                            : context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Glassmorphic Dashboard App Bar ──────────────────────────────
class _GlassDashboardAppBar extends ConsumerWidget
    implements PreferredSizeWidget {
  final String userInitial;
  final bool isScrolled;
  final VoidCallback onProfileTap;

  const _GlassDashboardAppBar({
    required this.userInitial,
    required this.isScrolled,
    required this.onProfileTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Responsive.init(context);
    final facePhoto = ref.watch(facePhotoProvider);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isScrolled ? 25 : 0,
          sigmaY: isScrolled ? 25 : 0,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isScrolled
                  ? [
                      context.glassOverlayStart,
                      context.glassOverlayEnd,
                    ]
                  : [
                      Colors.transparent,
                      Colors.transparent,
                    ],
            ),
            border: isScrolled
                ? Border(
                    bottom: BorderSide(
                      color: context.glassBorder,
                      width: 0.5,
                    ),
                  )
                : null,
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: kToolbarHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    // pPULSE logo in glassmorphic pill
                    GestureDetector(
                      onTap: () => Scaffold.of(context).openDrawer(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.15),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person,
                                color: Colors.purple, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'pPULSE',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Dashboard title centered
                    Text(
                      'Dashboard',
                      style: GoogleFonts.poppins(
                        fontSize: Responsive.sp(18),
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    // Profile avatar — shows face photo if verified, else initials
                    IconButton(
                      icon: Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary,
                            radius: Responsive.value(mobile: 16.0, tablet: 18.0),
                            backgroundImage: facePhoto != null
                                ? FileImage(File(facePhoto))
                                : null,
                            child: facePhoto == null
                                ? Text(
                                    userInitial,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: Responsive.sp(14),
                                    ),
                                  )
                                : null,
                          ),
                          if (facePhoto != null)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: const Icon(Icons.check, size: 8, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      onPressed: onProfileTap,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
