import 'dart:async';

import '../../../core/app_constants.dart';
import '../../shared/http_client.dart';
import '../../shared/http_response_parser.dart';
import '../models/mes_machine_model.dart';

class MESMachineListService {
  Future<List<MachineModel>> fetchMachines(String workCenterNo) async {
    final response = await HttpClient.post(AppConstants.fetchMachinesUrl, {
      'workCenterNo': workCenterNo,
    });

    final List<dynamic> machinesList = HttpResponseParser.parseList(
      response,
      label: 'fetch machines',
    );

    return machinesList
        .map((machine) => MachineModel.fromJson(machine))
        .toList();
    /**
        [
        MachineModel(machineNo: "M1", machineName: "CNC 1", workCenterNo: "100", workCenterName: "Assembly"),
        MachineModel(machineNo: "M2", machineName: "CNC 2", workCenterNo: "100", workCenterName: "Assembly"),
        ]
     **/
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

 Stream<Map<String, List<MachineModel>>>
streamFetchOrderedMachinePerDepartments(List<String> workCenterList) async* {
  while (true) {
    yield await fetchOrderedMachinePerDepartments(workCenterList);
    await Future.delayed(const Duration(seconds: 20));
  }
}
}



