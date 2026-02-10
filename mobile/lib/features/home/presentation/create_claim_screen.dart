import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/claim_provider.dart';

class CreateClaimScreen extends ConsumerStatefulWidget {
  const CreateClaimScreen({super.key});

  @override
  ConsumerState<CreateClaimScreen> createState() => _CreateClaimScreenState();
}

class _CreateClaimScreenState extends ConsumerState<CreateClaimScreen> {
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  String _claimType = 'Travel';
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(createClaimProvider, (previous, next) {
      if (next.hasError) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${next.error}'), backgroundColor: Colors.red));
      }
    });

    final isLoading = ref.watch(createClaimProvider).isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text('Submit Claim', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _claimType,
                      decoration: const InputDecoration(labelText: 'Claim Type', border: OutlineInputBorder()),
                      items: ['Travel', 'Medical', 'Food', 'Stationery']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.poppins()))).toList(),
                      onChanged: (val) => setState(() => _claimType = val!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder()),
                      style: GoogleFonts.poppins(),
                      validator: (v) => (v == null || v.isEmpty) ? 'Amount is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Description / Reason', border: OutlineInputBorder()),
                      style: GoogleFonts.poppins(),
                      validator: (v) => (v == null || v.isEmpty) ? 'Description is required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.attach_file, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('Attach Bill/Receipt (Optional)', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w500)),
                      ],
                    )
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: isLoading ? null : () async {
                    if (_formKey.currentState?.validate() ?? false) {
                       final result = await ref.read(createClaimProvider.notifier).createClaim({
                         'type': _claimType.toUpperCase(),
                         'amount': _amountController.text.trim(),
                         'description': _reasonController.text.trim(),
                       });
                       
                       if (context.mounted && !ref.read(createClaimProvider).hasError) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Claim Submitted Successfully')));
                          context.pop();
                       }
                    }
                  },
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  child: isLoading 
                     ? const CircularProgressIndicator(color: Colors.white)
                     : Text('Submit Claim', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
