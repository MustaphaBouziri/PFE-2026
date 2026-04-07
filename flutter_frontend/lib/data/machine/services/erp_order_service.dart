import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/app_constants.dart';
import '../models/erp_order_model.dart';
import '../models/mes_operation_model.dart';
import '../models/mes_production_cycle.dart';

/// Handles all machine-order related API calls.
/// Write operations (start/finish/cancel/pause/resume/declareProduction)
/// require the session token so the BC backend can resolve the MES user
/// from the token instead of the BC Windows session.
class ErpMachineOrdersService {
  /// Fetches all pending production orders assigned to [machineNo].
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
      final List<dynamic> list = jsonDecode(valueString);
      return list.map((e) => MachineOrderModel.fromJson(e)).toList();
    }
    throw Exception(
      'Failed to fetch machine orders: ${response.statusCode} ${response.body}',
    );
  }

  /// Starts [operationNo] on [machineNo] for [prodOrderNo].
  /// [token] — session token from the authenticated user.
  Future<bool> getStartOperationValidation(
    String token,
    String prodOrderNo,
    String operationNo,
    String machineNo,
  ) async {
    final body = jsonEncode({
      'token': token,
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
      final outer = jsonDecode(response.body);
      final inner = jsonDecode(outer['value']);
      if (inner['value'] == true) return true;
      throw Exception(inner['message'] ?? 'Unknown error');
    }
    throw Exception(
      'Failed to start operation: ${response.statusCode} ${response.body}',
    );
  }

  /// Marks the operation as Finished.
  Future<bool> finishOperation({
    required String token,
    required String machineNo,
    required String prodOrderNo,
    required String operationNo,
  }) => _setOperationStatus(
    url: AppConstants.finishOperationUrl,
    token: token,
    machineNo: machineNo,
    prodOrderNo: prodOrderNo,
    operationNo: operationNo,
  );

  /// Marks the operation as Cancelled.
  Future<bool> cancelOperation({
    required String token,
    required String machineNo,
    required String prodOrderNo,
    required String operationNo,
  }) => _setOperationStatus(
    url: AppConstants.cancelOperationUrl,
    token: token,
    machineNo: machineNo,
    prodOrderNo: prodOrderNo,
    operationNo: operationNo,
  );

  /// Pauses a running operation.
  Future<bool> pauseOperation({
    required String token,
    required String machineNo,
    required String prodOrderNo,
    required String operationNo,
  }) => _setOperationStatus(
    url: AppConstants.pauseOperationUrl,
    token: token,
    machineNo: machineNo,
    prodOrderNo: prodOrderNo,
    operationNo: operationNo,
  );

  /// Resumes a paused operation.
  Future<bool> resumeOperation({
    required String token,
    required String machineNo,
    required String prodOrderNo,
    required String operationNo,
  }) => _setOperationStatus(
    url: AppConstants.resumeOperationUrl,
    token: token,
    machineNo: machineNo,
    prodOrderNo: prodOrderNo,
    operationNo: operationNo,
  );

  /// Shared POST helper for status-transition endpoints.
  Future<bool> _setOperationStatus({
    required String url,
    required String token,
    required String machineNo,
    required String prodOrderNo,
    required String operationNo,
  }) async {
    final body = jsonEncode({
      'token': token,
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
      final outer = jsonDecode(response.body);
      final inner = jsonDecode(outer['value']);
      if (inner['value'] == true) return true;
      throw Exception(inner['message'] ?? 'Unknown error');
    }
    throw Exception('Request failed: ${response.statusCode} ${response.body}');
  }

  // ──────────────────────────────────────────────
  // Read-only endpoints (no token change needed)
  // ──────────────────────────────────────────────

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
    }
    throw Exception('Failed to fetch operations: ${response.statusCode}');
  }

  Stream<List<OperationStatusAndProgressModel>>
  streamMachinesOperationStatusAndProgress(
    String machineNo,
    bool fetchFinished, {
    Stream<void>? trigger,
  }) async* {
    while (true) {
      try {
        yield await fetchMachineOperationStatusAndProgress(
          machineNo,
          fetchFinished,
        );
      } catch (_) {
        yield [];
      }
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
    }
    throw Exception('Failed to fetch live data: ${response.statusCode}');
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

  /// Declares [input] produced units for the given operation.
  /// [token] — session token from the authenticated user.
  Future<bool> declareProduction(
    String token,
    String prodOrderNo,
    String operationNo,
    String machineNo,
    double input,
    String onBehalfOfUserId,
  ) async {
    final body = jsonEncode({
      'token': token,
      'prodOrderNo': prodOrderNo,
      'operationNo': operationNo,
      'machineNo': machineNo,
      'input': input,
      'onBehalfOfUserId': onBehalfOfUserId,
    });

    final response = await http.post(
      Uri.parse(AppConstants.declareProduction),
      headers: AppConstants.jsonHeaders,
      body: body,
    );

    if (response.statusCode == 200) {
      final outer = jsonDecode(response.body);
      final inner = jsonDecode(outer['value']);
      if (inner['value'] == true) return true;
      throw Exception(inner['message'] ?? 'Unknown error');
    }
    throw Exception(
      'Failed to declare production: ${response.statusCode} ${response.body}',
    );
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
    }
    throw Exception('Failed to fetch cycles: ${response.statusCode}');
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
