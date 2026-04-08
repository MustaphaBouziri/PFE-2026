import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pfe_mes/data/machine/barCode/models/mes_barCode_model.dart';

import '../../../../../core/app_constants.dart';

/// Handles barcode/item data fetching and scan insertion.
/// insertScans now requires the session token so the backend can
/// attribute each scan to the correct MES user.
class MesBarcodeService {
  /// Returns all items with their barcode text from the ERP.
  Future<List<ItemBarcodeModel>> fetchAllBarcodes() async {
    final response = await http.post(
      Uri.parse(AppConstants.fetchAllItemBarcodes),
      headers: AppConstants.jsonHeaders,
      body: jsonEncode({}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final String valueString = data['value'] ?? '[]';
      final List<dynamic> list = jsonDecode(valueString);
      return list.map((e) => ItemBarcodeModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load barcodes: ${response.statusCode}');
  }

  /// Submits a batch of component scans for [executionId].
  /// [token] — session token from the authenticated user.
  Future<bool> insertScans(
    String token,
    String executionId,
    List<Map<String, dynamic>> scans,
    ) async {
    final body = jsonEncode({
      'token': token,
      'executionId': executionId,
      'scansJson': jsonEncode(scans),

    });

    final response = await http.post(
      Uri.parse(AppConstants.insertScans),
      headers: AppConstants.jsonHeaders,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final result = jsonDecode(data['value'] ?? '{}');
      if (result['value'] == true) return true;
      throw Exception(result['message'] ?? 'Unknown error');
    }
    throw Exception('Failed to insert scans: ${response.statusCode}');
  }
}
