import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stores the current session's face verification photo path.
/// Set on clock-in, cleared on clock-out.
final facePhotoProvider = StateProvider<String?>((ref) => null);

/// Stores the user's DB face photo file path (loaded on login, persists across sessions).
/// This is the user's original registered face photo used as their profile picture.
final profilePhotoProvider = StateProvider<String?>((ref) => null);

/// Whether the current session has been face-verified
final isFaceVerifiedProvider = Provider<bool>((ref) {
  return ref.watch(facePhotoProvider) != null;
});
