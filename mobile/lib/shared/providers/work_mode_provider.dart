import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Work Mode State
final workModeProvider = StateNotifierProvider<WorkModeNotifier, String?>((ref) {
  return WorkModeNotifier();
});

class WorkModeNotifier extends StateNotifier<String?> {
  WorkModeNotifier() : super(null) {
    _loadWorkMode();
  }

  Future<void> _loadWorkMode() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('work_mode');
  }

  Future<void> setWorkMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('work_mode', mode);
    state = mode;
  }

  Future<void> clearWorkMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('work_mode');
    state = null;
  }

  // Helper methods
  bool get isOfficeMode => state == 'OFFICE';
  bool get isRemoteMode => state == 'REMOTE';
  bool get isOnDutyMode => state == 'ON_DUTY';
  
  // Office mode requires ALL THREE: Biometric AND Geofence AND Clock In/Out
  bool get requiresGeofence => isOfficeMode;
  bool get requiresBiometric => isOfficeMode;
  
  // ON_DUTY mode captures GPS location (lat/long + address) on both Clock In and Clock Out
  bool get requiresLocationTracking => isOnDutyMode;
}
