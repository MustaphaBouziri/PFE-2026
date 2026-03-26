import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/app_constants.dart';
import '../models/erp_order_model.dart';
import '../models/mes_operation_model.dart';
import '../models/mes_production_cycle.dart';

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
    String prodOrderNo,
    String operationNo,
    String machineNo,
  ) async {
    final body = jsonEncode({
      'prodOrderNo': prodOrderNo,
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

  // ── finish / cancel ──────────────────────────────────────────────────────

  /// Call when progress = 100 % — marks the operation as intentionally finished.
  Future<bool> finishOperation({
    required String machineNo,
    required String prodOrderNo,
    required String operationNo,
  }) async {
    return _setOperationStatus(
      url: AppConstants.finishOperationUrl,
      machineNo: machineNo,
      prodOrderNo: prodOrderNo,
      operationNo: operationNo,
    );
  }

  /// Call when progress < 100 % — marks the operation as cancelled.
  Future<bool> cancelOperation({
    required String machineNo,
    required String prodOrderNo,
    required String operationNo,
  }) async {
    return _setOperationStatus(
      url: AppConstants.cancelOperationUrl,
      machineNo: machineNo,
      prodOrderNo: prodOrderNo,
      operationNo: operationNo,
    );
  }

  Future<bool> pauseOperation({
    required String machineNo,
    required String prodOrderNo,
    required String operationNo,
  }) async {
    return _setOperationStatus(
      url: AppConstants.pauseOperationUrl,
      machineNo: machineNo,
      prodOrderNo: prodOrderNo,
      operationNo: operationNo,
    );
  }

  Future<bool> resumeOperation({
    required String machineNo,
    required String prodOrderNo,
    required String operationNo,
  }) async {
    return _setOperationStatus(
      url: AppConstants.resumeOperationUrl,
      machineNo: machineNo,
      prodOrderNo: prodOrderNo,
      operationNo: operationNo,
    );
  }

  Future<bool> _setOperationStatus({
    required String url,
    required String machineNo,
    required String prodOrderNo,
    required String operationNo,
  }) async {
    final body = jsonEncode({
      'machineNo': machineNo,
      'prodOrderNo': prodOrderNo,
      'operationNo': operationNo,
    });

    final response = await http.post(
      Uri.parse(url),
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
        'Request failed: ${response.statusCode} ${response.body}',
      );
    }
  }

  // ── existing methods below (unchanged) ───────────────────────────────────

  Future<List<OperationStatusAndProgressModel>>
  fetchMachineOperationStatusAndProgress(
    String machineNo,
    bool fetchFinished,
  ) async {
    final body = jsonEncode({
      'machineNo': machineNo,
      'fetchFinished': fetchFinished,
    });

    final response = await http.post(
      Uri.parse(AppConstants.fetchMachineOperationStatusAndProgress),
      headers: AppConstants.jsonHeaders,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final String valueString = data['value'] ?? '[]';
      final List<dynamic> list = jsonDecode(valueString);
      return list
          .map((e) => OperationStatusAndProgressModel.fromJson(e))
          .toList();
    } else {
      throw Exception(
        'Failed to fetch machine operations status and progress : ${response.statusCode}',
      );
    }
  }

  Stream<List<OperationStatusAndProgressModel>>
  streamMachinesOperationStatusAndProgress(
    String machineNo,
    bool fetchFinished, {
    Stream<void>? trigger,
  }) async* {
    while (true) {
      try {
        final data = await fetchMachineOperationStatusAndProgress(
          machineNo,
          fetchFinished,
        );
        yield data;
      } catch (e) {
        yield [];
      }

      // Wait for either the 5-second poll interval OR an on-demand refresh
      // trigger — whichever comes first — before fetching again.
      final delay = Future.delayed(const Duration(seconds: 5));
      if (trigger != null) {
        await Future.any([delay, trigger.first.catchError((_) {})]);
      } else {
        await delay;
      }
    }
  }

  Future<OperationStatusAndProgressModel?> fetchOperationLiveData(
    String machineNo,
    String prodOrderNo,
    String operationNo,
  ) async {
    final body = jsonEncode({
      'machineNo': machineNo,
      'prodOrderNo': prodOrderNo,
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
      return list.isNotEmpty
          ? OperationStatusAndProgressModel.fromJson(list.first)
          : null;
    } else {
      throw Exception(
        'Failed to fetch status and progress : ${response.statusCode}',
      );
    }
  }

  Stream<OperationStatusAndProgressModel?> streamFetchOperationLiveData(
    String machineNo,
    String prodOrderNo,
    String operationNo,
    Stream<void> trigger,
  ) async* {
    yield await fetchOperationLiveData(machineNo, prodOrderNo, operationNo);
    await for (final _ in trigger) {
      yield await fetchOperationLiveData(machineNo, prodOrderNo, operationNo);
    }
  }

  Future<bool> declareProduction(
    String prodOrderNo,
    String operationNo,
    String machineNo,
    double input,
  ) async {
    final body = jsonEncode({
      'prodOrderNo': prodOrderNo,
      'operationNo': operationNo,
      'machineNo': machineNo,
      'input': input,
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
      throw Exception(
        'Failed to declare production: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<List<ProductionCycleModel>> fetchProductionCycles(
    String machineNo,
    String prodOrderNo,
    String operationNo,
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
      throw Exception(
        'Failed to fetch production cycles: ${response.statusCode}',
      );
    }
  }

  Stream<List<ProductionCycleModel>> streamProductionCycles(
    String machineNo,
    String prodOrderNo,
    String operationNo,
    Stream<void> trigger,
  ) async* {
    yield await fetchProductionCycles(machineNo, prodOrderNo, operationNo);
    await for (final _ in trigger) {
      yield await fetchProductionCycles(machineNo, prodOrderNo, operationNo);
    }
  }

  
}
