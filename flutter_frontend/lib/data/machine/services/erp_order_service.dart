import 'dart:convert';


import 'package:http/http.dart' as http;
import 'package:pfe_mes/data/machine/models/mes_production_cycle.dart';

import '../../../core/app_constants.dart';
import '../models/erp_order_model.dart';
import '../models/mes_operation_model.dart';

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
      throw Exception(
        'Failed to start operation: ${response.statusCode} ${response.body}',
      );
    }
  }

 /* //____________fetch machine operation status monitoring

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
  // need to change the stream name

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
  */

  Future<List<OperationStatusAndProgressModel>> fetchMachineOperationStatusAndProgress(
    String machineNo,
  ) async {

    final body = jsonEncode({'machineNo': machineNo});

    final response = await http.post(
      Uri.parse(AppConstants.fetchMachineOperationStatusAndProgress),
      headers: AppConstants.jsonHeaders,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final String valueString = data['value'] ?? '[]';

      final List<dynamic> machineOperationStatusAndProgressList = jsonDecode(valueString);

      return machineOperationStatusAndProgressList
          .map((operationStatusAndProgress) => OperationStatusAndProgressModel.fromJson(operationStatusAndProgress))
          .toList();
    } else {
      throw Exception(
        'Failed to fetch machine operations status and progress : ${response.statusCode}',
      );
    }
  }

  // __________________ STREAM __________________


  Stream<List<OperationStatusAndProgressModel>> streamMachinesOperationStatusAndProgress(String machineNo) async* {
    while (true) {
      try {
        final machineOperationsStatusAndProgress = await fetchMachineOperationStatusAndProgress(
          machineNo,
        );

        yield machineOperationsStatusAndProgress;
      } catch (e) {
        yield [];
      }

      await Future.delayed(const Duration(seconds: 5));
    }
  }
  //________________________________fetch + stream live data for a specific operation

  Future<OperationStatusAndProgressModel?> fetchOperationLiveData(
  String machineNo, String prodOderNo, String operationNo
) async {
  final body = jsonEncode({
    'machineNo': machineNo,
    'prodOderNo': prodOderNo,
    'operationNo': operationNo,
  });

  final response = await http.post(
    Uri.parse(AppConstants.fetchOperationLiveData),
    headers: AppConstants.jsonHeaders,
    body: body,
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final String valueString = data['value'] ?? '[]';
    final List<dynamic> list = jsonDecode(valueString);

    // list.first bc return an array and we only need the first one after all it's basily one operation will be returned
    return list.isNotEmpty
        ? OperationStatusAndProgressModel.fromJson(list.first)
        : null;
  } else {
    throw Exception('Failed to fetch status and progress : ${response.statusCode}');
  }
}

Stream<OperationStatusAndProgressModel?> streamFetchOperationLiveData(
  String machineNo, String prodOderNo, String operationNo, Stream<void> trigger) async* {
  yield await fetchOperationLiveData(machineNo, prodOderNo, operationNo);
  await for (final _ in trigger) {
    yield await fetchOperationLiveData(machineNo, prodOderNo, operationNo);
  }
}


//_________declaire production _______________

Future<bool> declareProduction(
    String prodOderNo,
    String operationNo,
    String machineNo,
    double input,
  ) async {
    final body = jsonEncode({
      'prodOderNo': prodOderNo,
      'operationNo': operationNo,
      'machineNo': machineNo,
      'input':input
    });

    final response = await http.post(
      Uri.parse(AppConstants.declareProduction),
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
      throw Exception('Failed to declaire production: ${response.statusCode} ${response.body}');
    }
  }

//___________fetch production cycle ________
Future<List<ProductionCycleModel>> fetchProductionCycles(
  String machineNo, String prodOrderNo, String operationNo
) async {
  final body = jsonEncode({
    'machineNo': machineNo,
    'prodOrderNo': prodOrderNo,
    'operationNo': operationNo,
  });

  final response = await http.post(
    Uri.parse(AppConstants.fetchProductionCycles),
    headers: AppConstants.jsonHeaders,
    body: body,
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final String valueString = data['value'] ?? '[]';
    final List<dynamic> list = jsonDecode(valueString);
    return list.map((e) => ProductionCycleModel.fromJson(e)).toList();
  } else {
    throw Exception('Failed to fetch production cycles: ${response.statusCode}');
  }
}

Stream<List<ProductionCycleModel>> streamProductionCycles(
  String machineNo, String prodOrderNo, String operationNo, Stream<void> trigger) async* {
  yield await fetchProductionCycles(machineNo, prodOrderNo, operationNo);
  await for (final _ in trigger) {
    yield await fetchProductionCycles(machineNo, prodOrderNo, operationNo);
  }
}
}
