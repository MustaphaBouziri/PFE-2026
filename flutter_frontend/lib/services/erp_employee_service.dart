import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pfe_mes/models/erp_employees_model.dart';

class ErpEmployeeService {
  static const String baseUrl =
      'http://localhost:7048/BC210/api/yourcompany/v1/v1.0';
  static const String companyId = '9e31f41c-e73a-ed11-bbab-000d3a21ffa5';

  static String get fetchErpEmployeesUrl =>
      '$baseUrl/companies($companyId)/employees';

  Future<List<ErpEmployee>> fetchEmployees() async {
    final response = await http.get(
      Uri.parse(fetchErpEmployeesUrl),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List usersJson = data['value'] ?? [];
      return usersJson.map((json) =>  ErpEmployee.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to load Employees: ${response.statusCode} ${response.body}');
    }
  
  }
}
