import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../shared/providers/work_mode_provider.dart';

class ProfileGlassSheet extends ConsumerWidget {
  const ProfileGlassSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassContainer(
      height: 280,
      width: double.infinity,
      blur: 20,
      color: Colors.white.withOpacity(0.1),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.2),
          Colors.white.withOpacity(0.05),
        ],
      ),
      border: const Border.fromBorderSide(BorderSide.none),
      shadowStrength: 4,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),
          
          _buildOption(
            context,
            icon: Icons.person_outline,
            label: 'My Profile',
            subtitle: 'View personal & work details',
            onTap: () {
              Navigator.pop(context); // Close sheet
              _showProfileDetails(context);
            },
          ),
          
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          
          _buildOption(
            context,
            icon: Icons.logout,
            label: 'Log Out',
            subtitle: 'Sign out of your account',
            isDestructive: true,
            onTap: () async {
               Navigator.pop(context);
               await ref.read(authStateProvider.notifier).logout();
               await ref.read(workModeProvider.notifier).clearWorkMode();
               if (context.mounted) {
                 context.go('/login');
               }
            },
          ),
          
          const Spacer(),
          Text('v1.0.0+1', style: GoogleFonts.poppins(color: Colors.white24, fontSize: 10)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, {required IconData icon, required String label, required String subtitle, required VoidCallback onTap, bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDestructive ? Colors.red.withOpacity(0.1) : Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isDestructive ? Colors.redAccent : Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                  Text(subtitle, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }

  void _showProfileDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          borderRadius: BorderRadius.circular(24),
          blur: 20,
          border: const Border.fromBorderSide(BorderSide.none),
          color: Colors.black.withOpacity(0.8), // Dark detailed view
           gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.6),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary,
                  child: Text('JD', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 16),
                Text('John Doe', style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Software Engineer', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14)),
                 const SizedBox(height: 24),
                 
                 _buildDetailRow(Icons.badge, 'Employee ID', 'EMP-2024-001'),
                 _buildDetailRow(Icons.email, 'Email', 'john.doe@kaaspro.com'),
                 _buildDetailRow(Icons.phone, 'Phone', '+91 98765 43210'),
                 _buildDetailRow(Icons.business, 'Department', 'Engineering'),
                 _buildDetailRow(Icons.apps, 'Connected Apps', 'Slack, Jira, GitHub'),
                 
                 const SizedBox(height: 24),
                 FilledButton(
                   onPressed: () => Navigator.pop(context),
                   style: FilledButton.styleFrom(
                     backgroundColor: Colors.white.withOpacity(0.1),
                     foregroundColor: Colors.white,
                   ),
                   child: const Text('Close'),
                 )
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
