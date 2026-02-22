import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/responsive.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/dynamic_island_notification.dart';
import '../../../core/widgets/safe_scaffold.dart';

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
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.3),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        context.glassOverlayStart,
                        context.glassOverlayEnd,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.grey300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text('Filter Approvals', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      Text('Request Type', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.grey600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['All', 'Attendance', 'Leave', 'Claim'].map((type) {
                          final isSelected = _selectedType == type;
                          return ChoiceChip(
                            label: Text(type),
                            selected: isSelected,
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.primary : AppColors.grey700,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.grey300,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            showCheckmark: false,
                            onSelected: (val) {
                              setModalState(() => _selectedType = type);
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      Text('Time Period', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.grey600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['All', 'Today', 'Yesterday', 'Last Week'].map((date) {
                          final isSelected = _selectedDate == date;
                          return ChoiceChip(
                            label: Text(date),
                            selected: isSelected,
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.primary : AppColors.grey700,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.grey300,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            showCheckmark: false,
                            onSelected: (val) {
                              setModalState(() => _selectedDate = date);
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            _applyFilters();
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Apply Filters', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return SafeScaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AdaptiveAppBar(
        title: 'Pending Approvals',
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_alt_outlined,
              color: _selectedType != 'All' || _selectedDate != 'All'
                  ? AppColors.primary
                  : AppColors.grey500,
            ),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: _requests.isEmpty
          ? Center(child: Text('No pending approvals found.', style: GoogleFonts.poppins(color: Colors.grey)))
          : ListView.separated(
              padding: EdgeInsets.only(
                left: Responsive.horizontalPadding,
                right: Responsive.horizontalPadding,
                top: 16,
                bottom: 100, // Space for glass nav bar
              ),
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

    return GlassCard(
      blur: 12,
      opacity: 0.15,
      borderRadius: Responsive.cardRadius,
      padding: EdgeInsets.all(Responsive.horizontalPadding),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(typeIcon, color: typeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                    Text(req['type'], style: GoogleFonts.poppins(fontSize: 12, color: typeColor, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Text(req['date'], style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey500)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(req['details'], style: GoogleFonts.poppins(fontSize: 14, color: context.textPrimary)),
          ),
          const SizedBox(height: 16),
          // Equal-sized buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () {
                      DynamicIslandManager().show(context, message: 'Request rejected', isError: true);
                      setState(() {
                        _requests.removeAt(index);
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Reject', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      DynamicIslandManager().show(context, message: 'Request approved');
                      setState(() {
                        _requests.removeAt(index);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Approve', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX();
  }
}
