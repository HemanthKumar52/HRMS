import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/safe_scaffold.dart';
import 'widgets/finance_dashboard/finance_stats_cards.dart';
import 'widgets/finance_dashboard/headcount_vs_payroll_chart.dart';
import 'widgets/finance_dashboard/hr_cost_breakdown_chart.dart';
import 'widgets/dashboard_drawer.dart';

class FinanceDashboardScreen extends StatelessWidget {
  const FinanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeScaffold(
      drawer: const DashboardDrawer(),
      backgroundColor: context.scaffoldBg,
      appBar: AdaptiveAppBar(
        title: 'Finance Dashboard',
        actions: [
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.file_download_outlined, size: 16),
            label: const Text('Export CSV'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const FinanceStatsCards().animate().fadeIn().slideX(),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(flex: 3, child: HeadcountVsPayrollChart()),
                if (MediaQuery.of(context).size.width > 600) ...[
                  const SizedBox(width: 16),
                  const Expanded(flex: 2, child: HrCostBreakdownChart()),
                ] else ...[
                   // On Mobile, stack vertically
                ],
              ],
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
             
            if (MediaQuery.of(context).size.width <= 600)
              const Padding(
                 padding: EdgeInsets.only(top: 16),
                 child: HrCostBreakdownChart(),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
            
            const SizedBox(height: 16),
            
            // AI Assistant
             GlassCard(
               blur: 12,
               opacity: 0.15,
               borderRadius: 16,
               padding: const EdgeInsets.all(16),
               child: Row(
                 children: [
                   Container(
                     padding: const EdgeInsets.all(10),
                     decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), shape: BoxShape.circle),
                     child: const Icon(Icons.auto_awesome, color: Colors.purple),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text('How can I help you today?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                         Text('AI Finance Assistant', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey600)),
                       ],
                     ),
                   ),
                 ],
               ),
             ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
