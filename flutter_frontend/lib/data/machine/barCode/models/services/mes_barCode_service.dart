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
    final outerJson = jsonDecode(response.body);
    final innerJson = jsonDecode(outerJson['value']);
    if (innerJson['value'] == true) return true;
    throw Exception(innerJson['message'] ?? 'Unknown error');
  } else {
    throw Exception('Failed to insert scans: ${response.statusCode}');
  }
}
}