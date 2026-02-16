import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pfe_mes/models/mes_user_model.dart';

class MesUserService {
  static const String baseUrl =
      'https://your-bc-tenant.api.businesscentral.dynamics.com/v2.0/production/api/yourcompany/mes/v1.0';

  static const String fetchMesUsersUrl =
      '$baseUrl/mesUsers';

  Future<List<MesUser>> fetchMesUsers() async {
    final response = await http.get(
      Uri.parse(fetchMesUsersUrl),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List usersJson = data['value'] ?? []; 

      return usersJson
          .map((json) => MesUser.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load MES users');
    }
  }
}
