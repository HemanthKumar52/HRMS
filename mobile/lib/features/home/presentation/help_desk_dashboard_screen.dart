import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/widgets/safe_scaffold.dart';
import 'widgets/help_desk_dashboard/help_desk_stats_cards.dart';
import 'widgets/help_desk_dashboard/ticket_trends_chart.dart';
import 'widgets/help_desk_dashboard/tickets_by_status_chart.dart';
import 'widgets/help_desk_dashboard/sla_compliance_card.dart';
import 'widgets/help_desk_dashboard/backlog_growth_chart.dart';
import 'widgets/help_desk_dashboard/tickets_by_category_chart.dart';
import 'widgets/help_desk_dashboard/agent_performance_list.dart';
import 'widgets/help_desk_dashboard/activity_feed_card.dart';
import 'widgets/dashboard_drawer.dart';

class HelpDeskDashboardScreen extends StatelessWidget {
  const HelpDeskDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeScaffold(
      drawer: const DashboardDrawer(),
      backgroundColor: context.scaffoldBg,
      appBar: AdaptiveAppBar(
        title: 'Help Desk Dashboard',
        actions: [
          OutlinedButton.icon(
             onPressed: (){},
             icon: const Icon(Icons.person_add_alt, size: 16),
             label: const Text('Assign Agent'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Close Ticket'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF264653), // Dark Blue
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create Ticket'),
            style: FilledButton.styleFrom(
               backgroundColor: Colors.deepOrange,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const HelpDeskStatsCards().animate().fadeIn().slideX(),
            const SizedBox(height: 16),
            
            // Charts Row 1
            LayoutBuilder(builder: (context, constraints) {
               if(constraints.maxWidth > 900) {
                 return Row(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Expanded(flex: 3, child: TicketTrendsChart()),
                     const SizedBox(width: 16),
                     const Expanded(flex: 2, child: TicketsByStatusChart()),
                   ],
                 );
               } else {
                 return Column(
                   children: [
                     const TicketTrendsChart(),
                     const SizedBox(height: 16),
                     const TicketsByStatusChart(),
                   ],
                 );
               }
            }).animate().fadeIn(delay: 200.ms),
            
            const SizedBox(height: 16),
            
            // Charts Row 2: SLA, Backlog, Category
            LayoutBuilder(builder: (context, constraints) {
               if(constraints.maxWidth > 1100) {
                 return Row(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Expanded(flex: 1, child: SlaComplianceCard()),
                     const SizedBox(width: 16),
                     const Expanded(flex: 1, child: BacklogGrowthChart()),
                     const SizedBox(width: 16),
                     const Expanded(flex: 1, child: TicketsByCategoryChart()),
                   ],
                 );
               } else {
                 return Column(
                   children: [
                     const SlaComplianceCard(),
                     const SizedBox(height: 16),
                     const BacklogGrowthChart(),
                     const SizedBox(height: 16),
                     const TicketsByCategoryChart(),
                   ],
                 );
               }
            }).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 16),
            
            // Bottom Row: Agents, Feed
            LayoutBuilder(builder: (context, constraints) {
               if(constraints.maxWidth > 900) {
                 return Row(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Expanded(flex: 2, child: AgentPerformanceList()),
                     const SizedBox(width: 16),
                     const Expanded(flex: 1, child: ActivityFeedCard()),
                   ],
                 );
               } else {
                 return Column(
                   children: [
                     const AgentPerformanceList(),
                     const SizedBox(height: 16),
                     const ActivityFeedCard(),
                   ],
                 );
               }
            }).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
