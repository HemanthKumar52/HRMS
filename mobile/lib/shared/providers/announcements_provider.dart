import 'package:flutter_riverpod/flutter_riverpod.dart';

class Announcement {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });

  Announcement copyWith({bool? isRead}) {
    return Announcement(
      id: id,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

class AnnouncementsNotifier extends StateNotifier<List<Announcement>> {
  AnnouncementsNotifier()
      : super([
          Announcement(
            id: '1',
            title: 'Updated Leave Policy',
            body:
                'The new leave policy is effective from March 1st. Please review the updated terms in the HR portal.',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          Announcement(
            id: '2',
            title: 'Office Maintenance - Feb 22',
            body:
                'The office will undergo scheduled maintenance on Feb 22nd. Please plan to work remotely.',
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          Announcement(
            id: '3',
            title: 'Annual Performance Review',
            body:
                'Performance review cycle has started. Please complete your self-assessment by Feb 28th.',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ]);

  void markAsRead(String id) {
    state = state.map((a) => a.id == id ? a.copyWith(isRead: true) : a).toList();
  }

  void ignore(String id) {
    state = state.where((a) => a.id != id).toList();
  }
}

final announcementsProvider =
    StateNotifierProvider<AnnouncementsNotifier, List<Announcement>>((ref) {
  return AnnouncementsNotifier();
});

final unreadAnnouncementsProvider = Provider<List<Announcement>>((ref) {
  return ref.watch(announcementsProvider).where((a) => !a.isRead).toList();
});
