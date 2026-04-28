import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app_constants.dart';
import '../../shared/http_client.dart';
import '../../shared/http_response_parser.dart';

class ApiService {

  // ── Auth endpoints ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(
    String authId,
    String password,
    String deviceId,
  ) async {
    try {
      final response = await HttpClient.post(AppConstants.loginUrl, {
        'userId': authId,
        'password': password,
        'deviceId': deviceId,
      });

      final result = HttpResponseParser.parseObject(response, label: 'login');

      if (result['success'] == true) {
        await _saveToken(result['token'] as String);
        await _saveUserData(result);
      }
      return result;
    } catch (e) {
      return {'error': 'Connection failed', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    try {
      final response = await HttpClient.post(AppConstants.meUrl, {
        'token': token,
      });

      final result = HttpResponseParser.parseObject(response, label: 'getCurrentUser');
      if (result['success'] == true) {
        await _saveUserData(result);
      }

      return result;
    } catch (e) {
      return {'error': 'Connection failed', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> changePassword(
    String token,
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final response = await HttpClient.post(AppConstants.changePasswordUrl, {
        'token': token,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });

      return HttpResponseParser.parseObject(response, label: 'changePassword');
    } catch (e) {
      return {'error': 'Connection failed', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> logout(String token) async {
    try {
      final response = await HttpClient.post(AppConstants.logoutUrl, {
        'token': token,
      });

      await _clearStorage();

      return HttpResponseParser.parseObject(response, label: 'logout');
    } catch (e) {
      await _clearStorage();
      return {'success': true};
    }
  }

  Future<bool> adminSetPassword({
    required String token,
    required String userId,
    required String newPassword,
  }) async {
    final response = await HttpClient.post(AppConstants.adminSetPasswordUrl, {
      'token': token,
      'userId': userId,
      'newPassword': newPassword,
    });

    if (response.statusCode == 200 || response.statusCode == 201) return true;
    throw Exception(
      'Failed to generate password: ${response.statusCode} ${response.body}',
    );
  }

  //toggle active / deactivate user
  Future<bool> toggleUserActiveStatus({
    required String token,
    required String userId,
    required bool isActive,
  }) async {
    final response = await HttpClient.post(
      AppConstants.toggleUserActiveStatus,
      {'token': token, 'userId': userId, 'isActive': isActive},
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
        'Failed to toggle user status: ${response.statusCode} ${response.body}',
      );
    }
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user_data');
    if (data != null) return jsonDecode(data) as Map<String, dynamic>;
    return null;
  }

  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }
}
