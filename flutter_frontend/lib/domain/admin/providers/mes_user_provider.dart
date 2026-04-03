import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/admin/models/mes_user_model.dart';
import '../../../data/admin/services/mes_user_service.dart';

class MesUserProvider with ChangeNotifier {
  final MesUserService _service = MesUserService();
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
}
