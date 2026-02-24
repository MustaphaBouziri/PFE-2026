// =============================================================================
// Auth Domain Models
// Path   : lib/features/auth/domain/auth_models.dart
// =============================================================================

/// An active MES session returned by a successful Login call.
class AuthSession {
  const AuthSession({
    required this.token,
    required this.expiresAt,
    required this.userId,
    required this.name,
    required this.role,
    required this.workCenterNo,
    required this.needToChangePw,
  });

  final String   token;
  final DateTime expiresAt;
  final String   userId;
  final String   name;          // Auth ID from BC, used as display name
  final String   role;          // 'Operator' | 'Supervisor' | 'Admin'
  final String   workCenterNo;
  final bool     needToChangePw;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory AuthSession.fromJson(Map<String, dynamic> j) => AuthSession(
    token:          j['token']          as String,
    expiresAt:      DateTime.parse(j['expiresAt'] as String),
    userId:         j['userId']         as String,
    name:           j['name']           as String,
    role:           j['role']           as String,
    workCenterNo:   j['workCenterNo']   as String? ?? '',
    needToChangePw: j['needToChangePw'] as bool?   ?? false,
  );
}

/// Current user profile returned by the /Me endpoint.
class MesUserProfile {
  const MesUserProfile({
    required this.userId,
    required this.name,
    required this.role,
    required this.workCenterNo,
    required this.needToChangePw,
    required this.isActive,
  });

  final String userId;
  final String name;
  final String role;
  final String workCenterNo;
  final bool   needToChangePw;
  final bool   isActive;

  factory MesUserProfile.fromJson(Map<String, dynamic> j) => MesUserProfile(
    userId:         j['userId']         as String,
    name:           j['name']           as String,
    role:           j['role']           as String,
    workCenterNo:   j['workCenterNo']   as String? ?? '',
    needToChangePw: j['needToChangePw'] as bool?   ?? false,
    isActive:       j['isActive']       as bool?   ?? true,
  );
}
