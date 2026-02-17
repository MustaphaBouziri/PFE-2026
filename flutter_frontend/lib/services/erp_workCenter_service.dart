import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pfe_mes/models/erp_employees_model.dart';
import 'package:pfe_mes/models/erp_workCenter_model.dart';

class ErpWorkcenterService {
  static const String baseUrl =
      'http://localhost:7048/BC210/api/yourcompany/v1/v1.0';
  static const String companyId = '9e31f41c-e73a-ed11-bbab-000d3a21ffa5';

  static String get fetchWorkCenterUrl =>
      '$baseUrl/companies($companyId)/workCenters';

  Future<List<ErpWorkCenter>> fetchWorkCenters() async {
    final response = await http.get(
      Uri.parse(fetchWorkCenterUrl),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List workCenterJson = data['value'] ?? [];
      return workCenterJson.map((json) =>  ErpWorkCenter.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to load work center: ${response.statusCode} ${response.body}');
    }
  
  }
}
