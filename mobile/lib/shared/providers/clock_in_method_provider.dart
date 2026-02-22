import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ClockInMethod { biometric, app }

class ClockInMethodNotifier extends StateNotifier<ClockInMethod?> {
  ClockInMethodNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('clock_in_method');
    if (value == 'biometric') {
      state = ClockInMethod.biometric;
    } else if (value == 'app') {
      state = ClockInMethod.app;
    }
  }

  Future<void> setMethod(ClockInMethod method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'clock_in_method', method == ClockInMethod.biometric ? 'biometric' : 'app');
    state = method;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('clock_in_method');
    state = null;
  }

  String get methodLabel {
    switch (state) {
      case ClockInMethod.biometric:
        return 'Biometric';
      case ClockInMethod.app:
        return 'App';
      default:
        return 'None';
    }
  }
}

final clockInMethodProvider =
    StateNotifierProvider<ClockInMethodNotifier, ClockInMethod?>((ref) {
  return ClockInMethodNotifier();
});
