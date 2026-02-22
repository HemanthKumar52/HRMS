import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/widgets/safe_scaffold.dart';
import 'widgets/asset_dashboard/purchase_trend_chart.dart';
import 'widgets/asset_dashboard/assets_by_department_chart.dart';
import 'widgets/asset_dashboard/asset_stats_cards.dart';
import 'widgets/asset_dashboard/asset_value_cards.dart';
import 'widgets/asset_dashboard/assets_by_category_chart.dart';
import 'widgets/asset_dashboard/asset_list_table.dart';
import 'widgets/dashboard_drawer.dart';

class AssetManagementDashboardScreen extends StatelessWidget {
  const AssetManagementDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeScaffold(
      drawer: const DashboardDrawer(),
      backgroundColor: context.scaffoldBg,
      appBar: AdaptiveAppBar(
        title: 'Asset Management',
        actions: [
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add New Job'), // Matching the screenshot, though likely 'Add Asset'
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
            // Top Row: Trend & By Department
            LayoutBuilder(builder: (context, constraints) {
               if (constraints.maxWidth > 800) {
                 return Row(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Expanded(flex: 3, child: PurchaseTrendChart()),
                     const SizedBox(width: 16),
                     const Expanded(flex: 2, child: AssetsByDepartmentChart()),
                   ],
                 );
               } else {
                 return Column(
                   children: [
                     const PurchaseTrendChart(),
                     const SizedBox(height: 16),
                     const AssetsByDepartmentChart(),
                   ],
                 );
               }
            }).animate().fadeIn().slideX(),
            
            const SizedBox(height: 16),
            const AssetStatsCards().animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            const SizedBox(height: 16),
            
            // Middle section: Value vs Category
            LayoutBuilder(builder: (context, constraints) {
               if (constraints.maxWidth > 800) {
                 return Row(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Expanded(flex: 3, child: AssetValueCards()),
                     const SizedBox(width: 16),
                     const Expanded(flex: 2, child: AssetsByCategoryChart()),
                   ],
                 );
               } else {
                 return Column(
                   children: [
                     const AssetValueCards(),
                     const SizedBox(height: 16),
                     const AssetsByCategoryChart(),
                   ],
                 );
               }
            }).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

            const SizedBox(height: 16),
            const AssetListTable().animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
