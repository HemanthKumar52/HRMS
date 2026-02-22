import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/motivational_quotes.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme_extensions.dart';
import 'glass_card.dart';

class GreetingDialog extends StatelessWidget {
  final String userName;

  const GreetingDialog({super.key, required this.userName});

  static void show(BuildContext context, String userName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (ctx) => GreetingDialog(userName: userName),
    );
    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    final randomQuote =
        motivationalQuotes[Random().nextInt(motivationalQuotes.length)];

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GlassCard(
        blur: 25,
        opacity: 0.2,
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.waving_hand, color: Colors.amber, size: 48),
            const SizedBox(height: 16),
            Text(
              '$greeting,',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.grey600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              userName,
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
                ),
              ),
              child: Text(
                '"$randomQuote"',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppColors.grey700,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Let's Go!",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
