import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class FinanceStatsCards extends StatelessWidget {
  const FinanceStatsCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildBudgetCard(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildSmallStatCard('Total Payroll', '\$2,458,900', Colors.green, Icons.monetization_on)),
            const SizedBox(width: 16),
            Expanded(child: _buildSmallStatCard('Reimbursement', '\$124,200', Colors.red, Icons.receipt)),
          ],
        ),
      ],
    );
  }

  Widget _buildBudgetCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.account_balance_wallet, color: Colors.orange, size: 20),
              ),
              const Icon(Icons.north_east, color: AppColors.grey400, size: 16),
            ],
          ),
          const SizedBox(height: 16),
          Text('Budget Remaining', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey600)),
          Row(
            children: [
              Text('\$2,458,900', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.grey900)),
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
                Expanded(flex: 30, child: Container(height: 8, color: Colors.black87)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _legend('Salary Budget', Colors.orange),
              _legend('Benefits', const Color(0xFF004D40)),
              _legend('HR Ops', Colors.black87),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey500)),
      ],
    );
  }

  Widget _buildSmallStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
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
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey600)),
          Row(
            children: [
              Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  color: index < 10 ? color.withOpacity(0.5) : AppColors.grey200
                )
             ),
          ),
        ],
      ),
    );
  }
}
