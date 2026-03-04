import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/erp_order_model.dart';
import '../../../core/constants/app_constants.dart';

class ErpMachineOrdersService {
  Future<List<MachineOrderModel>> getMachineOrders(String machineNo) async {
    final body = jsonEncode({'machineNo': machineNo});

    final response = await http.post(
      Uri.parse(AppConstants.getMachineOrdersUrl),
      headers: AppConstants.jsonHeaders,
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

  Future<bool> getStartOperationValidation(
    String prodOderNo,
    String operationNo,
    String machineNo,
  ) async {
    final body = jsonEncode({
      'prodOderNo': prodOderNo,
      'operationNo': operationNo,
      'machineNo': machineNo,
    });

    final response = await http.post(
      Uri.parse(AppConstants.getStartOrderValidation),
      headers: AppConstants.jsonHeaders,
      body: body,
    );

    if (response.statusCode == 200) {
      final outerJson = jsonDecode(response.body);

      final innerJson = jsonDecode(outerJson['value']);

      if (innerJson['value'] == true) {
        return true;
      } else {
        throw Exception(innerJson['message'] ?? 'Unknown error');
      }
    } else {
      throw Exception('Failed to start operation: ${response.statusCode} ${response.body}');
    }
  }

  //____________fetch machine operation status monitoring

  Future<List<Map<String, dynamic>>> fetchMachineOperationStatus(
    String machineNo,
  ) async {
  
    final body = jsonEncode({'machineNo': machineNo});

    final response = await http.post(
      Uri.parse(AppConstants.fetchMachineOperationStatus),
      headers: AppConstants.jsonHeaders,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final String valueString = data['value'] ?? '[]';

      final List<dynamic> decodedList = jsonDecode(valueString);

      return decodedList
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } else {
      throw Exception(
        'Failed to fetch machine operations status: ${response.statusCode}',
      );
    }
  }

  // __________________ STREAM __________________

  Stream<List<Map<String, dynamic>>> streamMachines(String machineNo) async* {
    while (true) {
      try {
        final machineOperationsStatus = await fetchMachineOperationStatus(
          machineNo,
        );

        yield machineOperationsStatus;
      } catch (e) {
        yield [];
      }

      await Future.delayed(const Duration(seconds: 5));
    }
  }
}
