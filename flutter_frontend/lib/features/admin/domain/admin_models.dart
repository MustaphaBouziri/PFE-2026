// =============================================================================
// Admin Domain Models
// Path   : lib/features/admin/domain/admin_models.dart
// =============================================================================

/// Full MES user record as returned by the mesUsers API page.
class MesUser {
  const MesUser({
    required this.userId,
    required this.employeeId,
    required this.authId,
    required this.role,
    required this.workCenterNo,
    required this.workCenterName,
    required this.isActive,
    required this.needToChangePw,
    required this.createdAt,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  final String    userId;
  final String    employeeId;
  final String    authId;
  final String    role;
  final String    workCenterNo;
  final String    workCenterName;
  final bool      isActive;
  final bool      needToChangePw;
  final DateTime? createdAt;
  final String    firstName;
  final String    lastName;
  final String    email;

  String get fullName => '$firstName $lastName'.trim();

  factory MesUser.fromJson(Map<String, dynamic> j) => MesUser(
    userId:         j['userId']         as String? ?? '',
    employeeId:     j['employeeId']     as String? ?? '',
    authId:         j['authId']         as String? ?? '',
    role:           j['role']           as String? ?? '',
    workCenterNo:   j['workCenterNo']   as String? ?? '',
    workCenterName: j['workCenterName'] as String? ?? '',
    isActive:       j['isActive']       as bool?   ?? true,
    needToChangePw: j['needToChangePw'] as bool?   ?? false,
    createdAt:      j['createdAt'] != null
        ? DateTime.tryParse(j['createdAt'] as String)
        : null,
    firstName:      j['firstName']      as String? ?? '',
    lastName:       j['lastName']       as String? ?? '',
    email:          j['email']          as String? ?? '',
  );
}

/// BC Employee record from the employees API page.
class ErpEmployee {
  const ErpEmployee({
    required this.id,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
  });

  final String id;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;

  String get fullName =>
      [firstName, middleName, lastName].where((s) => s.isNotEmpty).join(' ');

  factory ErpEmployee.fromJson(Map<String, dynamic> j) => ErpEmployee(
    id:         j['id']         as String? ?? '',
    firstName:  j['firstName']  as String? ?? '',
    middleName: j['middleName'] as String? ?? '',
    lastName:   j['lastName']   as String? ?? '',
    email:      j['email']      as String? ?? '',
  );
}

/// BC Work Center record from the workCenters API page.
class ErpWorkCenter {
  const ErpWorkCenter({required this.id, required this.name});

  final String id;
  final String name;

  factory ErpWorkCenter.fromJson(Map<String, dynamic> j) => ErpWorkCenter(
    id:   j['id']             as String? ?? '',
    name: j['workCenterName'] as String? ?? '',
  );
}

/// Input model for creating a new MES user.
class CreateMesUserRequest {
  const CreateMesUserRequest({
    required this.userId,
    required this.employeeId,
    required this.roleInt,
    required this.workCenterNo,
  });

  final String userId;
  final String employeeId;
  final int    roleInt;     // 0=Operator, 1=Supervisor, 2=Admin
  final String workCenterNo;
}
