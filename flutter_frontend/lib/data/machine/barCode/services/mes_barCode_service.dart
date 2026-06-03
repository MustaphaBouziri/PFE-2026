import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pfe_mes/core/storage/session_storage.dart';

import '../../../../core/app_constants.dart';
import '../models/mes_barCode_model.dart';

class MesBarcodeService {
  final SessionStorage _sessionStorage = SessionStorage();

  Future<List<ItemBarcodeModel>> fetchAllBarcodes() async {
    final response = await http.post(
      Uri.parse(AppConstants.fetchAllItemBarcodes),
      headers: AppConstants.jsonHeaders,
      body: jsonEncode({}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = jsonDecode(data['value'] as String? ?? '[]') as List;
      return list.map((e) => ItemBarcodeModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load barcodes: ${response.statusCode}');
  }

  // Future<bool> insertScans(
  //   String executionId,
  //   List<Map<String, dynamic>> scans,
  // ) async {
  //   final token = _sessionStorage.getToken();
  //   final response = await http.post(
  //     Uri.parse(AppConstants.insertScans),
  //     headers: AppConstants.jsonHeaders,
  //     body: jsonEncode({
  //       'token': token,
  //       'executionId': executionId,
  //       'scansJson': jsonEncode(scans),
  //     }),
  //   );

  //   if (response.statusCode == 200) {
  //     final data = jsonDecode(response.body) as Map<String, dynamic>;
  //     final result =
  //         jsonDecode(data['value'] as String? ?? '{}') as Map<String, dynamic>;
  //     if (result['value'] == true) return true;
  //     throw Exception(result['message'] ?? 'Unknown error');
  //   }
  //   throw Exception('Failed to insert scans: ${response.statusCode}');
  // }


  Future<bool> insertScans(
  String executionId,
  List<Map<String, dynamic>> scans,
) async {
  final token = _sessionStorage.getToken();

  final response = await http.post(
    Uri.parse(AppConstants.insertScans),
    headers: AppConstants.jsonHeaders,
    body: jsonEncode({
      'token': token,
      'executionId': executionId,
      'scansJson': jsonEncode(scans),
    }),
  );

  // // Print useful debug information
  // print('=== insertScans DEBUG ===');
  // print('Status code: ${response.statusCode}');
  // print('Response body: ${response.body}');
  // print('=========================');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final result =
        jsonDecode(data['value'] as String? ?? '{}') as Map<String, dynamic>;

    if (result['value'] == true) {
      return true;
    }

    throw Exception(result['message'] ?? 'Unknown error');
  }

  // Try to extract Business Central error message from HTTP 400 response
  try {
    final data = jsonDecode(response.body);

    // Sometimes BC returns {"error":{"message":"..."}}
    if (data is Map<String, dynamic>) {
      if (data['error'] is Map<String, dynamic>) {
        final error = data['error'] as Map<String, dynamic>;
        final message = error['message'];
        if (message != null) {
          throw Exception(message.toString());
        }
      }

      // Sometimes your wrapper returns {"value":"{\"message\":\"...\"}"}
      if (data['value'] != null) {
        final inner = jsonDecode(data['value'].toString());
        if (inner is Map<String, dynamic> && inner['message'] != null) {
          throw Exception(inner['message'].toString());
        }
      }
    }
  } catch (_) {
    // If parsing fails, fall back to raw body below
  }

  // Final fallback: include raw response body
  throw Exception(
    'Failed to insert scans (${response.statusCode})\n${response.body}',
  );
}






  Future<Map<String, dynamic>?> resolveBarcode(String barcode) async {
    final response = await http.post(
      Uri.parse(AppConstants.fetchResolveBarcode),
      headers: AppConstants.jsonHeaders,
      body: jsonEncode({'barcode': barcode}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return jsonDecode(data['value'] as String) as Map<String, dynamic>;
    }
    return null;
  }
}
