import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../../../core/widgets/dynamic_island_notification.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin({String? name, bool isGuest = false, String? mockRole}) async {
    if (!isGuest && mockRole == null && _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your Email')));
      return;
    }
    
    if (!isGuest && mockRole == null && _passwordController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your Password')));
       return;
    }

    setState(() => _isLoading = true);

    try {
      if (isGuest) {
        await ref.read(authStateProvider.notifier).login('employee@acme.com', password: 'password123');
      } else {
        final displayName = name ?? _nameController.text;
        final email = _emailController.text;
        final password = _passwordController.text;
        
        await ref.read(authStateProvider.notifier).login(email, password: password, name: displayName, mockRole: mockRole);
      }

      final authState = ref.read(authStateProvider);
      if (authState is AsyncError) {
         throw authState.error ?? Exception('Unknown authentication error');
      }

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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withOpacity(0.1)))),
          Positioned(bottom: -50, left: -50, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.secondary.withOpacity(0.1)))),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   const Icon(Icons.hub, size: 64, color: AppColors.primary).animate().scale(delay: 200.ms),
                   const SizedBox(height: 16),
                   Text('HRMS Portal', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.grey900)).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
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
                    child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Sign In', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                   ).animate().fadeIn(delay: 700.ms).scale(),

                   const SizedBox(height: 24),
                  
                   Row(children: [const Expanded(child: Divider()), Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('Or continue with', style: GoogleFonts.poppins(color: Colors.grey))), const Expanded(child: Divider())]).animate().fadeIn(delay: 800.ms),

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
                   ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.2),

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
                   ).animate().fadeIn(delay: 1000.ms),

                   const SizedBox(height: 16),

                   TextButton(
                    onPressed: () => _handleLogin(isGuest: true),
                    child: Text('Continue as Guest', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.grey700)),
                   ).animate().fadeIn(delay: 1100.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(Widget child, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.grey200),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Center(child: child),
      ),
    );
  }
}
