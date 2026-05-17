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
  bool _pendingBadge = false;
  String? _pendingToken;
  Map<String, dynamic>? _pendingUserData;
  String? _pendingUserId; // internal userId for VerifyBadge call

  bool get pendingBadge => _pendingBadge;

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
      final deviceId =
          'flutter-device-${DateTime.now().millisecondsSinceEpoch}';
      final result = await _apiService.login(userId, password, deviceId);

      if (result['success'] != true) {
        _errorMessage = result['message'] as String? ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final twoFAEnabled = result['twoFAEnabled'] == true;

      if (twoFAEnabled) {
        // Hold everything in memory — do NOT persist until badge passes
        _pendingBadge = true;
        _pendingToken = result['token'] as String?;
        _pendingUserData = result;
        _pendingUserId = result['userId'] as String?;
        _isLoading = false;
        notifyListeners();
        return true; // login() returns true = credentials OK; caller checks pendingBadge
      }

      // No 2FA — persist and authenticate immediately (existing behaviour)
      await _sessionStorage.saveToken(result['token'] as String);
      await _sessionStorage.saveUserData(result);
      _isAuthenticated = true;
      await _syncUserDataFromSession();
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
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

  /// Called by the badge scan dialog with the raw scanned value.
  /// On success: persists token/userData and marks authenticated.
  /// On failure: sets errorMessage; caller shows it in the dialog.
  Future<bool> verifyBadge(String scannedSecret) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.verifyBadge(
        userId: _pendingUserId ?? '',
        scannedSecret: scannedSecret,
      );

      if (result['success'] == true) {
        // Persist what we were holding in memory
        await _sessionStorage.saveToken(_pendingToken!);
        await _sessionStorage.saveUserData(_pendingUserData!);
        _isAuthenticated = true;
        _pendingBadge = false;
        _pendingToken = null;
        _pendingUserData = null;
        _pendingUserId = null;
        await _syncUserDataFromSession();
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage =
          result['message'] as String? ?? 'Badge verification failed';
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

  /// Cancel badge scan — clear pending state and go back to login form.
  void cancelBadgeScan() {
    _pendingBadge = false;
    _pendingToken = null;
    _pendingUserData = null;
    _pendingUserId = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Admin: get badge secret for a user (to render QR in the dialog).
  Future<Map<String, dynamic>> getBadgeSecret(String targetUserId) async {
    return await _apiService.getBadgeSecret(targetUserId: targetUserId);
  }

  /// Admin: regenerate badge secret (returns new secret to re-render QR).
  Future<Map<String, dynamic>> regenerateBadge(String targetUserId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _apiService.regenerateBadge(
        targetUserId: targetUserId,
      );
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }
}
