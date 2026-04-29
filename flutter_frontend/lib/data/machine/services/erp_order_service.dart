import 'package:pfe_mes/core/storage/session_storage.dart';

import '../../../core/app_constants.dart';
import '../../shared/http_client.dart';
import '../../shared/http_response_parser.dart';
import '../models/erp_order_model.dart';
import '../models/mes_operation_model.dart';
import '../models/mes_production_cycle.dart';

/// Handles all machine-order related API calls.
/// Write operations (start/finish/cancel/pause/resume/declareProduction)
/// require the session token so the BC backend can resolve the MES user
/// from the token instead of the BC Windows session.
class ErpMachineOrdersService {
  final SessionStorage _sessionStorage =SessionStorage();
  /// Fetches all pending production orders assigned to [machineNo].
  Future<List<MachineOrderModel>> getMachineOrders(String machineNo) async {
    final response = await HttpClient.post(AppConstants.getMachineOrdersUrl, {
      'machineNo': machineNo,
    });

    final list = HttpResponseParser.parseList(
      response,
      label: 'fetch machine orders',
    );
    return list.map((e) => MachineOrderModel.fromJson(e)).toList();
  }

  /// Starts [operationNo] on [machineNo] for [prodOrderNo].
  /// [token] — session token from the authenticated user.
  Future<bool> startOperation(
    String prodOrderNo,
    String operationNo,
    String machineNo,
  ) async {
    final token = _sessionStorage.getToken();
    final response = await HttpClient.post(AppConstants.startOperation, {
      'token': token,
      'prodOrderNo': prodOrderNo,
      'operationNo': operationNo,
      'machineNo': machineNo,
    });

    return HttpResponseParser.parseWriteResult(
      response,
      label: 'start operation',
    );
  }

  /// Marks the operation as Finished.
  Future<bool> finishOperation({
    required String machineNo,
    required String prodOrderNo,
    required String operationNo,
  }) => _setOperationStatus(
    url: AppConstants.finishOperationUrl,
    machineNo: machineNo,
    prodOrderNo: prodOrderNo,
    operationNo: operationNo,
  );

  /// Marks the operation as Cancelled.
  Future<bool> cancelOperation({
    required String machineNo,
    required String prodOrderNo,
    required String operationNo,
  }) => _setOperationStatus(
    url: AppConstants.cancelOperationUrl,
    machineNo: machineNo,
    prodOrderNo: prodOrderNo,
    operationNo: operationNo,
  );

  /// Pauses a running operation.
  Future<bool> pauseOperation({
    required String machineNo,
    required String prodOrderNo,
    required String operationNo,
  }) => _setOperationStatus(
    url: AppConstants.pauseOperationUrl,
    machineNo: machineNo,
    prodOrderNo: prodOrderNo,
    operationNo: operationNo,
  );

  /// Resumes a paused operation.
  Future<bool> resumeOperation({
    required String machineNo,
    required String prodOrderNo,
    required String operationNo,
  }) => _setOperationStatus(
    url: AppConstants.resumeOperationUrl,
    machineNo: machineNo,
    prodOrderNo: prodOrderNo,
    operationNo: operationNo,
  );

  /// Shared POST helper for status-transition endpoints.
  Future<bool> _setOperationStatus({
    required String url,
    required String machineNo,
    required String prodOrderNo,
    required String operationNo,
  }) async {
    final token = _sessionStorage.getToken();
    final response = await HttpClient.post(url, {
      'token': token,
      'machineNo': machineNo,
      'prodOrderNo': prodOrderNo,
      'operationNo': operationNo,
    });

    return HttpResponseParser.parseWriteResult(
      response,
      label: 'operation status update',
    );
  }

  // ──────────────────────────────────────────────
  // Read-only endpoints (no token change needed)
  // ──────────────────────────────────────────────

  Future<List<OperationStatusAndProgressModel>> fetchOngoingOperationsState(
    String machineNo,
  ) async {
    final response = await HttpClient.post(
      AppConstants.fetchOngoingOperationsState,
      {'machineNo': machineNo},
    );

    final list = HttpResponseParser.parseList(
      response,
      label: 'fetch operations',
    );
    return list
        .map((e) => OperationStatusAndProgressModel.fromJson(e))
        .toList();
  }

  Future<List<OperationStatusAndProgressModel>> fetchOperationsHistory(
    String machineNo,
  ) async {
    final response = await HttpClient.post(
      AppConstants.fetchOperationsHistory,
      {'machineNo': machineNo},
    );

    final list = HttpResponseParser.parseList(
      response,
      label: 'fetch operations',
    );
    return list
        .map((e) => OperationStatusAndProgressModel.fromJson(e))
        .toList();
  }

  Stream<List<OperationStatusAndProgressModel>>
  streamMachinesOngoingOperationsState(
    String machineNo, {
    Stream<void>? trigger,
  }) async* {
    while (true) {
      try {
        yield await fetchOngoingOperationsState(machineNo);
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
    final response = await HttpClient.post(
      AppConstants.fetchOperationLiveData,
      {
        'machineNo': machineNo,
        'prodOrderNo': prodOrderNo,
        'operationNo': operationNo,
      },
    );

    final list = HttpResponseParser.parseList(
      response,
      label: 'fetch live data',
    );
    return list.isNotEmpty
        ? OperationStatusAndProgressModel.fromJson(list.first)
        : null;
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
    String prodOrderNo,
    String operationNo,
    String machineNo,
    double input,
    String onBehalfOfUserId,
  ) async {
    final token = _sessionStorage.getToken();
    final response = await HttpClient.post(AppConstants.declareProduction, {
      'token': token,
      'prodOrderNo': prodOrderNo,
      'operationNo': operationNo,
      'machineNo': machineNo,
      'input': input,
      'onBehalfOfUserId': onBehalfOfUserId,
    });

    return HttpResponseParser.parseWriteResult(
      response,
      label: 'declare production',
    );
  }

  Future<List<ProductionCycleModel>> fetchProductionCycles(
    String machineNo,
    String prodOrderNo,
    String operationNo,
  ) async {
    final response = await HttpClient.post(AppConstants.fetchProductionCycles, {
      'machineNo': machineNo,
      'prodOrderNo': prodOrderNo,
      'operationNo': operationNo,
    });

    final list = HttpResponseParser.parseList(response, label: 'fetch cycles');
    return list.map((e) => ProductionCycleModel.fromJson(e)).toList();
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
