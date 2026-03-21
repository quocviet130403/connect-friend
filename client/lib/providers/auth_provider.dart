import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _user;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _api.isLoggedIn;

  Future<void> init() async {
    await _api.loadTokens();
    if (_api.isLoggedIn) {
      try {
        final res = await _api.getMyProfile();
        if (res['success'] == true) {
          _user = res['data'] as Map<String, dynamic>?;
        }
      } catch (e) {
        // Token may be expired or network error
        debugPrint('[AuthProvider] init error: $e');
        await _api.clearTokens();
      }
    }
    notifyListeners();
  }

  Future<bool> register(String phone, String password, String deviceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.register(phone, password, deviceId);
      _user = res['data']?['user'] as Map<String, dynamic>?;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[AuthProvider] register error: $e');
      _error = 'Lỗi kết nối mạng. Vui lòng thử lại.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.login(phone, password);
      _user = res['data']?['user'] as Map<String, dynamic>?;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[AuthProvider] login error: $e');
      _error = 'Lỗi kết nối. Vui lòng kiểm tra mạng và thử lại.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _api.logout();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
