import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/app_constants.dart';
import '../models/mes_scrapCode_model.dart';

class MesScrapService {
  Future<List<MesScrapCode>> fetchScrapCodes() async {
    final response = await http.get(
      Uri.parse(AppConstants.scrapCodesUrl),
      headers: AppConstants.jsonHeaders,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['value'] ?? [];
      return list.map((e) => MesScrapCode.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load scrap codes: ${response.statusCode}');
    }
  }

  Future<bool> declareScrap({
    required String executionId,
    required String scrapCode,
    required double quantity,
    String description = '',
  }) async {
    final body = jsonEncode({
      'executionId': executionId,
      'description': description,
      'scrapCode': scrapCode,
      'quantity': quantity,
    });

    final response = await http.post(
      Uri.parse(AppConstants.declareScrapUrl),
      headers: AppConstants.jsonHeaders,
      body: body,
    );

    if (response.statusCode == 200) {
      final outerJson = jsonDecode(response.body);
      final innerJson = jsonDecode(outerJson['value']);
      if (innerJson['value'] == true) return true;
      throw Exception(innerJson['message'] ?? 'Unknown error');
    } else {
      throw Exception('Failed to declare scrap: ${response.statusCode}');
    }
  }
}