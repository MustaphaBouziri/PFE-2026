import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/app_constants.dart';
import '../models/erp_employees_model.dart';

class ErpEmployeeService {
  Future<List<ErpEmployee>> fetchEmployees() async {
    final response = await http.get(
      Uri.parse(AppConstants.employeesUrl),
      headers:AppConstants.jsonHeaders,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List usersJson = data['value'] ?? [];
      return usersJson.map((json) => ErpEmployee.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to load Employees: ${response.statusCode} ${response.body}',
      );
    }
  }
}
