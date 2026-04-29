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
      final response = await HttpClient.post(AppConstants.loginUrl, {
        'userId': authId,
        'password': password,
        'deviceId': deviceId,
      });

      final result = HttpResponseParser.parseObject(response, label: 'login');

      if (result['success'] == true) {
        await _storage.saveToken(result['token'] as String);
        await _storage.saveUserData(result);
      }
      return result;
    } catch (e) {
      return {'error': 'Connection failed', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = _storage.getToken();
      final response = await HttpClient.post(AppConstants.meUrl, {
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

  Future<Map<String, dynamic>> logout() async {
    try {
      final token = _storage.getToken();
      final response = await HttpClient.post(AppConstants.logoutUrl, {
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
    final response = await HttpClient.post(AppConstants.adminSetPasswordUrl, {
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

  // ── Persistence passthrough (for callers that need async token access) ───

  String? getToken() => _storage.getToken();

  Map<String, dynamic>? getUserData() => _storage.getUserData();
}
