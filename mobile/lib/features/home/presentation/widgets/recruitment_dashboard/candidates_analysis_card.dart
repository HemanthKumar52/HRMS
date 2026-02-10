import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class CandidatesAnalysisCard extends StatelessWidget {
  const CandidatesAnalysisCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.grey200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Candidates Hiring Analysis',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                const Icon(Icons.download_rounded, color: AppColors.grey600, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 60,
                dataRowMaxHeight: 60,
                columnSpacing: 20,
                horizontalMargin: 0,
                columns: const [
                  DataColumn(label: Text('Department')),
                  DataColumn(label: Center(child: Text('Applicants'))),
                  DataColumn(label: Center(child: Text('Shortlisted'))),
                  DataColumn(label: Center(child: Text('Interviewed'))),
                  DataColumn(label: Center(child: Text('Offered'))),
                  DataColumn(label: Center(child: Text('Hired'))),
                ],
                rows: [
                  _buildRow('Marketing', 'Product Manager', '14', '04', null, null, null),
                  _buildRow('Data Analyst', 'Jr Data Analyst', '16', '12', null, null, null),
                  _buildRow('Project Coord', 'Jr Level', '24', '06', null, null, null),
                  _buildRow('Design Lead', 'UI Designer', '12', '08', '06', '05', null),
                  _buildRow('Project Mgr', 'Senior Manager', '22', '20', '16', '12', '04'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildRow(String dept, String role, String c1, String c2, String? c3, String? c4, String? c5) {
    return DataRow(
      cells: [
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dept, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
              Text(role, style: GoogleFonts.poppins(color: AppColors.grey500, fontSize: 10)),
            ],
          ),
        ),
        DataCell(_buildPill(c1, Colors.deepOrange)),
        DataCell(_buildPill(c2, const Color(0xFF004D40))), // Dark Green/Teal
        DataCell(c3 != null ? _buildPill(c3, Colors.black) : _buildEmptyPill()),
        DataCell(c4 != null ? _buildPill(c4, Colors.blue) : _buildEmptyPill()),
        DataCell(c5 != null ? _buildPill(c5, Colors.green) : _buildEmptyPill()),
      ],
    );
  }

  Widget _buildPill(String text, Color color) {
    return Container(
      width: 40,
      padding: const EdgeInsets.symmetric(vertical: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyPill() {
    return Container(
      width: 40,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
