import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class PayrollOverviewHeader extends StatelessWidget {
  const PayrollOverviewHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark Background
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
            image: NetworkImage("https://grainy-gradients.vercel.app/noise.svg"), // Subtle texture if possible, otherwise solid
            fit: BoxFit.cover,
            opacity: 0.1,
        ),
         gradient: const LinearGradient(
          colors: [Color(0xFF2C2C2C), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overview',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(Icons.info_outline, color: Colors.white54, size: 20),
            ],
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                   Expanded(
                     flex: 3,
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Container(
                           padding: const EdgeInsets.all(10),
                           decoration: const BoxDecoration(
                             color: Color(0xFFE65100), // Orange
                             shape: BoxShape.circle,
                           ),
                           child: const Icon(Icons.account_balance_wallet, color: Colors.white),
                         ).animate().scale(delay: 200.ms),
                         const SizedBox(height: 12),
                         Text(
                           '\$2,458,320',
                           style: GoogleFonts.poppins(
                             color: Colors.white,
                             fontSize: 28,
                             fontWeight: FontWeight.bold,
                           ),
                         ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2),
                         Text(
                           'Total Gross Payroll',
                           style: GoogleFonts.poppins(
                             color: Colors.white70,
                             fontSize: 12,
                           ),
                         ),
                       ],
                     ),
                   ),
                   // Secondary Stats
                   Expanded(
                     flex: 4,
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.end,
                       children: [
                         _buildSmallStat('\$1,987,450', 'Net Payable Amount'),
                         const SizedBox(height: 16),
                         // Use Wrap to prevent overflow on small screens
                         Wrap(
                           spacing: 8,
                           runSpacing: 8,
                           alignment: WrapAlignment.end,
                           children: [
                             _buildTinyCard(Icons.receipt_long, '\$1.9M', 'Total Deductions'),
                             _buildTinyCard(Icons.pending_actions, '12', 'Pending Approvals'),
                           ],
                         ),
                       ],
                     ),
                   ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTinyCard(IconData icon, String value, String label) {
    return Container(
      // width: 100, // Removed fixed width
      constraints: const BoxConstraints(minWidth: 80),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 8), // Smaller font to fit
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1);
  }
}
