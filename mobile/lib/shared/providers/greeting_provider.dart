import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory flag to track if greeting has been shown this session.
/// Resets on app restart.
final greetingShownProvider = StateProvider<bool>((ref) => false);
