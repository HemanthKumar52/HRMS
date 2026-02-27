import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/responsive.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  LoginMethod? _currentLoginMethod;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin({
    LoginMethod loginMethod = LoginMethod.password,
  }) async {
    if (loginMethod == LoginMethod.password && _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your Email')));
      return;
    }

    if (loginMethod == LoginMethod.password && _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your Password')));
      return;
    }

    setState(() {
      _isLoading = true;
      _currentLoginMethod = loginMethod;
    });

    try {
      final email = _emailController.text;
      final password = _passwordController.text;

      await ref.read(authStateProvider.notifier).login(email, password: password);

      final authState = ref.read(authStateProvider);
      if (authState is AsyncError) {
        throw authState.error ?? Exception('Unknown authentication error');
      }

      await ref.read(loginMethodProvider.notifier).setLoginMethod(loginMethod);

      if (mounted) {
        DynamicIslandManager().show(context, message: 'Successfully Logged In', isError: false);
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

  Future<void> _handleMicrosoftLogin() async {
    setState(() {
      _isLoading = true;
      _currentLoginMethod = LoginMethod.password;
    });

    try {
      // Launch Microsoft OAuth consent page
      // The backend handles the OAuth flow and returns tokens
      final authUrl = Uri.parse('${ApiConstants.baseUrl}/auth/microsoft');

      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);

        // After user completes OAuth in browser, they return to the app.
        // For mobile deep-link flow, the callback URL redirects back with a token.
        // For now, show a dialog to enter the token received from the callback.
        if (mounted) {
          final token = await _showSsoTokenInputDialog();
          if (token != null && token.isNotEmpty) {
            await ref.read(authStateProvider.notifier).loginWithSSO(token);

            final authState = ref.read(authStateProvider);
            if (authState is AsyncError) {
              throw authState.error ?? Exception('SSO authentication error');
            }

            await ref.read(loginMethodProvider.notifier).setLoginMethod(LoginMethod.password);

            if (mounted) {
              DynamicIslandManager().show(context, message: 'Successfully Logged In via Microsoft', isError: false);
              context.go('/');
            }
          }
        }
      } else {
        // Fallback: show token input directly (for environments without browser)
        if (mounted) {
          DynamicIslandManager().show(
            context,
            message: 'Cannot open browser. Please configure Microsoft SSO.',
            isError: true,
          );
        }
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

  Future<String?> _showSsoTokenInputDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Microsoft SSO', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'After signing in with Microsoft, paste the token received from the callback.',
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.grey600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Paste Microsoft access token',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

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
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: AppColors.grey50,
                      ),
                    ).animate().fadeIn(delay: 450.ms).slideX(),
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
                    ).animate().fadeIn(delay: 550.ms).slideX(),

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
                    ).animate().fadeIn(delay: 650.ms).scale(),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('or', style: GoogleFonts.poppins(color: Colors.grey)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ).animate().fadeIn(delay: 700.ms),

                    const SizedBox(height: 16),

                    // Microsoft SSO Button
                    OutlinedButton(
                      onPressed: _isLoading ? null : _handleMicrosoftLogin,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey.shade300),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            'https://learn.microsoft.com/en-us/entra/identity-platform/media/howto-add-branding-in-apps/ms-symbollockup_mssymbol_19.png',
                            width: 20,
                            height: 20,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.window, size: 20, color: Color(0xFF00A4EF)),
                          ),
                          const SizedBox(width: 12),
                          Text('Sign in with Microsoft', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ).animate().fadeIn(delay: 750.ms).scale(),

                    SizedBox(height: Responsive.bottomSafeArea + 16),
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
