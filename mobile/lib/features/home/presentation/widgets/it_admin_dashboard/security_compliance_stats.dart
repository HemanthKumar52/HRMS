import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_theme_extensions.dart';

class SecurityComplianceStats extends StatelessWidget {
  const SecurityComplianceStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: context.borderColor)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Security & Compliance', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: context.textPrimary)),
            const SizedBox(height: 20),
            _buildItem(context, '47', 'Failed Logins', 'Last 24h', Colors.red),
            const Divider(),
            _buildItem(context, '12', 'Suspicious Alerts', 'Active', Colors.orange),
            const Divider(),
            _buildItem(context, '27', 'Blocked IPs', 'Currently blocked', Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, String value, String label, String subLabel, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 3, height: 30, color: color),
              const SizedBox(width: 8),
              Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: context.textPrimary)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimary)),
                  Text(subLabel, style: GoogleFonts.poppins(fontSize: 10, color: context.textSecondary)),
                ],
              ),
            ],
          ),
          // Mini chart placeholder
          Icon(Icons.show_chart, color: color),
        ],
      ),
    );
  }
}
