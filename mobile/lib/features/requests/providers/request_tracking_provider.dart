import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

/// Selected tab index for context-aware FAB behavior
final selectedRequestTabProvider = StateProvider<int>((ref) => 0);

/// Mock ticket data
final userTicketsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 600));
  return [
    {
      'id': 'TKT-204',
      'title': 'Laptop screen flickering',
      'department': 'IT Support',
      'priority': 'High',
      'status': 'In Progress',
      'date': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'id': 'TKT-198',
      'title': 'VPN access request',
      'department': 'IT Support',
      'priority': 'Medium',
      'status': 'Resolved',
      'date': DateTime.now().subtract(const Duration(days: 5)),
    },
    {
      'id': 'TKT-185',
      'title': 'Email not syncing on mobile',
      'department': 'IT Support',
      'priority': 'Low',
      'status': 'Closed',
      'date': DateTime.now().subtract(const Duration(days: 12)),
    },
  ];
});

/// Mock claims data
final userClaimsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 600));
  return [
    {
      'id': 'CLM-045',
      'title': 'Client visit travel expense',
      'type': 'Travel',
      'amount': 2500.0,
      'status': 'Pending',
      'date': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'id': 'CLM-039',
      'title': 'Team lunch - project celebration',
      'type': 'Food',
      'amount': 1800.0,
      'status': 'Approved',
      'date': DateTime.now().subtract(const Duration(days: 7)),
    },
    {
      'id': 'CLM-032',
      'title': 'Medical checkup reimbursement',
      'type': 'Medical',
      'amount': 3200.0,
      'status': 'Rejected',
      'date': DateTime.now().subtract(const Duration(days: 15)),
    },
  ];
});

/// Shift request data from API
final userShiftRequestsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get(ApiConstants.shiftRequests);
  final list = response.data as List<dynamic>;
  return list.map((e) {
    final item = Map<String, dynamic>.from(e as Map);
    // Parse date fields for UI compatibility
    if (item['requestDate'] != null) {
      item['date'] = DateTime.parse(item['requestDate'].toString());
    } else if (item['createdAt'] != null) {
      item['date'] = DateTime.parse(item['createdAt'].toString());
    } else {
      item['date'] = DateTime.now();
    }
    // Map status to title-case for display
    final rawStatus = (item['status'] as String?) ?? 'PENDING';
    item['status'] = rawStatus[0] + rawStatus.substring(1).toLowerCase();
    return item;
  }).toList();
});
