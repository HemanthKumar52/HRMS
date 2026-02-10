import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import 'widgets/dashboard_drawer.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  // Mock Data
  final List<Map<String, dynamic>> _allRequests = [
    {'type': 'Attendance', 'name': 'John Doe', 'details': 'Clock In Request @ 09:15 AM', 'date': 'Today', 'status': 'Pending'},
    {'type': 'Leave', 'name': 'Jane Smith', 'details': 'Sick Leave (1 Day)', 'date': 'Yesterday', 'status': 'Pending'},
    {'type': 'Claim', 'name': 'Mike Ross', 'details': 'Travel Expense - ₹1,200', 'date': '02 Feb', 'status': 'Pending'},
    {'type': 'Leave', 'name': 'Sarah Johnson', 'details': 'Casual Leave (2 Days)', 'date': '01 Feb', 'status': 'Pending'},
    {'type': 'Attendance', 'name': 'Emily Davis', 'details': 'Work From Home', 'date': 'Today', 'status': 'Pending'},
  ];

  List<Map<String, dynamic>> _requests = [];
  String _selectedType = 'All';
  String _selectedDate = 'All';

  @override
  void initState() {
    super.initState();
    _requests = List.from(_allRequests);
  }

  void _applyFilters() {
    setState(() {
      _requests = _allRequests.where((req) {
        final matchesType = _selectedType == 'All' || req['type'] == _selectedType;
        final matchesDate = _selectedDate == 'All' || 
                            (_selectedDate == 'Today' && req['date'] == 'Today') ||
                            (_selectedDate == 'Yesterday' && req['date'] == 'Yesterday') ||
                            (_selectedDate == 'Last Week' && !['Today', 'Yesterday'].contains(req['date']));
        return matchesType && matchesDate;
      }).toList();
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filter Approvals', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Text('Request Type', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['All', 'Attendance', 'Leave', 'Claim'].map((type) {
                      final isSelected = _selectedType == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (val) {
                          setModalState(() => _selectedType = type);
                          setState(() {}); // Update parent state reference if needed, but applyFilters handles real logic
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text('Time Period', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['All', 'Today', 'Yesterday', 'Last Week'].map((date) {
                      final isSelected = _selectedDate == date;
                      return ChoiceChip(
                        label: Text(date),
                        selected: isSelected,
                        onSelected: (val) {
                          setModalState(() => _selectedDate = date);
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () {
                        _applyFilters();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  )
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DashboardDrawer(),
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text('Pending Approvals', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: _selectedType != 'All' || _selectedDate != 'All' ? AppColors.primary : Colors.grey),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: _requests.isEmpty 
        ? Center(child: Text('No pending approvals found.', style: GoogleFonts.poppins(color: Colors.grey)))
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _requests.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final req = _requests[i];
              return _buildApprovalCard(req, i);
            },
          ),
    );
  }

  Widget _buildApprovalCard(Map<String, dynamic> req, int index) {
    Color typeColor = Colors.blue;
    IconData typeIcon = Icons.info;

    switch (req['type']) {
      case 'Attendance':
        typeColor = Colors.orange;
        typeIcon = Icons.access_time;
        break;
      case 'Leave':
        typeColor = Colors.purple;
        typeIcon = Icons.calendar_today;
        break;
      case 'Claim':
        typeColor = Colors.green;
        typeIcon = Icons.receipt_long;
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: typeColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(typeIcon, color: typeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(req['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                      Text(req['type'], style: GoogleFonts.poppins(fontSize: 12, color: typeColor, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Text(req['date'], style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text(req['details'], style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request Rejected')));
                       setState(() {
                         _requests.removeAt(index);
                       });
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request Approved')));
                        setState(() {
                         _requests.removeAt(index);
                       });
                    },
                    style: FilledButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX();
  }
}
