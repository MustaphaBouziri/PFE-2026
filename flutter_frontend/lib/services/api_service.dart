  import 'dart:convert';
  import 'package:http/http.dart' as http;
  import 'package:shared_preferences/shared_preferences.dart';

  class ApiService {
    // Local on‑prem base URL (BC210)
    static const String baseUrl =
        'http://localhost:7048/BC210/api/yourcompany/mes/v1.0';

    // Your company id (from /api/v2.0/companies)
    static const String companyId = '9e31f41c-e73a-ed11-bbab-000d3a21ffa5';

    // Endpoints
    static const String authActionsEndpoint =
        '$baseUrl/companies($companyId)/authActions';

    // Shared headers
    Map<String, String> _getHeaders({String? token}) {
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      return headers;
    }

    // Login
    Future<Map<String, dynamic>> login(String userId, String password, String deviceId) async {
      try {
        final response = await http.post(
          Uri.parse('$authActionsEndpoint/Login'),
          headers: _getHeaders(),
          body: jsonEncode({
            'userId': userId,
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
        return {
          'error': 'Connection failed',
          'message': e.toString(),
        };
      }
    }

    // Get current user info
    Future<Map<String, dynamic>> getCurrentUser(String token) async {
      try {
        final response = await http.post(
          Uri.parse('$authActionsEndpoint/Me'),
          headers: _getHeaders(token: token),
          body: jsonEncode({'token': token}),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final result = jsonDecode(data['value'] ?? '{}');
          return result;
        } else {
          return {
            'error': 'Unauthorized',
            'message': 'Failed to get user info',
          };
        }
      } catch (e) {
        return {
          'error': 'Connection failed',
          'message': e.toString(),
        };
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
          Uri.parse('$authActionsEndpoint/ChangePassword'),
          headers: _getHeaders(token: token),
          body: jsonEncode({
            'token': token,
            'oldPassword': oldPassword,
            'newPassword': newPassword,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final result = jsonDecode(data['value'] ?? '{}');
          return result;
        } else {
          return {
            'error': 'Failed',
            'message': 'Password change failed',
          };
        }
      } catch (e) {
        return {
          'error': 'Connection failed',
          'message': e.toString(),
        };
      }
    }

    // Logout
    Future<Map<String, dynamic>> logout(String token) async {
      try {
        final response = await http.post(
          Uri.parse('$authActionsEndpoint/Logout'),
          headers: _getHeaders(token: token),
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
