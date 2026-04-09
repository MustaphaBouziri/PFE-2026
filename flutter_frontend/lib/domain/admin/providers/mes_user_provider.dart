import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/admin/models/mes_user_model.dart';
import '../../../data/admin/services/mes_user_service.dart';
import '../../../data/auth/services/api_service.dart';

class MesUserProvider with ChangeNotifier {
  final MesUserService _service = MesUserService();
  final ApiService _apiService = ApiService();
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
  bool isLoading = false;
  String? errorMessage;

  // Fetch users


  Future<void> fetchUsersByWc({required String wcId}) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      users = await _service.fetchMESUsersByWC(wcId: wcId);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  Stream<List<MesUser>> fetchMesUsers() {
  return _service.streamFetchAllMESUsers(trigger: _refreshController.stream);
}

  Future<bool> addUser({
    required String employeeId,
    required int roleInt,
    required List<String> workCenterList,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final success = await _service.createMesUser(
        employeeId: employeeId,
        roleInt: roleInt,
        workCenterList: workCenterList,
      );

      return success;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Changes the role of [targetUserId] and resets their work-center assignments.
  /// Triggers a refresh of the user list stream on success.
  Future<bool> changeUserRole({
    required String targetUserId,
    required int newRoleInt,
    required List<String> workCenterList,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
      final token = await _apiService.getToken() ?? '';
      final success = await _service.changeUserRole(
        token: token,
        targetUserId: targetUserId,
        newRoleInt: newRoleInt,
        workCenterList: workCenterList,
      );

      if (success) triggerRefresh();
      return success;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
