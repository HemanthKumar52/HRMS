import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/responsive.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/finance_provider.dart';

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Responsive.init(context);
    final payslipsAsync = ref.watch(payslipListProvider);
    final selectedPeriod = ref.watch(selectedPayslipPeriodProvider);
    final formatter = NumberFormat('#,##,###');

    return SafeScaffold(
      appBar: AdaptiveAppBar(title: 'Finance'),
      backgroundColor: context.scaffoldBg,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(payslipListProvider);
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(Responsive.horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Salary Summary Card with glass effect
              ClipRRect(
                borderRadius: BorderRadius.circular(Responsive.cardRadius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(Responsive.horizontalPadding),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.circular(Responsive.cardRadius),
                      border: Border.all(
                        color: Colors.white.withValues(alpha:0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Earnings',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: Responsive.sp(12),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                payslipsAsync.when(
                                  data: (payslips) => Text(
                                    '₹${formatter.format(payslips.isNotEmpty ? payslips.first.grossPay : 0)}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: Responsive.sp(26),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  loading: () => Text(
                                    'Loading...',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: Responsive.sp(22),
                                    ),
                                  ),
                                  error: (_, __) => Text(
                                    'Error',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: Responsive.sp(22),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha:0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.account_balance_wallet,
                                color: Colors.white,
                                size: Responsive.sp(28),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                            height:
                                Responsive.value(mobile: 20.0, tablet: 28.0)),
                        payslipsAsync.when(
                          data: (payslips) {
                            final latest = payslips.isNotEmpty
                                ? payslips.first
                                : null;
                            return Row(
                              children: [
                                _buildSalaryStat(
                                  'Gross Salary',
                                  '₹${formatter.format(latest?.grossPay ?? 0)}/mo',
                                ),
                                SizedBox(
                                    width: Responsive.value(
                                        mobile: 20.0, tablet: 28.0)),
                                _buildSalaryStat(
                                  'Net Pay',
                                  '₹${formatter.format(latest?.netPay ?? 0)}/mo',
                                ),
                                SizedBox(
                                    width: Responsive.value(
                                        mobile: 20.0, tablet: 28.0)),
                                _buildSalaryStat(
                                  'Deductions',
                                  '₹${formatter.format(latest?.totalDeductions ?? 0)}/mo',
                                ),
                              ],
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn().slideY(begin: 0.1),

              SizedBox(height: Responsive.value(mobile: 24.0, tablet: 32.0)),

              // Download Payslip Section
              Text(
                'Download Payslip',
                style: GoogleFonts.poppins(
                  fontSize: Responsive.sp(18),
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ).animate().fadeIn(delay: 100.ms),
              SizedBox(height: Responsive.value(mobile: 12.0, tablet: 16.0)),
              GlassCard(
                blur: 12,
                opacity: 0.15,
                borderRadius: Responsive.cardRadius,
                padding: EdgeInsets.all(Responsive.horizontalPadding),
                child: Column(
                  children: [
                    // Period Dropdown
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: context.borderColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedPeriod,
                          isExpanded: true,
                          icon: Icon(Icons.keyboard_arrow_down,
                              color: context.textSecondary),
                          style: GoogleFonts.poppins(
                            fontSize: Responsive.sp(14),
                            color: context.textPrimary,
                          ),
                          items: const [
                            'Last 1 Month',
                            'Last 3 Months',
                            'Last 6 Months',
                            'Last 1 Year',
                            'Last 2 Years',
                          ]
                              .map((period) => DropdownMenuItem(
                                    value: period,
                                    child: Text(period),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              ref
                                  .read(
                                      selectedPayslipPeriodProvider.notifier)
                                  .state = value;
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                        height: Responsive.value(mobile: 12.0, tablet: 16.0)),
                    // Download Button
                    SizedBox(
                      width: double.infinity,
                      height: Responsive.buttonHeight,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.showSnackBar(
                              'Downloading payslip for $selectedPeriod...');
                        },
                        icon: Icon(Icons.picture_as_pdf,
                            size: Responsive.sp(20), color: Colors.white),
                        label: Text(
                          'Download Payslip PDF',
                          style: GoogleFonts.poppins(
                            fontSize: Responsive.sp(15),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(Responsive.cardRadius),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

              SizedBox(height: Responsive.value(mobile: 24.0, tablet: 32.0)),

              // Recent Payslips
              Text(
                'Recent Payslips',
                style: GoogleFonts.poppins(
                  fontSize: Responsive.sp(18),
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ).animate().fadeIn(delay: 300.ms),
              SizedBox(height: Responsive.value(mobile: 12.0, tablet: 16.0)),

              payslipsAsync.when(
                data: (payslips) => Column(
                  children: payslips.asMap().entries.map((entry) {
                    final index = entry.key;
                    final payslip = entry.value;
                    return _buildPayslipCard(context, payslip, formatter)
                        .animate()
                        .fadeIn(delay: (400 + index * 80).ms)
                        .slideX(begin: 0.1);
                  }).toList(),
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Center(
                  child: Text('Error: $e'),
                ),
              ),

              // Bottom padding for glass nav bar
              SizedBox(height: Responsive.value(mobile: 80.0, tablet: 100.0)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalaryStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white54,
            fontSize: Responsive.sp(10),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: Responsive.sp(12),
          ),
        ),
      ],
    );
  }

  Widget _buildPayslipCard(
      BuildContext context, PayslipModel payslip, NumberFormat formatter) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        blur: 10,
        opacity: 0.15,
        borderRadius: Responsive.cardRadius,
        padding: EdgeInsets.all(Responsive.horizontalPadding),
        child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.description_outlined,
              color: AppColors.primary,
              size: Responsive.sp(24),
            ),
          ),
          SizedBox(width: Responsive.value(mobile: 12.0, tablet: 16.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${payslip.month} ${payslip.year}',
                  style: GoogleFonts.poppins(
                    fontSize: Responsive.sp(14),
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Net: ₹${formatter.format(payslip.netPay)}',
                  style: GoogleFonts.poppins(
                    fontSize: Responsive.sp(12),
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Gross: ₹${formatter.format(payslip.grossPay)}',
                  style: GoogleFonts.poppins(
                    fontSize: Responsive.sp(11),
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              context.showSnackBar(
                  'Downloading ${payslip.month} ${payslip.year} payslip...');
            },
            icon: Icon(
              Icons.download_rounded,
              color: AppColors.primary,
              size: Responsive.sp(22),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
