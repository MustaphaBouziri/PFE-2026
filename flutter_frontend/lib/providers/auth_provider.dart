import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _userData;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userData => _userData;
  bool get needsPasswordChange => _userData?['needToChangePw'] ?? false;

  // Check if user is already logged in
  Future<void> checkAuthStatus() async {
    final token = await _apiService.getToken();
    if (token != null) {
      final result = await _apiService.getCurrentUser(token);
      if (result['success'] == true) {
        _isAuthenticated = true;
        _userData = result;
        notifyListeners();
      } else {
        await logout();
      }
    }
  }

  // Login
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
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Change password
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _apiService.getToken();
      if (token == null) {
        _errorMessage = 'Not authenticated';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final result = await _apiService.changePassword(token, oldPassword, newPassword);

      if (result['success'] == true) {
        // Update user data
        if (_userData != null) {
          _userData!['needToChangePw'] = false;
        }
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Password change failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    final token = await _apiService.getToken();
    if (token != null) {
      await _apiService.logout(token);
    }
    
    _isAuthenticated = false;
    _userData = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Get device ID (simplified - in production, use device_info_plus package)
  Future<String> _getDeviceId() async {
    // For production, install device_info_plus package and get actual device ID
    return 'flutter-device-${DateTime.now().millisecondsSinceEpoch}';
  }
}