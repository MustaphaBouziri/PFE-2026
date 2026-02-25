import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pfe_mes/models/erp_order_model.dart';
import 'package:pfe_mes/models/mes_machine_model.dart';

class ErpMachineOrdersService {
  static const String baseUrl =
      'http://localhost:7048/BC210/ODataV4/MESMachinesActionsEndpoints_';
  //http://localhost:7048/BC210/ODataV4/MESMachinesActionsEndpoints_FetchMachines?company=9e31f41c-e73a-ed11-bbab-000d3a21ffa5
  static const String companyId = '9e31f41c-e73a-ed11-bbab-000d3a21ffa5';

  static const String fetchMachineOrderEndpoint =
      '${baseUrl}getMachineOrders?company=$companyId';

  Future<List<MachineOrderModel>> getMachineOrders(String machineNo) async {
    final body = jsonEncode({'machineNo': machineNo});

    final response = await http.post(
      Uri.parse(fetchMachineOrderEndpoint),
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
