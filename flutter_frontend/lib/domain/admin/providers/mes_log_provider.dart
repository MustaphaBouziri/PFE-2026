import 'package:flutter/material.dart';
import 'package:pfe_mes/data/admin/models/mes_log_model.dart';
import 'package:pfe_mes/data/admin/services/mes_log_service.dart';

class LogProvider with ChangeNotifier {
  final LogService _service = LogService();

  List<ActivityLogModel> activityLogs = [];
  List<MachineDashboardModel> machineDashboardList = [];
  bool isLoading = false;
  String? errorMessage;

  int selectedHours = 24;
  final List<int> hourOptions = [1, 8, 24, 48, 168];

  Future<void> fetchActivityLog() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      activityLogs = await _service.fetchActivityLog(selectedHours);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMachineDashboard() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      machineDashboardList = await _service.fetchMachineDashboard(selectedHours);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setHours(int hours) {
    selectedHours = hours;
    notifyListeners();
  }
}