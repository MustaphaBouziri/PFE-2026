// lib/data/barcode/services/barcode_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../../core/app_constants.dart';
import 'package:pfe_mes/data/machine/barCode/models/mes_barCode_model.dart';

class MesBarcodeService {
  Future<List<ItemBarcodeModel>> fetchAllBarcodes() async {
    // Use the same POST pattern as MesComponentconsumptionService
    final response = await http.post(
      Uri.parse(AppConstants.fetchAllItemBarcodes),
      headers: AppConstants.jsonHeaders,
      body: jsonEncode({}), // empty body, or maybe parameters if needed
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(data);
      final String valueString = data['value'] ?? '[]';
      final List<dynamic> list = jsonDecode(valueString);
      return list.map((e) => ItemBarcodeModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load barcodes: ${response.statusCode}');
    }
  }

  Future<bool> insertScans(
    String executionId,
    List<Map<String, dynamic>> scans,
  ) async {
    //jsonEncode convert a dart obj into json string
    // why 2 encode ? the al expect scansJson to be a string that contain JSON array
    /**
    {
    "executionId": "EX123",
    "scansJson": "[{\"itemNo\":\"A1\",...}, ...]"
    }
  */
    final body = jsonEncode({
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
      final result = jsonDecode(data['value'] ?? '{}'); //decode from string to map

      if (result['value'] == true) return true;

      throw Exception(result['message'] ?? 'Unknown error');
    } else {
      throw Exception('Failed to insert scans: ${response.statusCode}');
    }
  }
}
