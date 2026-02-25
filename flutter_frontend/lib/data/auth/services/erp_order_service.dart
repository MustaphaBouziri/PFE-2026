import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../../admin/models/erp_order_model.dart';

class ErpMachineOrdersService {
  Future<List<MachineOrderModel>> getMachineOrders(String machineNo) async {
    final body = jsonEncode({'machineNo': machineNo});

    final response = await http.post(
      Uri.parse(AppConstants.getMachineOrdersUrl),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final String valueString = data['value'] ?? '[]';

      final List<dynamic> machineOrdersList = jsonDecode(valueString);

      return machineOrdersList
          .map((machineOrder) => MachineOrderModel.fromJson(machineOrder))
          .toList();
    } else {
      throw Exception(
        'Failed to fetch machine orders: ${response.statusCode} ${response.body}',
      );
    }
  }
}
