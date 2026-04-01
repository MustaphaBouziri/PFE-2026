import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/mes_user_model.dart';
import '../../../core/app_constants.dart';

class MesUserService {


  Future<List<MesUser>> fetchMesUsers() async {
    final response = await http.get(
      Uri.parse(AppConstants.mesUsersUrl),
      headers:AppConstants.jsonHeaders,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List usersJson = data['value'] ?? [];
      return usersJson.map((json) => MesUser.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to load MES users: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<bool> createMesUser({
    required String employeeId,
    required int roleInt,
    required List<String> workCenterList,
  }) async {
    final body = jsonEncode({
    'userId': employeeId,
    'employeeId': employeeId,
    'authId': employeeId,
    'roleInt': roleInt,
    'workCenterListJson': jsonEncode(workCenterList),
    });

    final response = await http.post(
      Uri.parse(AppConstants.AdminCreateUser),
      headers:AppConstants.jsonHeaders,
      body: body,
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
        'Failed to create MES user: ${response.statusCode} ${response.body}',
      );
    }
  }
}
