import 'package:flutter/material.dart';

import '../../../data/admin/models/mes_user_model.dart';
import '../../../data/admin/services/mes_user_service.dart';

class MesUserProvider with ChangeNotifier {
  final MesUserService _service = MesUserService();

  List<MesUser> users = [];
  bool isLoading = false;
  String? errorMessage;

  // Fetch users
  Future<void> fetchUsers() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      users = await _service.fetchAllMESUsers();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

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
      if (success) {
        await fetchUsers(); // to refresh the mes list user if i dont do it it wont show the new user
      }
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
