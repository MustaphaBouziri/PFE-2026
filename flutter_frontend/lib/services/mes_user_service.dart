import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mes_user_model.dart';

class MesUserService {
  static const String baseUrl =
      'http://localhost:7048/BC210/api/yourcompany/v1/v1.0';
  static const String companyId =
      '9e31f41c-e73a-ed11-bbab-000d3a21ffa5';

  // GET users
  static String get fetchMesUsersUrl =>
      '$baseUrl/companies($companyId)/mesUsers';

  // POST create user
  static String get createMesUserUrl =>
      '$baseUrl/companies($companyId)/createMesUsers';

  Future<List<MesUser>> fetchMesUsers() async {
    final response = await http.get(
      Uri.parse(fetchMesUsersUrl),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List usersJson = data['value'] ?? [];
      return usersJson.map((json) => MesUser.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to load MES users: ${response.statusCode} ${response.body}');
    }
  }

  Future<bool> createMesUser({
    required String employeeId,
    required String role,
    required String workCenterNo,
    
  }) async {
    final body = jsonEncode({
       'employeeId': employeeId,
    'role': role,
    'workCenterNo': workCenterNo,
      
    });

    final response = await http.post(
      Uri.parse(createMesUserUrl),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
          'Failed to create MES user: ${response.statusCode} ${response.body}');
    }
  }
}