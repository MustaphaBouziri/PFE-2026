import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pfe_mes/core/storage/session_storage.dart';

import '../../../core/app_constants.dart';
import '../../shared/http_client.dart';
import '../../shared/http_response_parser.dart';
import '../models/mes_scrapCode_model.dart';

class MesScrapService {
  final SessionStorage _sessionStorage = SessionStorage();

  Future<List<MesScrapCode>> fetchScrapCodes() async {
    final response = await http.get(
      Uri.parse(AppConstants.scrapCodesUrl),
      headers: AppConstants.jsonHeaders,
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final list = data['value'] as List;
    return list.map((e) => MesScrapCode.fromJson(e)).toList();
  }

  Future<bool> declareScrap({
    required String executionId,
    required String scrapCode,
    required double quantity,
    String description = '',
    String materialId = '',
    required String onBehalfOfUserId,
  }) async {
    final token = _sessionStorage.getToken();
    final response = await HttpClient.post(AppConstants.declareScrapUrl, {
      'token': token,
      'executionId': executionId,
      'description': description,
      'scrapCode': scrapCode,
      'quantity': quantity,
      'materialId': materialId,
      'onBehalfOfUserId': onBehalfOfUserId,
    });
    return HttpResponseParser.parseWriteResult(
      response,
      label: 'declare scrap',
    );
  }
}
