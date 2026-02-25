import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/erp_workCenter_model.dart';
import '../../../core/constants/app_constants.dart';

class ErpWorkcenterService {

  Future<List<ErpWorkCenter>> fetchWorkCenters() async {
    final response = await http.get(
      Uri.parse(AppConstants.workCentersUrl),
      headers:AppConstants.jsonHeaders,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List workCenterJson = data['value'] ?? [];
      return workCenterJson
          .map((json) => ErpWorkCenter.fromJson(json))
          .toList();
    } else {
      throw Exception(
        'Failed to load work center: ${response.statusCode} ${response.body}',
      );
    }
  }
}
