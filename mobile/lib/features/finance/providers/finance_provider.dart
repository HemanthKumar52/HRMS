import 'package:flutter_riverpod/flutter_riverpod.dart';

class PayslipModel {
  final String month;
  final String year;
  final double grossPay;
  final double netPay;
  final double totalDeductions;
  final double basicSalary;
  final double hra;
  final double otherAllowances;
  final double providentFund;
  final double professionalTax;
  final double incomeTax;

  const PayslipModel({
    required this.month,
    required this.year,
    required this.grossPay,
    required this.netPay,
    required this.totalDeductions,
    required this.basicSalary,
    required this.hra,
    required this.otherAllowances,
    required this.providentFund,
    required this.professionalTax,
    required this.incomeTax,
  });
}

final selectedPayslipPeriodProvider =
    StateProvider<String>((ref) => 'Last 1 Month');

final payslipListProvider =
    FutureProvider.autoDispose<List<PayslipModel>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 600));
  return const [
    PayslipModel(
      month: 'January',
      year: '2026',
      grossPay: 85000,
      netPay: 68500,
      totalDeductions: 16500,
      basicSalary: 42500,
      hra: 17000,
      otherAllowances: 25500,
      providentFund: 5100,
      professionalTax: 200,
      incomeTax: 11200,
    ),
    PayslipModel(
      month: 'December',
      year: '2025',
      grossPay: 85000,
      netPay: 68500,
      totalDeductions: 16500,
      basicSalary: 42500,
      hra: 17000,
      otherAllowances: 25500,
      providentFund: 5100,
      professionalTax: 200,
      incomeTax: 11200,
    ),
    PayslipModel(
      month: 'November',
      year: '2025',
      grossPay: 82500,
      netPay: 66200,
      totalDeductions: 16300,
      basicSalary: 41250,
      hra: 16500,
      otherAllowances: 24750,
      providentFund: 4950,
      professionalTax: 200,
      incomeTax: 11150,
    ),
    PayslipModel(
      month: 'October',
      year: '2025',
      grossPay: 82500,
      netPay: 66200,
      totalDeductions: 16300,
      basicSalary: 41250,
      hra: 16500,
      otherAllowances: 24750,
      providentFund: 4950,
      professionalTax: 200,
      incomeTax: 11150,
    ),
    PayslipModel(
      month: 'September',
      year: '2025',
      grossPay: 82500,
      netPay: 66200,
      totalDeductions: 16300,
      basicSalary: 41250,
      hra: 16500,
      otherAllowances: 24750,
      providentFund: 4950,
      professionalTax: 200,
      incomeTax: 11150,
    ),
    PayslipModel(
      month: 'August',
      year: '2025',
      grossPay: 80000,
      netPay: 64500,
      totalDeductions: 15500,
      basicSalary: 40000,
      hra: 16000,
      otherAllowances: 24000,
      providentFund: 4800,
      professionalTax: 200,
      incomeTax: 10500,
    ),
  ];
});
