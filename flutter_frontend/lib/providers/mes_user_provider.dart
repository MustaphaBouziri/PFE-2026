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

  
  Future<bool> addUser(MesUser user) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final success = await _service.createMesUser(user);
      if (success) {
        users.add(user);
        notifyListeners();
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