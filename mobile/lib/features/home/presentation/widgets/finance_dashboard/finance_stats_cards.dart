import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/widgets/glass_card.dart';

class FinanceStatsCards extends StatelessWidget {
  const FinanceStatsCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildBudgetCard(context),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildSmallStatCard(context, 'Total Payroll', '\$2,458,900', Colors.green, Icons.monetization_on)),
            const SizedBox(width: 16),
            Expanded(child: _buildSmallStatCard(context, 'Reimbursement', '\$124,200', Colors.red, Icons.receipt)),
          ],
        ),
      ],
    );
  }

  Widget _buildBudgetCard(BuildContext context) {
    return GlassCard(
      blur: 12,
      opacity: 0.15,
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.account_balance_wallet, color: Colors.orange, size: 20),
              ),
              Icon(Icons.north_east, color: context.textTertiary, size: 16),
            ],
          ),
          const SizedBox(height: 16),
          Text('Budget Remaining', style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary)),
          Row(
            children: [
              Text('\$2,458,900', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: context.textPrimary)),
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
            ],
          ),
          const SizedBox(height: 16),
          // Progress Bar (Multi-colored)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                Expanded(flex: 50, child: Container(height: 8, color: Colors.orange)),
                Expanded(flex: 20, child: Container(height: 8, color: const Color(0xFF004D40))),
                Expanded(flex: 30, child: Container(height: 8, color: context.isDark ? Colors.white70 : Colors.black87)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _legend(context, 'Salary Budget', Colors.orange),
              _legend(context, 'Benefits', const Color(0xFF004D40)),
              _legend(context, 'HR Ops', context.isDark ? Colors.white70 : Colors.black87),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: context.textSecondary)),
      ],
    );
  }

  Widget _buildSmallStatCard(BuildContext context, String label, String value, Color color, IconData icon) {
    return GlassCard(
      blur: 12,
      opacity: 0.15,
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFE0F2F1), shape: BoxShape.circle),
                child: Icon(icon, color: const Color(0xFF00695C), size: 18),
              ),
              // Icon(Icons.refresh, size: 14, color: AppColors.grey400),
            ],
          ),
          const SizedBox(height: 12),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary)),
          Row(
            children: [
              Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary)),
              const SizedBox(width: 4),
              Icon(Icons.check_circle, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 8),
          // Bar code effect
          Row(
             children: List.generate(20, (index) =>
                Container(
                  margin: const EdgeInsets.only(right: 2),
                  width: 2,
                  height: 10 + (index % 3) * 5.0,
                  color: index < 10 ? color.withValues(alpha: 0.5) : context.borderColor
                )
             ),
          ),
        ],
      ),
    );
  }
}
