import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/app_constants.dart';
import '../models/erp_workCenter_model.dart';

class ErpWorkcenterService {
  Future<List<ErpWorkCenter>> fetchWorkCenters() async {
    final response = await http.get(
      Uri.parse(AppConstants.workCentersUrl),
      headers: AppConstants.jsonHeaders,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['value'] as List? ?? [];
      return list.map((e) => ErpWorkCenter.fromJson(e)).toList();
    }
    throw Exception(
      'Failed to load work centers: ${response.statusCode} ${response.body}',
    );
  }
}