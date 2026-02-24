// =============================================================================
// IAuthRepository
// Path   : lib/features/auth/domain/i_auth_repository.dart
// Purpose: Abstract contract for the auth repository.
//          Providers depend on this interface — not the concrete class —
//          so the backend can be swapped or mocked in tests without any
//          changes to provider or UI code.
// =============================================================================

import './auth_model.dart';

abstract interface class IAuthRepository {
  Future<AuthSession>    login(String userId, String password);
  Future<void>           logout(String token);
  Future<MesUserProfile> me(String token);
  Future<void>           changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  });
}
