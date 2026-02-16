import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/responsive.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/widgets/face_verification_dialog.dart';
import '../../../shared/providers/login_method_provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/widgets/dynamic_island_notification.dart';
import '../../../core/widgets/pulse_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  LoginMethod? _currentLoginMethod;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin({
    String? name,
    bool isGuest = false,
    String? mockRole,
    LoginMethod loginMethod = LoginMethod.password,
  }) async {
    if (!isGuest && mockRole == null && loginMethod == LoginMethod.password && _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your Email')));
      return;
    }

    if (!isGuest && mockRole == null && loginMethod == LoginMethod.password && _passwordController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your Password')));
       return;
    }

    setState(() {
      _isLoading = true;
      _currentLoginMethod = loginMethod;
    });

    try {
      if (isGuest) {
        await ref.read(authStateProvider.notifier).login('employee@acme.com', password: 'password123');
      } else {
        final displayName = name ?? _nameController.text;
        final email = _emailController.text.isNotEmpty ? _emailController.text : 'employee@acme.com';
        final password = _passwordController.text.isNotEmpty ? _passwordController.text : 'password123';

        await ref.read(authStateProvider.notifier).login(email, password: password, name: displayName, mockRole: mockRole);
      }

      final authState = ref.read(authStateProvider);
      if (authState is AsyncError) {
         throw authState.error ?? Exception('Unknown authentication error');
      }

      // Save the login method
      await ref.read(loginMethodProvider.notifier).setLoginMethod(loginMethod);

      if (mounted) {
        DynamicIslandManager().show(context, message: 'Successfully Logged In via ${loginMethod.displayName}', isError: false);
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
         String errorMessage = e.toString().replaceAll("Exception: ", "");
         DynamicIslandManager().show(context, message: 'Login Failed: $errorMessage', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentLoginMethod = null;
        });
      }
    }
  }

  /// Handle biometric login
  Future<void> _handleBiometricLogin() async {
    final bioService = ref.read(biometricServiceProvider);

    // Check if biometric is available
    final canUseBiometric = await bioService.canCheckBiometrics;
    if (!canUseBiometric) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication is not available on this device'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Authenticate with biometric
    final authenticated = await bioService.authenticate(reason: 'Login with Biometric');

    if (authenticated) {
      await _handleLogin(
        name: 'Biometric User',
        loginMethod: LoginMethod.biometric,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Handle Face ID login
  Future<void> _handleFaceIdLogin() async {
    // Show face verification dialog
    final photoPath = await showFaceVerificationDialog(context);

    if (photoPath != null) {
      await _handleLogin(
        name: 'Face ID User',
        loginMethod: LoginMethod.faceId,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Face verification cancelled'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  /// Handle phone/OTP login (simulated)
  Future<void> _handlePhoneLogin() async {
    // Show phone number dialog
    final phoneNumber = await _showPhoneInputDialog();

    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      // Simulate OTP verification
      final otpVerified = await _showOtpVerificationDialog(phoneNumber);

      if (otpVerified) {
        await _handleLogin(
          name: 'Phone User',
          loginMethod: LoginMethod.phone,
        );
      }
    }
  }

  Future<String?> _showPhoneInputDialog() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.phone_android, color: AppColors.phoneLogin),
            const SizedBox(width: 12),
            const Text('Phone Login'),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: '+91 9876543210',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.phoneLogin,
            ),
            child: const Text('Send OTP'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showOtpVerificationDialog(String phoneNumber) async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter the OTP sent to $phoneNumber',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: '000000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'For demo, enter any 6 digits',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.length == 6) {
                Navigator.of(context).pop(true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.phoneLogin,
            ),
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    // Listen for auth changes
    ref.listen(authStateProvider, (previous, next) {
      if (next is AsyncData && next.value != null) {
        context.go('/');
      }
    });

    return SafeScaffold(
      backgroundColor: Colors.white,
      useSafeArea: true,
      body: Stack(
        children: [
          // Background decorations - responsive sizes
          Positioned(
            top: -Responsive.hp(10),
            right: -Responsive.hp(10),
            child: Container(
              width: Responsive.value(mobile: 250.0, tablet: 350.0),
              height: Responsive.value(mobile: 250.0, tablet: 350.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -Responsive.hp(5),
            left: -Responsive.hp(5),
            child: Container(
              width: Responsive.value(mobile: 180.0, tablet: 250.0),
              height: Responsive.value(mobile: 180.0, tablet: 250.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(0.1),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.value(mobile: 24.0, tablet: 48.0),
                vertical: Responsive.verticalPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.value<double>(mobile: double.infinity, tablet: 450.0),
                ),
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   const PulseLogo().animate().scale(delay: 200.ms),
                   const SizedBox(height: 16),
                   Text('Manage your work life balance', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, color: AppColors.grey500)).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),

                   const SizedBox(height: 48),

                   TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'John Doe',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: AppColors.grey50,
                    ),
                   ).animate().fadeIn(delay: 450.ms).slideX(),
                   const SizedBox(height: 16),

                   TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: AppColors.grey50,
                    ),
                   ).animate().fadeIn(delay: 500.ms).slideX(),
                   const SizedBox(height: 16),

                   TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: AppColors.grey50,
                    ),
                   ).animate().fadeIn(delay: 600.ms).slideX(),

                   const SizedBox(height: 24),

                   ElevatedButton(
                    onPressed: _isLoading ? null : () => _handleLogin(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading && _currentLoginMethod == LoginMethod.password
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Sign In', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                   ).animate().fadeIn(delay: 700.ms).scale(),

                   const SizedBox(height: 24),

                   Row(children: [const Expanded(child: Divider()), Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('Quick Login', style: GoogleFonts.poppins(color: Colors.grey))), const Expanded(child: Divider())]).animate().fadeIn(delay: 800.ms),

                   const SizedBox(height: 24),

                   // BIOMETRIC LOGIN OPTIONS
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLoginMethodButton(
                        icon: Icons.fingerprint,
                        label: 'Biometric',
                        color: AppColors.biometricLogin,
                        isLoading: _isLoading && _currentLoginMethod == LoginMethod.biometric,
                        onTap: _handleBiometricLogin,
                      ),
                      _buildLoginMethodButton(
                        icon: Icons.phone_android,
                        label: 'Phone',
                        color: AppColors.phoneLogin,
                        isLoading: _isLoading && _currentLoginMethod == LoginMethod.phone,
                        onTap: _handlePhoneLogin,
                      ),
                      _buildLoginMethodButton(
                        icon: Icons.face,
                        label: 'Face ID',
                        color: AppColors.faceIdLogin,
                        isLoading: _isLoading && _currentLoginMethod == LoginMethod.faceId,
                        onTap: _handleFaceIdLogin,
                      ),
                    ],
                   ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.2),

                   const SizedBox(height: 24),

                   Row(children: [const Expanded(child: Divider()), Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('Or continue with', style: GoogleFonts.poppins(color: Colors.grey))), const Expanded(child: Divider())]).animate().fadeIn(delay: 950.ms),

                   const SizedBox(height: 24),

                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSocialButton(
                        Text('G', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFFDB4437))),
                        'Google',
                        const Color(0xFFDB4437),
                        () => _handleLogin(name: 'Google User')
                      ),
                      _buildSocialButton(
                        const Icon(Icons.window, size: 30, color: Color(0xFF00A4EF)),
                        'Microsoft',
                        const Color(0xFF00A4EF),
                        () => _handleLogin(name: 'Microsoft User')
                      ),
                      _buildSocialButton(
                        const Icon(Icons.apple, size: 32, color: Colors.black),
                        'Apple',
                        Colors.black,
                        () => _handleLogin(name: 'Mac User')
                      ),
                    ],
                   ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2),

                   const SizedBox(height: 32),

                   Wrap(
                     spacing: 12,
                     runSpacing: 12,
                     alignment: WrapAlignment.center,
                     children: [
                       ActionChip(
                         avatar: const Icon(Icons.person_outline, size: 16),
                         label: const Text('Employee'),
                         onPressed: () => _handleLogin(name: 'John Employee', mockRole: 'EMPLOYEE'),
                       ),
                       ActionChip(
                         avatar: const Icon(Icons.supervisor_account_outlined, size: 16),
                         label: const Text('Manager'),
                         onPressed: () => _handleLogin(name: 'Jane Manager', mockRole: 'MANAGER'),
                       ),
                       ActionChip(
                         avatar: const Icon(Icons.admin_panel_settings_outlined, size: 16),
                         label: const Text('HR Admin'),
                         onPressed: () => _handleLogin(name: 'Super HR', mockRole: 'HR_ADMIN'),
                       ),
                     ],
                   ).animate().fadeIn(delay: 1100.ms),

                   const SizedBox(height: 16),

                   TextButton(
                    onPressed: () => _handleLogin(isGuest: true),
                    child: Text('Continue as Guest', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.grey700)),
                   ).animate().fadeIn(delay: 1200.ms),

                   // Extra padding for bottom safe area
                   SizedBox(height: Responsive.bottomSafeArea),
                ],
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginMethodButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    final buttonWidth = Responsive.value(mobile: 90.0, tablet: 110.0);
    final iconSize = Responsive.value(mobile: 32.0, tablet: 36.0);

    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(Responsive.cardRadius),
      child: Container(
        width: buttonWidth,
        padding: EdgeInsets.symmetric(
          vertical: Responsive.value(mobile: 16.0, tablet: 20.0),
          horizontal: Responsive.value(mobile: 8.0, tablet: 12.0),
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(Responsive.cardRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isLoading
                ? SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  )
                : Icon(icon, size: iconSize, color: color),
            SizedBox(height: Responsive.value(mobile: 8.0, tablet: 10.0)),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: Responsive.sp(12),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(Widget child, String label, Color color, VoidCallback onTap) {
    final buttonSize = Responsive.value(mobile: 60.0, tablet: 70.0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Responsive.cardRadius),
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.grey200),
          borderRadius: BorderRadius.circular(Responsive.cardRadius),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Center(child: child),
      ),
    );
  }
}
