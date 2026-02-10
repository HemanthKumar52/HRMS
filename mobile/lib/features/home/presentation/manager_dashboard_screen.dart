import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import 'widgets/dashboard_drawer.dart';

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DashboardDrawer(),
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          'Manager Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.grey900),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Overview Stats
            Row(
              children: [
                Expanded(child: _buildStatCard('Pending Approvals', '12', Icons.pending_actions, Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Team Present', '24/30', Icons.people, Colors.green)),
              ],
            ).animate().fadeIn().slideX(),
            const SizedBox(height: 16),
             // My Tasks Shortcut
             InkWell(
               onTap: () => context.push('/tasks'),
               child: _buildStatCard('My Tasks', '4 Pending', Icons.task, Colors.blue),
             ).animate().fadeIn(delay: 50.ms),
            const SizedBox(height: 16),
            
            // Attendance Requests (Priority)
            Card(
              elevation: 4,
              shadowColor: Colors.orange.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.orange.withOpacity(0.5))),
              color: Colors.orange.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.priority_high, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text('Attendance Requests (Priority)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange[800])),
                      ],
                    ),
                    const Divider(color: Colors.orangeAccent),
                    _buildApprovalRow(context, 'John Doe', 'Clock In Request @ 9:02 AM', true),
                    _buildApprovalRow(context, 'Jane Smith', 'Leave Request (Sick)', false),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(),

            const SizedBox(height: 16),
            
            // Team Attendance Overview
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Team Attendance (Today)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                        TextButton(onPressed: (){}, child: const Text('View All')),
                      ],
                    ),
                    const Divider(),
                    _buildMemberRow('Sarah Johnson', 'In @ 9:00 AM', true),
                    _buildMemberRow('Mike Ross', 'In @ 9:15 AM', true),
                    _buildMemberRow('Rachel Zane', 'On Leave', false),
                    _buildMemberRow('Harvey Specter', 'Not Checked In', false),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),

             const SizedBox(height: 16),
            
            // Task Assignments
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Text('Task Assignments', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                         IconButton(onPressed: (){}, icon: const Icon(Icons.add_circle, color: AppColors.primary)),
                      ],
                    ),
                    const Divider(),
                    _buildTaskRow('Update Client Presentation', 'Sarah Johnson', 'Due Today', Colors.red),
                    _buildTaskRow('Review Q3 Reports', 'Mike Ross', 'Due Tomorrow', Colors.orange),
                    _buildTaskRow('Prepare Contract', 'Rachel Zane', 'Completed', Colors.green),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey600)),
        ],
      ),
    );
  }

  Widget _buildMemberRow(String name, String status, bool isPresent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isPresent ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            child: Icon(Icons.person, color: isPresent ? Colors.green : Colors.red, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w500))),
          Text(status, style: GoogleFonts.poppins(fontSize: 12, color: isPresent ? Colors.green : Colors.red)),
        ],
      ),
    );
  }

  Widget _buildTaskRow(String task, String assignee, String due, Color statusColor) {
     return Padding(
       padding: const EdgeInsets.symmetric(vertical: 12.0),
       child: Row(
         children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                   Text('Assigned to: $assignee', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey500)),
                ],
              ),
            ),
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
               decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
               child: Text(due, style: GoogleFonts.poppins(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
             ),
         ],
       ),
     );
  }
  Widget _buildApprovalRow(BuildContext context, String name, String request, bool isClockIn) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
             backgroundColor: Colors.white,
             child: Text(name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                Text(request, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey700)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(onPressed: () => _showApprovalDialog(context, name), icon: const Icon(Icons.check_circle, color: Colors.green)),
              IconButton(onPressed: (){}, icon: const Icon(Icons.cancel, color: Colors.red)),
            ],
          )
        ],
      ),
    );
  }

  void _showApprovalDialog(BuildContext context, String name) {
     showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
         title: Text('Approve Request?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
         content: Text('Are you sure you want to approve attendance request for $name?', style: GoogleFonts.poppins()),
         actions: [
           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
           FilledButton(onPressed: () {
             Navigator.pop(ctx);
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request Approved for $name')));
           }, child: const Text('Approve')),
         ],
       )
     );
  }
}
