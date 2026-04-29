import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/storage/session_storage.dart';
import '../../../data/auth/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SessionStorage _sessionStorage = SessionStorage();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _userData;

  AuthProvider() {
    _syncUserDataFromSession();
  }

  Future<void> _syncUserDataFromSession() async {
    _userData = await _sessionStorage.getUserData();
  }

  bool get isAuthenticated => _isAuthenticated;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get needsPasswordChange => _userData?['needToChangePw'] ?? false;

  Future<void> checkAuthStatus() async {
    final result = await _apiService.getCurrentUser();
    if (result['success'] == true) {
      _isAuthenticated = true;
      _syncUserDataFromSession();
      notifyListeners();
    } else {
      await logout();
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
        _syncUserDataFromSession();
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
      final result = await _apiService.changePassword(oldPassword, newPassword);

      if (result['success'] == true) {
        final updatedUserData = Map<String, dynamic>.from(_userData ?? {});
        updatedUserData['needToChangePw'] = false;

        await _sessionStorage.saveUserData(updatedUserData);
        _userData = updatedUserData;

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

      final activeToken = await _sessionStorage.getToken() ?? '';
      return await _apiService.adminSetPassword(
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
    await _apiService.logout();
    _isAuthenticated = false;
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

      final success = await _apiService.toggleUserActiveStatus(
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
