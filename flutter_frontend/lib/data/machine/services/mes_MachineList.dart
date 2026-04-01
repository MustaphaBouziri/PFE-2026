import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/app_constants.dart';
import '../models/mes_machine_model.dart';

class MESMachineListService {
  Future<List<MachineModel>> fetchMachines(String workCenterNo) async {
    final body = jsonEncode({'workCenterNo': workCenterNo});
    final response = await http.post(
      Uri.parse(AppConstants.fetchMachinesUrl),
      headers: AppConstants.jsonHeaders,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final String valueString = data['value'] ?? '[]';

      final List<dynamic> machinesList = jsonDecode(valueString);

      return machinesList
          .map((machine) => MachineModel.fromJson(machine))
          .toList();
    } else {
      throw Exception(
        'Failed to fetch machines: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<Map<String, List<MachineModel>>> fetchOrderedMachinePerDepartments(
  List<String> workCenterNos,
) async {
  final Map<String, List<MachineModel>> orderedMachinePerDepartment = {};

  for (final wc in workCenterNos) {
    final machines = await fetchMachines(wc);
    orderedMachinePerDepartment[wc] = machines;
  }

  return orderedMachinePerDepartment;
}

  Stream<Map<String, List<MachineModel>>> streamFetchOrderedMachinePerDepartments(
  List<String> workCenterList,
) async* {
  while (true) {
    try {
      final data = await fetchOrderedMachinePerDepartments(workCenterList);
      yield data;
    } catch (e) {
      yield {};
    }
    await Future.delayed(const Duration(seconds: 5));
  }
}
}
