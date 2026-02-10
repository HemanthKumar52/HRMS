import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../data/leave_model.dart';

class LeaveBalanceCard extends StatelessWidget {
  final LeaveBalance balance;

  const LeaveBalanceCard({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getTypeColor(balance.type),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  balance.type.toString().split('.').last.capitalize,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  balance.available.toStringAsFixed(
                    balance.available == balance.available.toInt()
                        ? 0
                        : 1,
                  ),
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '/ ${balance.total.toInt()} days',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: AppColors.grey500,
                    ),
                  ),
                ),
              ],
            ),
            LinearProgressIndicator(
              value: balance.total > 0 ? balance.used / balance.total : 0,
              backgroundColor: AppColors.grey200,
              valueColor: AlwaysStoppedAnimation(_getTypeColor(balance.type)),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(LeaveType type) {
    switch (type) {
      case LeaveType.casual:
        return AppColors.primary;
      case LeaveType.sick:
        return AppColors.error;
      case LeaveType.earned:
        return AppColors.success;
      case LeaveType.unpaid:
        return AppColors.warning;
      case LeaveType.maternity:
        return Colors.pink;
      case LeaveType.paternity:
        return Colors.blue;
      case LeaveType.od:
        return Colors.purpleAccent;
    }
  }
}
