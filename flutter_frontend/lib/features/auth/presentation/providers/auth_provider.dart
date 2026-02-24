// =============================================================================
// AuthProvider
// Path   : lib/features/auth/presentation/providers/auth_provider.dart
// Purpose: State management for authentication.
//          Accepts IAuthRepository via constructor injection — pass a mock
//          implementation in tests, the real AuthRepository in production.
// =============================================================================

import 'package:flutter/foundation.dart';

import '../../data/auth_repository.dart';
import '../../domain/auth_model.dart';
import '../../domain/i_auth_repository.dart';
import '../../../../core/errors/app_exceptions.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthProvider({IAuthRepository? repository})
      : _repo = repository ?? AuthRepository();

  final IAuthRepository _repo;

  AuthStatus      _status  = AuthStatus.initial;
  AuthSession?    _session;
  MesUserProfile? _profile;
  String?         _errorMessage;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  AuthStatus      get status       => _status;
  AuthSession?    get session      => _session;
  MesUserProfile? get profile      => _profile;
  String?         get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading       => _status == AuthStatus.loading;
  bool get needToChangePw  => _session?.needToChangePw ?? false;

  String? get token        => _session?.token;
  String? get userId       => _session?.userId;
  String? get role         => _session?.role;
  String? get workCenterNo => _session?.workCenterNo;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> login(String userId, String password) async {
    _setLoading();
    try {
      _session      = await _repo.login(userId, password);
      _status       = AuthStatus.authenticated;
      _errorMessage = null;
    } on AppException catch (e) {
      _session      = null;
      _status       = AuthStatus.unauthenticated;
      _errorMessage = e.message;
    } finally {
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (_session == null) return;
    try {
      await _repo.logout(_session!.token);
    } catch (_) {
      // Always clear local session even if server revocation fails
    } finally {
      _clearSession();
    }
  }

  Future<void> refreshProfile() async {
    if (_session == null) return;
    try {
      _profile = await _repo.me(_session!.token);
      notifyListeners();
    } on SessionExpiredException {
      _clearSession();
    } catch (_) {
      // Profile refresh failure is non-fatal — keep existing session
    }
  }

  /// Returns true on success. On failure, stays authenticated and sets errorMessage.
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (_session == null) return false;
    _setLoading();
    try {
      await _repo.changePassword(
        token:       _session!.token,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      // Server revokes ALL tokens after a password change — force re-login.
      _clearSession();
      return true;
    } on AppException catch (e) {
      _status       = AuthStatus.authenticated;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _setLoading() {
    _status       = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _clearSession() {
    _session      = null;
    _profile      = null;
    _status       = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }
}
