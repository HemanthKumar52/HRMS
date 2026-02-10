import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AttendanceStatusCard extends StatelessWidget {
  const AttendanceStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF212121), // Dark
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Attendance Status', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: const Icon(Icons.calendar_today, color: Colors.white, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Total Working Days', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
          Text('300', style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(flex: 50, child: Container(height: 24, color: const Color(0xFFE65100))), // Orange (Present)
                Expanded(flex: 20, child: Container(height: 24, color: const Color(0xFFFFAB91))), // Light Orange
                Expanded(flex: 15, child: Container(height: 24, color: const Color(0xFFFFCCBC))), 
                Expanded(flex: 15, child: Container(height: 24, color: const Color(0xFFFFAB91).withOpacity(0.5))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildLegendItem('Present', '2458', const Color(0xFFE65100)),
          _buildLegendItem('WFH', '187', const Color(0xFFFFAB91)),
          _buildLegendItem('Late', '89', const Color(0xFFFFCCBC)),
          _buildLegendItem('On Leave', '78', const Color(0xFFFFAB91).withOpacity(0.5)),
          _buildLegendItem('Absent', '124', Colors.white30),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
            ],
          ),
          Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
