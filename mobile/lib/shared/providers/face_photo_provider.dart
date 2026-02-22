import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stores the current session's face verification photo path.
/// Set on clock-in, cleared on clock-out.
final facePhotoProvider = StateProvider<String?>((ref) => null);

/// Whether the current session has been face-verified
final isFaceVerifiedProvider = Provider<bool>((ref) {
  return ref.watch(facePhotoProvider) != null;
});
