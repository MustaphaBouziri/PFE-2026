import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app_constants.dart';

class ApiService {
  // Shared headers

  Future<bool> AdminSetPassword({
    required String token,
    required String userId,
    required String newPassword,
  }) async {
    final body = jsonEncode({
      'token': token,
      'userId': userId,
      'newPassword': newPassword,
    });
    final response = await http.post(
      Uri.parse(AppConstants.adminSetPasswordUrl),
      headers: AppConstants.jsonHeaders,
      body: body,
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
        'Failed to generate password: ${response.statusCode} ${response.body}',
      );
    }
  }

  // Login
  Future<Map<String, dynamic>> login(
    String authId,
    String password,
    String deviceId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.loginUrl),
        headers: AppConstants.jsonHeaders,
        body: jsonEncode({
          'userId': authId,
          'password': password,
          'deviceId': deviceId,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final result = jsonDecode(data['value'] ?? '{}');

        if (result['success'] == true) {
          await _saveToken(result['token']);
          await _saveUserData(result);
        }
        return result;
      } else {
        return {
          'error': 'Request failed',
          'message': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {'error': 'Connection failed', 'message': e.toString()};
    }
  }

  // Get current user info
  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.meUrl),
        headers: AppConstants.jsonHeaders,
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = jsonDecode(data['value'] ?? '{}');
        return result;
      } else {
        return {'error': 'Unauthorized', 'message': 'Failed to get user info'};
      }
    } catch (e) {
      return {'error': 'Connection failed', 'message': e.toString()};
    }
  }

  // Change password
  Future<Map<String, dynamic>> changePassword(
    String token,
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.changePasswordUrl),
        headers: AppConstants.jsonHeaders,
        body: jsonEncode({
          'token': token,
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final result = jsonDecode(data['value'] ?? '{}');
        return result;
      } else {
        // Parse BC's actual error response instead of swallowing it
        try {
          final data = jsonDecode(response.body);
          return {
            'success': false,
            'error': 'Failed',
            'message':
                data['error']?['message'] ?? 'HTTP ${response.statusCode}',
          };
        } catch (_) {
          return {
            'success': false,
            'error': 'Failed',
            'message': 'HTTP ${response.statusCode}: ${response.body}',
          };
        }
      }
    } catch (e) {
      return {'error': 'Connection failed', 'message': e.toString()};
    }
  }

  // Logout
  Future<Map<String, dynamic>> logout(String token) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.logoutUrl),
        headers: AppConstants.jsonHeaders,
        body: jsonEncode({'token': token}),
      );

      await _clearStorage();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = jsonDecode(data['value'] ?? '{}');
        return result;
      } else {
        return {'success': true};
      }
    } catch (e) {
      await _clearStorage();
      return {'success': true};
    }
  }

  // Local storage helpers
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user_data');
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }
}
