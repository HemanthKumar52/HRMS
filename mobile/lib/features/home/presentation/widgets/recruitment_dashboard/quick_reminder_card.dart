import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickReminderCard extends StatelessWidget {
  const QuickReminderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF00695C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        // Simplified abstract background placeholder
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
               Container(
                 padding: const EdgeInsets.all(4),
                 decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                 child: const Icon(Icons.notifications_active, color: Colors.white, size: 14),
               ),
               const SizedBox(width: 8),
               Text('Quick Reminder', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'You have 21 Interview Schedule Today!',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Don\'t forget to schedule interviews',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {}, 
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Schedule Now'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}
