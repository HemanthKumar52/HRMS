import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive.dart';
import '../../../shared/providers/work_mode_provider.dart';

class WorkModeSelectionScreen extends ConsumerWidget {
  const WorkModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Responsive.init(context);
    return SafeScaffold(
      body: Padding(
        padding: EdgeInsets.all(Responsive.value(mobile: 20.0, tablet: 32.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: Responsive.value(mobile: 20.0, tablet: 32.0)),
            Text(
              'Select Work Mode',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.sp(26),
                  ),
            ),
            SizedBox(height: Responsive.value(mobile: 8.0, tablet: 12.0)),
            Text(
              'Choose how you\'re working today',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                    fontSize: Responsive.sp(16),
                  ),
            ),
            SizedBox(height: Responsive.value(mobile: 28.0, tablet: 40.0)),
              Expanded(
                child: ListView(
                  children: [
                    _WorkModeCard(
                      title: 'Office',
                      description: 'Working from office location',
                      icon: Icons.business,
                      color: Colors.blue,
                      requirements: [
                        'Biometric Authentication (Fingerprint/Face ID)',
                        'Geofence Verification (200m radius)',
                        'Clock In/Out',
                        'All three required for attendance',
                      ],
                      onTap: () {
                        ref.read(workModeProvider.notifier).setWorkMode('OFFICE');
                        context.go('/');
                      },
                    ),
                    SizedBox(height: Responsive.horizontalPadding),
                    _WorkModeCard(
                      title: 'Remote',
                      description: 'Working from home',
                      icon: Icons.home,
                      color: Colors.green,
                      requirements: [
                        'Clock In/Out only',
                        'No location verification',
                        'No biometric required',
                      ],
                      onTap: () {
                        ref.read(workModeProvider.notifier).setWorkMode('REMOTE');
                        context.go('/');
                      },
                    ),
                    SizedBox(height: Responsive.horizontalPadding),
                    _WorkModeCard(
                      title: 'On Duty (OD)',
                      description: 'Field visits and tasks',
                      icon: Icons.directions_car,
                      color: Colors.orange,
                      requirements: [
                        'GPS Location captured on Clock In',
                        'GPS Location captured on Clock Out',
                        'Location name/address recorded',
                        'Requires manager approval',
                      ],
                      onTap: () {
                        ref.read(workModeProvider.notifier).setWorkMode('ON_DUTY');
                        context.go('/');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}

class _WorkModeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> requirements;
  final VoidCallback onTap;

  const _WorkModeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.requirements,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Responsive.cardRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Responsive.cardRadius),
        child: Padding(
          padding: EdgeInsets.all(Responsive.value(mobile: 16.0, tablet: 24.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(Responsive.value(mobile: 12.0, tablet: 16.0)),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Responsive.cardRadius),
                    ),
                    child: Icon(icon, color: color, size: Responsive.sp(28)),
                  ),
                  SizedBox(width: Responsive.horizontalPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: Responsive.sp(18),
                              ),
                        ),
                        SizedBox(height: Responsive.value(mobile: 4.0, tablet: 6.0)),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                                fontSize: Responsive.sp(14),
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: Responsive.sp(20)),
                ],
              ),
              SizedBox(height: Responsive.horizontalPadding),
              const Divider(),
              SizedBox(height: Responsive.value(mobile: 12.0, tablet: 16.0)),
              Text(
                'Requirements:',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: Responsive.sp(13),
                    ),
              ),
              SizedBox(height: Responsive.value(mobile: 8.0, tablet: 12.0)),
              ...requirements.map((req) => Padding(
                    padding: EdgeInsets.only(bottom: Responsive.value(mobile: 6.0, tablet: 8.0)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: Responsive.sp(18),
                          color: color,
                        ),
                        SizedBox(width: Responsive.value(mobile: 8.0, tablet: 12.0)),
                        Expanded(
                          child: Text(
                            req,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[700],
                                  fontSize: Responsive.sp(12),
                                ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
