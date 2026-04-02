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
          /**
            [
    MachineModel(machineNo: "M1", machineName: "CNC 1", workCenterNo: "100", workCenterName: "Assembly"),
    MachineModel(machineNo: "M2", machineName: "CNC 2", workCenterNo: "100", workCenterName: "Assembly"),
  ]
          */
    } else {
      throw Exception(
        'Failed to fetch machines: ${response.statusCode} ${response.body}',
      );
    }
  }
  //fetchOrderedMachinePerDepartments(["100", "200"])
  Future<Map<String, List<MachineModel>>> fetchOrderedMachinePerDepartments(
  List<String> workCenterNos,
) async {
  final Map<String, List<MachineModel>> orderedMachinePerDepartment = {};

  for (final wc in workCenterNos) {
    //first iteration -> calls fetchMachines("100") -> gets list of machines -> stores under key "100"
    final machines = await fetchMachines(wc);
    orderedMachinePerDepartment[wc] = machines;
  }
  /**
    {
    "100": [MachineModel(...), MachineModel(...)],
    "200": [MachineModel(...), MachineModel(...)],
  }
  */

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
