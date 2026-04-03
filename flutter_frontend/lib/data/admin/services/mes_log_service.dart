import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pfe_mes/data/admin/models/mes_log_model.dart';

import '../../../core/app_constants.dart';

class LogService {
  Future<List<ActivityLogModel>> fetchActivityLog(int hoursBack) async {
    final body = jsonEncode({'hoursBack': hoursBack});
    final response = await http.post(
      Uri.parse(AppConstants.fetchActivityLog),
      headers: AppConstants.jsonHeaders,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final String valueString = data['value'] ?? '[]';
      final List<dynamic> list = jsonDecode(valueString);
      return list.map((e) => ActivityLogModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch activity log: ${response.statusCode}');
    }
  }

  Future<List<MachineDashboardModel>> fetchMachineDashboard(int hoursBack) async {
    final body = jsonEncode({'hoursBack': hoursBack});
    final response = await http.post(
      Uri.parse(AppConstants.fetchMachineDashboard),
      headers: AppConstants.jsonHeaders,
      body: body,
    );

    if (response.statusCode == 200) {
      print(response.body);
      final data = jsonDecode(response.body);
      final String valueString = data['value'] ?? '[]';
      final List<dynamic> list = jsonDecode(valueString);
      return list.map((e) => MachineDashboardModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch machine dashboard: ${response.statusCode}');
    }
  }
}