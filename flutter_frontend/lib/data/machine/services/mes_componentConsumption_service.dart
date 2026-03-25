import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/app_constants.dart';
import '../models/mes_componentConsumption_model.dart';

class MesComponentconsumptionService {
   Future<List<ComponentConsumptionModel>> fetchBom(
    String prodOrderNo,
    String operationNo,
  ) async {
    final body = jsonEncode({
      'prodOrderNo': prodOrderNo,
      'operationNo': operationNo,
    });

    final response = await http.post(
      Uri.parse(AppConstants.fetchBom),
      headers: AppConstants.jsonHeaders,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Response Body: ${response.body}');
      final String valueString = data['value'] ?? '[]';
      final List<dynamic> list = jsonDecode(valueString);
      return list.map((e) => ComponentConsumptionModel.fromJson(e)).toList();
    } else {
      throw Exception(
        'Failed to fetch Bill of materials : ${response.statusCode}',
      );
    }
  }

  Stream<List<ComponentConsumptionModel>> streamBom(
    
    String prodOrderNo,
    String operationNo,
    Stream<void> trigger,
  ) async* {
    yield await fetchBom( prodOrderNo, operationNo);
    await for (final _ in trigger) {
      yield await fetchBom( prodOrderNo, operationNo);
    }
  }
}