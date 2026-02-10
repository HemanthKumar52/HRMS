import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';

class AssetListTable extends StatelessWidget {
  const AssetListTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.grey200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Asset List', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                // Filter dropdown placeholder
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 4),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.grey300), borderRadius: BorderRadius.circular(4)),
                  child: Row(
                    children: [
                      Text('All Status', style: GoogleFonts.poppins(fontSize: 10)),
                      const Icon(Icons.arrow_drop_down, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 50,
              dataRowMaxHeight: 50,
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('Asset ID')),
                DataColumn(label: Text('Asset Name')),
                DataColumn(label: Text('Assigned To')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Action')),
              ],
              rows: [
                _buildRow('AST-001', 'Dell XPS 15', 'Sarah Johnson', 'In Use', Colors.green),
                _buildRow('AST-002', 'HP EliteBook', 'David Lee', 'Active', Colors.green),
                _buildRow('AST-003', 'MacBook Pro', 'Emily Wilson', 'In Use', Colors.green),
                _buildRow('AST-004', 'iPad Pro', 'Unassigned', 'Available', Colors.purple),
                _buildRow('AST-005', 'Samsung Monitor', 'Ashley Green', 'Active', Colors.green),
                _buildRow('AST-006', 'Logitech Mouse', 'Andrew Brown', 'Under Repair', Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildRow(String id, String name, String user, String status, Color statusColor) {
    return DataRow(
      cells: [
        DataCell(Text(id, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500))),
        DataCell(Text(name, style: GoogleFonts.poppins(fontSize: 12))),
        DataCell(Row(
          children: [
            CircleAvatar(radius: 10, backgroundColor: AppColors.primary, child: Text(user[0], style: const TextStyle(fontSize: 8, color: Colors.white))),
            const SizedBox(width: 8),
            Text(user, style: GoogleFonts.poppins(fontSize: 12)),
          ],
        )),
        DataCell(
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
             decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
             child: Text(status, style: GoogleFonts.poppins(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
          ),
        ),
        DataCell(
          Row(
            children: [
              IconButton(icon: const Icon(Icons.edit, size: 16, color: AppColors.grey500), onPressed: () {}),
              IconButton(icon: const Icon(Icons.delete, size: 16, color: AppColors.grey500), onPressed: () {}),
            ],
          ),
        ),
      ],
    );
  }
}
