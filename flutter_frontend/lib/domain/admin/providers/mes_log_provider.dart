import 'package:flutter/material.dart';
import 'package:pfe_mes/data/admin/models/mes_log_model.dart';
import 'package:pfe_mes/data/admin/services/mes_log_service.dart';

import '../../shared/async_state_mixin.dart';

class LogProvider with ChangeNotifier, AsyncStateMixin {
  final LogService _service = LogService();

  List<ActivityLogModel> activityLogs = [];
  List<MachineDashboardModel> machineDashboardList = [];

  int selectedHours = 24;
  final List<int> hourOptions = [1, 8, 24, 48, 168];

  Future<void> fetchActivityLog() async {
    await runAsync(() async {
      activityLogs = await _service.fetchActivityLog(selectedHours);
    });
  }

  Future<void> fetchMachineDashboard() async {
    await runAsync(() async {
      machineDashboardList = await _service.fetchMachineDashboard(selectedHours);
    });
  }

  void setHours(int hours) {
    selectedHours = hours;
    notifyListeners();
  }
}