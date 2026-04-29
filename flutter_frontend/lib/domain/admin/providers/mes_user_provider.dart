import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/storage/session_storage.dart';
import '../../../data/admin/models/mes_user_model.dart';
import '../../../data/admin/services/mes_user_service.dart';
import '../../shared/async_state_mixin.dart';

class MesUserProvider with ChangeNotifier, AsyncStateMixin {
  final MesUserService _service = MesUserService();
  final SessionStorage _sessionStorage = SessionStorage();
  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  void triggerRefresh() {
    _refreshController.add(());
  }

  @override
  void dispose() {
    _refreshController.close();
    super.dispose();
  }

  List<MesUser> users = [];

  Future<void> fetchUsersByWc({required String wcId}) async {
    await runAsync(() async {
      users = await _service.fetchMESUsersByWC(wcId: wcId);
    });
  }

  Stream<List<MesUser>> fetchMesUsers() {
    return _service.streamFetchAllMESUsers(trigger: _refreshController.stream);
  }

  Future<bool> addUser({
    required String employeeId,
    required int roleInt,
    required List<String> workCenterList,
  }) async {
    final result = await runAsync(
      () => _service.createMesUser(
        employeeId: employeeId,
        roleInt: roleInt,
        workCenterList: workCenterList,
      ),
    );

    if (result == true) {
      triggerRefresh();
    }

    return result ?? false;
  }

  Future<bool> changeUserRole({
    required String targetUserId,
    required int newRoleInt,
    required List<String> workCenterList,
  }) async {
    final result = await runAsync(() async {
      final token = await _sessionStorage.getToken() ?? '';
      final success = await _service.changeUserRole(
        targetUserId: targetUserId,
        newRoleInt: newRoleInt,
        workCenterList: workCenterList,
      );

      if (success) triggerRefresh();
      return success;
    });

    return result ?? false;
  }
}
