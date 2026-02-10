import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class SalaryInfoCard extends StatelessWidget {
  const SalaryInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.blue[900], // Dark blue like mockup
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Earnings', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                    Text('\$4,500.00', style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                   child: const Icon(Icons.download, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildInfoItem('Gross Salary', '\$60,000/yr'),
                const SizedBox(width: 24),
                _buildInfoItem('Net Pay', '\$4,200/mo'),
                 const SizedBox(width: 24),
                _buildInfoItem('Deductions', '\$300/mo'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}
