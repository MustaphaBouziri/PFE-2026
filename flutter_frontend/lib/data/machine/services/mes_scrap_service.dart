import 'package:http/http.dart' as http;

import '../../../core/app_constants.dart';
import '../../shared/http_client.dart';
import '../../shared/http_response_parser.dart';
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

    final List list = HttpResponseParser.parseList(
      response,
      label: 'load scrap codes',
    );
    return list.map((e) => MesScrapCode.fromJson(e)).toList();
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
    final response = await HttpClient.post(AppConstants.declareScrapUrl, {
      'token': token,
      'executionId': executionId,
      'description': description,
      'scrapCode': scrapCode,
      'quantity': quantity,
    });

    return HttpResponseParser.parseWriteResult(
      response,
      label: 'declare scrap',
    );
  }
}
