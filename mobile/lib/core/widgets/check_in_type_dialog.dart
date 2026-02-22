import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';

/// Type of check-in for mobile users
enum CheckInType {
  onDuty,
  fieldVisit,
}

extension CheckInTypeExtension on CheckInType {
  String get displayName {
    switch (this) {
      case CheckInType.onDuty:
        return 'On Duty';
      case CheckInType.fieldVisit:
        return 'Field Visit';
    }
  }

  String get description {
    switch (this) {
      case CheckInType.onDuty:
        return 'Regular work from your current location';
      case CheckInType.fieldVisit:
        return 'Client visit or field work';
    }
  }

  IconData get icon {
    switch (this) {
      case CheckInType.onDuty:
        return Icons.work;
      case CheckInType.fieldVisit:
        return Icons.directions_walk;
    }
  }

  Color get color {
    switch (this) {
      case CheckInType.onDuty:
        return AppColors.primary;
      case CheckInType.fieldVisit:
        return AppColors.secondary;
    }
  }
}

/// Dialog to select check-in type (On Duty or Field Visit)
class CheckInTypeDialog extends StatelessWidget {
  const CheckInTypeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: GlassCard(
          blur: 12,
          opacity: 0.15,
          borderRadius: 20,
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.location_on, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select Check-In Type',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Options
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'What type of check-in is this?',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // On Duty Option
                  _buildOption(
                    context,
                    CheckInType.onDuty,
                  ),

                  const SizedBox(height: 12),

                  // Field Visit Option
                  _buildOption(
                    context,
                    CheckInType.fieldVisit,
                  ),

                  const SizedBox(height: 16),

                  // Cancel Button
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, CheckInType type) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: type.color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
          color: type.color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: type.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                type.icon,
                color: type.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: type.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: type.color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

/// Show check-in type selection dialog
Future<CheckInType?> showCheckInTypeDialog(BuildContext context) async {
  return await showDialog<CheckInType>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const CheckInTypeDialog(),
  );
}
