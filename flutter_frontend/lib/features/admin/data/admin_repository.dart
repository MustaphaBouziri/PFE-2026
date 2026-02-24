// =============================================================================
// IAdminRepository + AdminRepository
// Path   : lib/features/admin/data/admin_repository.dart
// =============================================================================

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/admin_models.dart';

abstract interface class IAdminRepository {
  Future<List<MesUser>>       getMesUsers(String companyId);
  Future<List<ErpEmployee>>   getEmployees(String companyId);
  Future<List<ErpWorkCenter>> getWorkCenters(String companyId);

  Future<void> setPassword({
    required String adminToken,
    required String targetUserId,
    required String newPassword,
  });

  Future<void> setActive({
    required String adminToken,
    required String targetUserId,
    required bool   isActive,
  });

  Future<String> createUser({
    required String adminToken,
    required CreateMesUserRequest request,
  });
}

class AdminRepository implements IAdminRepository {
  AdminRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  String get _service => AppConfig.bc.odataServiceName;

  @override
  Future<List<MesUser>> getMesUsers(String companyId) async {
    final rows = await _client.getEntitySet(companyId, AppConstants.api.entitySetMesUsers);
    return rows.map(MesUser.fromJson).toList();
  }

  @override
  Future<List<ErpEmployee>> getEmployees(String companyId) async {
    final rows = await _client.getEntitySet(companyId, AppConstants.api.entitySetEmployees);
    return rows.map(ErpEmployee.fromJson).toList();
  }

  @override
  Future<List<ErpWorkCenter>> getWorkCenters(String companyId) async {
    final rows = await _client.getEntitySet(companyId, AppConstants.api.entitySetWorkCenters);
    return rows.map(ErpWorkCenter.fromJson).toList();
  }

  @override
  Future<void> setPassword({
    required String adminToken,
    required String targetUserId,
    required String newPassword,
  }) async {
    await _client.postODataAction(_service, AppConstants.api.actionAdminSetPassword, {
      'token':       adminToken,
      'userId':      targetUserId,
      'newPassword': newPassword,
    });
  }

  @override
  Future<void> setActive({
    required String adminToken,
    required String targetUserId,
    required bool   isActive,
  }) async {
    await _client.postODataAction(_service, AppConstants.api.actionAdminSetActive, {
      'token':    adminToken,
      'userId':   targetUserId,
      'isActive': isActive,
    });
  }

  @override
  Future<String> createUser({
    required String adminToken,
    required CreateMesUserRequest request,
  }) async {
    final data = await _client.postODataAction(
        _service, AppConstants.api.actionAdminCreateUser, {
      'token':        adminToken,
      'userId':       request.userId,
      'employeeId':   request.employeeId,
      'authId':       '',  // auto-generated server-side
      'roleInt':      request.roleInt,
      'workCenterNo': request.workCenterNo,
    });
    return data['userId'] as String? ?? request.userId;
  }
}
