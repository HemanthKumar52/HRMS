import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/claim_repository.dart';

class CreateClaimNotifier extends StateNotifier<AsyncValue<void>> {
  final ClaimRepository _repository;

  CreateClaimNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> createClaim(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createClaim(data);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final createClaimProvider = StateNotifierProvider.autoDispose<
    CreateClaimNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(claimRepositoryProvider);
  return CreateClaimNotifier(repository);
});
