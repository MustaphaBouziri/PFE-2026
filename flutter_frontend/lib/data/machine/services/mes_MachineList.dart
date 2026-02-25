import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
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

  Stream<List<MachineModel>> streamMachines(String workCenterNo) async* {
    while (true) {
      // yes we create an infinit loop cuz stream wont stop
      try {
        // fetchMachine function know how to call the api
        // streamMachine need to call that api evry 5 sec
        // so stream will say :ok every 5 seconds i will call fetchMachines and send the result evry 5 sec "
        final machines = await fetchMachines(workCenterNo);
        yield machines; //Send this value to whoever is listening. in my case its the stream builder snapshot .data
      } catch (e) {
        yield [];
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }
}
