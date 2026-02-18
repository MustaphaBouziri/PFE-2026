import 'package:flutter/material.dart';
import '../models/mes_user_model.dart';
import '../services/mes_user_service.dart';

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

      users = await _service.fetchMesUsers();
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> addUser({
    required String employeeId,
    required String role,
    required String workCenterNo,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final success = await _service.createMesUser(
        employeeId: employeeId,
        role: role,
        workCenterNo: workCenterNo,
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
