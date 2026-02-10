import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/work_mode_provider.dart';

class WorkModeSelectionScreen extends ConsumerWidget {
  const WorkModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Select Work Mode',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how you\'re working today',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 32),
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
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 20),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Requirements:',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
              ),
              const SizedBox(height: 8),
              ...requirements.map((req) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            req,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[700],
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
