import 'package:flutter/material.dart';
import 'package:pfe_mes/data/admin/models/mes_log_model.dart';
import 'package:pfe_mes/data/admin/services/mes_log_service.dart';
import 'package:pfe_mes/domain/auth/providers/auth_provider.dart';

import '../../shared/async_state_mixin.dart';

class LogProvider with ChangeNotifier, AsyncStateMixin {
  final LogService _service = LogService();

  List<ActivityLogModel> activityLogs = [];
  List<MachineDashboardModel> machineDashboardList = [];

  // default = last 24h
  int selectedHours = 24;

  // Last 1h, Last 24h, Last 48h, Last 7 Days, Last 30 Days
  final List<int> hourOptions = [1, 24, 48, 168, 720];

  String labelFor(int h) {
    switch (h) {
      case 1:   return 'Last 1 Hour';
      case 24:  return 'Last 24h';
      case 48:  return 'Last 48h';
      case 168: return 'Last 7 Days';
      case 720: return 'Last 30 Days';
      default:  return 'Last ${h}h';
    }
  }

  Future<void> fetchActivityLog() async {
    
    await runAsync(() async {
      activityLogs = await _service.fetchActivityLog(selectedHours);
    });
  }
AuthProvider? _authProvider;


void setAuthProvider(AuthProvider auth) {
  _authProvider = auth;
}
 Future<void> fetchMachineDashboard([List<String>? workCenterList]) async {
  final list = workCenterList ?? <String>[];
  await runAsync(() async {
    machineDashboardList =
        await _service.fetchMachineDashboard(selectedHours, list);
  });
}

  void setHours(int hours) {
    selectedHours = hours;
    notifyListeners();
  }
}