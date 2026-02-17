import 'package:flutter/material.dart';
import 'package:pfe_mes/models/mes_user_model.dart';
import 'package:pfe_mes/services/mes_user_service.dart';

class MesUserProvider with ChangeNotifier {// this class notify the ui when data changes meaning ui will auto rebuild so no need to create setState
  final MesUserService _service = MesUserService();

  List<MesUser> users = [];// declaire the list here not the actual page 
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchUsers() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();//hey something changed rebuild pls

      users = await _service.fetchMesUsers();//will have the data inside it 
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }
}
