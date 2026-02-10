import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/user_model.dart';
import '../data/directory_repository.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final usersProvider =
    FutureProvider.autoDispose.family<List<UserModel>, String>((ref, search) async {
  final repository = ref.watch(directoryRepositoryProvider);
  return repository.getUsers(search: search.isNotEmpty ? search : null);
});

final userProfileProvider =
    FutureProvider.autoDispose.family<UserModel, String>((ref, userId) async {
  final repository = ref.watch(directoryRepositoryProvider);
  return repository.getUserProfile(userId);
});

final userTeamProvider =
    FutureProvider.autoDispose.family<List<UserModel>, String>((ref, userId) async {
  final repository = ref.watch(directoryRepositoryProvider);
  return repository.getUserTeam(userId);
});
