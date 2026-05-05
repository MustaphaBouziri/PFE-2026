import 'dart:async';
import 'dart:convert';

import '../../../core/app_constants.dart';
import '../../shared/http_client.dart';
import '../../shared/http_response_parser.dart';
import '../models/mes_machine_model.dart';

class MESMachineListService {

 
  Future<Map<String, List<MachineModel>>> fetchOrderedMachinePerDepartments(
    List<String> workCenterNos,
  ) async {

final response = await HttpClient.post(
  AppConstants.fetchMachinesUrl,
  { 'workCenterNoJson': jsonEncode({ 'workCenterNos': workCenterNos }) },
);

    final List<dynamic> machinesList = HttpResponseParser.parseList(
      response,
      label: 'fetch machines',
    );

    final machines = machinesList
        .map((e) => MachineModel.fromJson(e))
        .toList();

    final Map<String, List<MachineModel>> grouped = {};

    for (final machine in machines) {
      grouped.putIfAbsent(machine.workCenterNo, () => []);
      grouped[machine.workCenterNo]!.add(machine);
    }

    return grouped;
  }

  Stream<Map<String, List<MachineModel>>>
      streamFetchOrderedMachinePerDepartments(
    List<String> workCenterList,
  ) async* {
    while (true) {
      yield await fetchOrderedMachinePerDepartments(workCenterList);
      await Future.delayed(const Duration(seconds: 20));
    }
  }
}