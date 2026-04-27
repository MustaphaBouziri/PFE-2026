import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../../data/auth/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _userData;

  // Cached in memory after login so service layers can read it without async
  String? _cachedToken;

  bool get isAuthenticated => _isAuthenticated;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Map<String, dynamic>? get userData => _userData;

  bool get needsPasswordChange => _userData?['needToChangePw'] ?? false;

  /// Synchronous token access for service layers that already have the provider.
  /// Falls back to the dev token constant when no real session exists.
  String get token => _cachedToken ?? '';

  Future<void> checkAuthStatus() async {
    final storedToken = await _apiService.getToken();
    if (storedToken != null) {
      final result = await _apiService.getCurrentUser(storedToken);
      if (result['success'] == true) {
        _isAuthenticated = true;
        _userData = result;
        _cachedToken = storedToken;
        notifyListeners();
      } else {
        await logout();
      }
    }
  }

  Future<bool> login(String userId, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final deviceId = await _getDeviceId();
      final result = await _apiService.login(userId, password, deviceId);

      if (result['success'] == true) {
        _isAuthenticated = true;
        _userData = result;
        _cachedToken = result['token'] as String?;
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = result['message'] as String? ?? 'Login failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final activeToken = await _apiService.getToken();
      if (activeToken == null) {
        _errorMessage = 'Not authenticated';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final result = await _apiService.changePassword(
        activeToken,
        oldPassword,
        newPassword,
      );

      if (result['success'] == true) {
        _userData?['needToChangePw'] = false;
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = result['message'] as String? ?? 'Password change failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> adminSetPassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final activeToken = await _apiService.getToken() ?? '';
      return await _apiService.adminSetPassword(
        token: activeToken,
        userId: userId,
        newPassword: newPassword,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final activeToken = await _apiService.getToken();
    if (activeToken != null) await _apiService.logout(activeToken);

    _isAuthenticated = false;
    _userData = null;
    _cachedToken = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Get device ID (simplified - in production, use device_info_plus package)
  Future<String> _getDeviceId() async {
    // For production, install device_info_plus package and get actual device ID
    return 'flutter-device-${DateTime.now().millisecondsSinceEpoch}';
  }

Uint8List? get profileImageBytes {
  final base64Str = _userData?['imageBase64']?.toString() ?? '';
  if (base64Str.isEmpty) return null;
  try {
    return base64Decode(base64Str);
  } catch (_) {
    return null;
  }
}

  //toggle use active status

  Future<bool> toggleUserActiveStatus(String userId, bool isActive) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      final String token = await _apiService.getToken() ?? '';

      final success = await _apiService.toggleUserActiveStatus(
        token: token,
        userId: userId,
        isActive: isActive,
      );
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
