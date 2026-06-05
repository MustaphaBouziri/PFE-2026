import '../../../core/app_constants.dart';
import '../../../core/storage/session_storage.dart';
import '../../shared/http_client.dart';
import '../../shared/http_response_parser.dart';

/// Handles all authentication-related API calls.
///
/// Persistence (token + user data) is fully delegated to [SessionStorage]
/// so there is one canonical place for SharedPreferences keys.
class ApiService {
  final SessionStorage _storage;

  ApiService({SessionStorage? storage})
    : _storage = storage ?? SessionStorage();

  // ── Auth endpoints ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(
    String authId,
    String password,
    String deviceId,
  ) async {
    try {
      final response = await HttpClient.post(AppConstants.login, {
        'userId': authId,
        'password': password,
        'deviceId': deviceId,
      });

      final result = HttpResponseParser.parseObject(response, label: 'login');
      return result;
    } catch (e) {
      return {'error': 'Connection failed', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = _storage.getToken();
      final response = await HttpClient.post(AppConstants.me, {
        'token': token,
      });

      final result = HttpResponseParser.parseObject(
        response,
        label: 'getCurrentUser',
      );
      if (result['success'] == true) {
        await _storage.saveUserData(result);
        await _storage.saveToken(token??'');
      }
      return result;
    } catch (e) {
      return {'error': 'Connection failed', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final token = _storage.getToken();
      final response = await HttpClient.post(AppConstants.changePassword, {
        'token': token,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
      return HttpResponseParser.parseObject(response, label: 'changePassword');
    } catch (e) {
      return {'error': 'Connection failed', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      final token = _storage.getToken();
      final response = await HttpClient.post(AppConstants.logout, {
        'token': token,
      });
      await _storage.clear();
      return HttpResponseParser.parseObject(response, label: 'logout');
    } catch (e) {
      await _storage.clear();
      return {'success': true};
    }
  }

  Future<bool> adminSetPassword({
    required String userId,
    required String newPassword,
  }) async {
    final token = _storage.getToken();
    final response = await HttpClient.post(AppConstants.adminSetPassword, {
      'token': token,
      'userId': userId,
      'newPassword': newPassword,
    });
    return HttpResponseParser.parseSuccess(response, label: 'adminSetPassword');
  }

  Future<bool> toggleUserActiveStatus({
    required String userId,
    required bool isActive,
  }) async {
    final token = _storage.getToken();
    final response = await HttpClient.post(
      AppConstants.toggleUserActiveStatus,
      {'token': token, 'userId': userId, 'isActive': isActive},
    );
    return HttpResponseParser.parseSuccess(
      response,
      label: 'toggleUserActiveStatus',
    );
  }

  // ── Badge 2FA ─────────────────────────────────────────────────────────────

  /// Called during login when the server returns twoFAEnabled: true.
  /// [userId]        : internal userId from the login response (NOT authId).
  /// [scannedSecret] : raw string decoded from the badge QR code.
  /// Returns { "success": true } or { "success": false, "message": "..." }
  Future<Map<String, dynamic>> verifyBadge({
    required String scannedSecret,
    required String token,
  }) async {
    try {
      final response = await HttpClient.post(AppConstants.verifyBadgeUrl, {
        'scannedSecret': scannedSecret,
        'token': token,
      });
      return HttpResponseParser.parseObject(response, label: 'verifyBadge');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Admin dialog: get the current badge secret for a user.
  /// Returns { "success": true, "badgeSecret": "<64-char hex>" }
  Future<Map<String, dynamic>> getBadgeSecret({
    required String targetUserId,
  }) async {
    try {
      final token = _storage.getToken();
      final response = await HttpClient.post(AppConstants.getBadgeSecretUrl, {
        'adminToken': token,
        'targetUserId': targetUserId,
      });
      return HttpResponseParser.parseObject(response, label: 'getBadgeSecret');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Admin dialog: regenerate the badge secret for a user (lost badge).
  /// Returns { "success": true, "badgeSecret": "<new 64-char hex>" }
  Future<Map<String, dynamic>> regenerateBadge({
    required String targetUserId,
  }) async {
    try {
      final token = _storage.getToken();
      final response = await HttpClient.post(AppConstants.regenerateBadgeUrl, {
        'adminToken': token,
        'targetUserId': targetUserId,
      });
      return HttpResponseParser.parseObject(response, label: 'regenerateBadge');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }


  // ── Persistence passthrough (for callers that need async token access) ───

  String? getToken() => _storage.getToken();

  Map<String, dynamic>? getUserData() => _storage.getUserData();
}