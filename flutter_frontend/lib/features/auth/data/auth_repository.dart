// =============================================================================
// AuthRepository
// Path   : lib/features/auth/data/auth_repository.dart
// Purpose: Concrete IAuthRepository implementation.
//          Translates domain calls into BC OData API requests via ApiClient.
//          All HTTP details live in ApiClient — this class only maps
//          request shapes and action names.
// =============================================================================

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/auth_model.dart';
import '../domain/i_auth_repository.dart';

class AuthRepository implements IAuthRepository {
  AuthRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  String get _service => AppConfig.bc.odataServiceName;

  @override
  Future<AuthSession> login(String userId, String password) async {
    final data = await _client.postODataAction(_service, AppConstants.api.actionLogin, {
      'userId':   userId,
      'password': password,
      'deviceId': AppConfig.session.deviceId,
    });
    return AuthSession.fromJson(data);
  }

  @override
  Future<void> logout(String token) async {
    await _client.postODataAction(_service, AppConstants.api.actionLogout, {'token': token});
  }

  @override
  Future<MesUserProfile> me(String token) async {
    final data = await _client.postODataAction(_service, AppConstants.api.actionMe, {'token': token});
    return MesUserProfile.fromJson(data);
  }

  @override
  Future<void> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    await _client.postODataAction(_service, AppConstants.api.actionChangePassword, {
      'token':       token,
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }
}
