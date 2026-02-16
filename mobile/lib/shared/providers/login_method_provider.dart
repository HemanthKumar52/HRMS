import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/api_client.dart';

/// Enum representing the method used to login
enum LoginMethod {
  biometric,  // Fingerprint or device biometric
  phone,      // Phone/OTP login
  faceId,     // Face ID login
  password,   // Regular password login
}

/// Extension to get color and display name for each login method
extension LoginMethodExtension on LoginMethod {
  String get displayName {
    switch (this) {
      case LoginMethod.biometric:
        return 'Biometric';
      case LoginMethod.phone:
        return 'Phone';
      case LoginMethod.faceId:
        return 'Face ID';
      case LoginMethod.password:
        return 'Password';
    }
  }

  String get storageKey => 'login_method';
}

class LoginMethodNotifier extends StateNotifier<LoginMethod> {
  final FlutterSecureStorage _storage;
  static const String _loginMethodKey = 'login_method';

  LoginMethodNotifier(this._storage) : super(LoginMethod.password) {
    _loadLoginMethod();
  }

  Future<void> _loadLoginMethod() async {
    try {
      final stored = await _storage.read(key: _loginMethodKey);
      if (stored != null) {
        state = LoginMethod.values.firstWhere(
          (m) => m.name == stored,
          orElse: () => LoginMethod.password,
        );
      }
    } catch (e) {
      // Default to password if error
      state = LoginMethod.password;
    }
  }

  Future<void> setLoginMethod(LoginMethod method) async {
    state = method;
    await _storage.write(key: _loginMethodKey, value: method.name);
  }

  Future<void> clear() async {
    state = LoginMethod.password;
    await _storage.delete(key: _loginMethodKey);
  }
}

final loginMethodProvider =
    StateNotifierProvider<LoginMethodNotifier, LoginMethod>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return LoginMethodNotifier(storage);
});
