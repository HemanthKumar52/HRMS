import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ticket_repository.dart';

class CreateTicketNotifier extends StateNotifier<AsyncValue<void>> {
  final TicketRepository _repository;

  CreateTicketNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> createTicket(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createTicket(data);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final createTicketProvider = StateNotifierProvider.autoDispose<
    CreateTicketNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(ticketRepositoryProvider);
  return CreateTicketNotifier(repository);
});
