import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/app_constants.dart';
import '../models/mes_scrapCode_model.dart';

/// Handles scrap-code lookups and scrap declaration.
/// declareScrap now requires the session token so the backend can
/// attribute the declaration to the correct MES user.
class MesScrapService {
  /// Fetches all available scrap codes from the ERP.
  Future<List<MesScrapCode>> fetchScrapCodes() async {
    final response = await http.get(
      Uri.parse(AppConstants.scrapCodesUrl),
      headers: AppConstants.jsonHeaders,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['value'] ?? [];
      return list.map((e) => MesScrapCode.fromJson(e)).toList();
    }
    throw Exception('Failed to load scrap codes: ${response.statusCode}');
  }

  /// Declares scrapped units for [executionId].
  /// [token] — session token from the authenticated user.
  Future<bool> declareScrap({
    required String token,
    required String executionId,
    required String scrapCode,
    required double quantity,
    String description = '',
  }) async {
    final body = jsonEncode({
      'token': token,
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
      final outer = jsonDecode(response.body);
      final inner = jsonDecode(outer['value']);
      if (inner['value'] == true) return true;
      throw Exception(inner['message'] ?? 'Unknown error');
    }
    throw Exception('Failed to declare scrap: ${response.statusCode}');
  }
}
