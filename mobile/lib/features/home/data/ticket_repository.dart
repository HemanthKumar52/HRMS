import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';

class TicketRepository {
  final Dio _dio;

  TicketRepository(this._dio);

  Future<void> createTicket(Map<String, dynamic> data) async {
    await _dio.post(ApiConstants.tickets, data: data);
  }
}

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TicketRepository(dio);
});
