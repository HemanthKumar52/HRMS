import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/ticket_provider.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _department = 'IT Support';
  String _priority = 'Medium';
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (_formKey.currentState?.validate() ?? false) {
      // FocusScope.of(context).unfocus(); // Close keyboard
      
      await ref.read(createTicketProvider.notifier).createTicket({
        'subject': _subjectController.text.trim(),
        'description': _descriptionController.text.trim(),
        'department': _department,
        'priority': _priority,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(createTicketProvider, (previous, next) {
      next.when(
        data: (_) {
          // Success handled in createTicket, usually null on success?
          // Since default state is data(null), need to distinguish?
          // Wait, state starts as data(null).
          // If action completes, it sets data(null) AGAIN.
          // Listener fires?
          // Usually better to assume success if no error after loading.
          // But here, I'll rely on the Future to complete. 
          // Actually, let's keep it simple: handle success inside _submitTicket if no exception thrown.
          // But exception is caught in notifier.
          // Notifier sets state to data(null) on success.
          // Or I check `next.isLoading` vs `previous.isLoading`.
        },
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        ),
        loading: () {},
      );
    });

    final state = ref.watch(createTicketProvider);
    final isLoading = state.isLoading;

    // Handle Success Side Effect here if state just changed to Data from Loading?
    // It's tricky with Riverpod async.
    // Let's rely on checking `!state.hasError` after await in _submitTicket?
    // But notifier catches error.
    // I will modify notifier to rethrow? Or return success status.
    // Simpler: Use listener. If success, pop.
    // But initial state is data(null).
    // I'll add logic: if previous was loading and next is data -> success.
    
    // Actually, I'll just use the button interaction.

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text('Raise Ticket', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black)),
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
                      value: _department,
                      decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
                      items: ['IT Support', 'HR', 'Finance', 'Facility']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.poppins()))).toList(),
                      onChanged: (val) => setState(() => _department = val!),
                    ),
                     const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                      items: ['Low', 'Medium', 'High', 'Critical']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.poppins()))).toList(),
                      onChanged: (val) => setState(() => _priority = val!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
                      style: GoogleFonts.poppins(),
                      validator: (v) => (v == null || v.isEmpty) ? 'Subject is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Detailed Description', border: OutlineInputBorder()),
                      style: GoogleFonts.poppins(),
                      validator: (v) => (v == null || v.isEmpty) ? 'Description is required' : null,
                    ),
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
                      await ref.read(createTicketProvider.notifier).createTicket({
                        'subject': _subjectController.text.trim(),
                        'description': _descriptionController.text.trim(),
                        'department': _department,
                        'priority': _priority,
                      });
                      
                      // Check result
                      if (context.mounted && !ref.read(createTicketProvider).hasError) {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket Raised Successfully')));
                         context.pop();
                      }
                    }
                  },
                  style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                  child: isLoading 
                     ? const CircularProgressIndicator(color: Colors.white) 
                     : Text('Raise Ticket', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
