import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/storage/session_storage.dart';
import '../../../data/auth/services/api_service.dart';
import '../../../data/machine/models/erp_order_model.dart';
import '../../../data/machine/models/mes_operation_model.dart';
import '../../../data/machine/models/mes_production_cycle.dart';
import '../../../data/machine/services/erp_order_service.dart';
import '../../shared/async_state_mixin.dart';

/// Provides machine-order state to the UI layer.
/// All write operations retrieve the current session token via [ApiService]
/// and forward it to the service layer, which includes it in the request body
/// so the BC backend can resolve the MES user identity from the token.
class MachineordersProvider with ChangeNotifier, AsyncStateMixin {
  final ErpMachineOrdersService _service = ErpMachineOrdersService();
  final SessionStorage _sessionStorage = SessionStorage();

  List<MachineOrderModel> machineOrders = [];

  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  void triggerRefresh() => _refreshController.add(());

  @override
  void dispose() {
    _refreshController.close();
    super.dispose();
  }

  Future<void> getMachineOrders(String machineNo) async {
    await runAsync(() async {
      machineOrders = await _service.getMachineOrders(machineNo);
    });
  }

  /// Resolves the current token; throws if the session has expired.
  Future<String> _requireToken() async {
    final token = await _sessionStorage.getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated');
    return token;
  }

  Future<bool> startOrder(
    String prodOrderNo,
    String operationNo,
    String machineNo,
  ) async {
    final token = await _requireToken();
    return _service.startOperation(token, prodOrderNo, operationNo, machineNo);
  }

  Future<bool> finishOperation({
    required String machineNo,
    required String prodOrderNo,
    required String operationNo,
  }) async {
    final token = await _requireToken();
    final result = await _service.finishOperation(
      token: token,
      machineNo: machineNo,
      prodOrderNo: prodOrderNo,
      operationNo: operationNo,
    );
    triggerRefresh();
    return result;
  }

  Future<bool> cancelOperation({
    required String machineNo,
    required String prodOrderNo,
    required String operationNo,
  }) async {
    final token = await _requireToken();
    final result = await _service.cancelOperation(
      token: token,
      machineNo: machineNo,
      prodOrderNo: prodOrderNo,
      operationNo: operationNo,
    );
    triggerRefresh();
    return result;
  }

  Future<bool> pauseOperation({
    required String machineNo,
    required String prodOrderNo,
    required String operationNo,
  }) async {
    final token = await _requireToken();
    final result = await _service.pauseOperation(
      token: token,
      machineNo: machineNo,
      prodOrderNo: prodOrderNo,
      operationNo: operationNo,
    );
    triggerRefresh();
    return result;
  }

  Future<bool> resumeOperation({
    required String machineNo,
    required String prodOrderNo,
    required String operationNo,
  }) async {
    final token = await _requireToken();
    final result = await _service.resumeOperation(
      token: token,
      machineNo: machineNo,
      prodOrderNo: prodOrderNo,
      operationNo: operationNo,
    );
    triggerRefresh();
    return result;
  }

  Future<bool> declareProduction(
    String prodOrderNo,
    String operationNo,
    String machineNo,
    double input,
    String onBehalfOfUserId,
  ) async {
    final token = await _requireToken();
    final result = await _service.declareProduction(
      token,
      prodOrderNo,
      operationNo,
      machineNo,
      input,
      onBehalfOfUserId,
    );
    triggerRefresh();
    return result;
  }

  // ── Read-only streams (no token needed) ──────────────────────────────────

  Stream<List<OperationStatusAndProgressModel>>
  getMachineOngoingOperationsStateStream(String machineNo) {
    return _service.streamMachinesOngoingOperationsState(
      machineNo,
      trigger: _refreshController.stream,
    );
  }

  Future<List<OperationStatusAndProgressModel>> fetchMachineHistory(
    String machineNo,
  ) {
    return _service.fetchOperationsHistory(machineNo);
  }

  Stream<OperationStatusAndProgressModel?> fetchOperationLiveDataStream(
    String machineNo,
    String prodOrderNo,
    String operationNo,
  ) {
    return _service.streamFetchOperationLiveData(
      machineNo,
      prodOrderNo,
      operationNo,
      _refreshController.stream,
    );
  }

  Stream<List<ProductionCycleModel>> fetchProductionCyclesStream(
    String machineNo,
    String prodOrderNo,
    String operationNo,
  ) {
    return _service.streamProductionCycles(
      machineNo,
      prodOrderNo,
      operationNo,
      _refreshController.stream,
    );
  }
}
