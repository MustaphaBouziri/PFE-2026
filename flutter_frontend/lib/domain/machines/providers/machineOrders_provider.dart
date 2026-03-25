import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/machine/models/erp_order_model.dart';
import '../../../data/machine/models/mes_operation_model.dart';
import '../../../data/machine/models/mes_production_cycle.dart';
import '../../../data/machine/services/erp_order_service.dart';

class MachineordersProvider with ChangeNotifier {
  final ErpMachineOrdersService _service = ErpMachineOrdersService();

  List<MachineOrderModel> machineOrders = [];
  List<MachineOrderModel> machineOrdersHistory = [];
  bool isLoading = false;
  String? errorMessage;

  final StreamController<void> _refreshController =
  StreamController<void>.broadcast();

  void triggerRefresh() {
    _refreshController.add(());
  }

  @override
  void dispose() {
    _refreshController.close();
    super.dispose();
  }

  Future<void> getMachineOrders(String machineNo) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      machineOrders = await _service.getMachineOrders(machineNo);
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> startOrder(
      String prodOrderNo,
      String operationNo,
      String machineNo,
      ) async {
    final result = await _service.getStartOperationValidation(
      prodOrderNo,
      operationNo,
      machineNo,
    );
    return result;
  }

  // ── finish / cancel ────────────────────────────────────────────────────────

  /// Called when progress = 100 %.
  Future<bool> finishOperation({
    required String machineNo,
    required String prodOrderNo,
    required String operationNo,
  }) async {
    final result = await _service.finishOperation(
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
    final result = await _service.pauseOperation(
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
    final result = await _service.resumeOperation(
      machineNo: machineNo,
      prodOrderNo: prodOrderNo,
      operationNo: operationNo,
    );
    triggerRefresh();
    return result;
  }


  /// Called when progress < 100 %.
  Future<bool> cancelOperation({
    required String machineNo,
    required String prodOrderNo,
    required String operationNo,
  }) async {
    final result = await _service.cancelOperation(
      machineNo: machineNo,
      prodOrderNo: prodOrderNo,
      operationNo: operationNo,
    );
    triggerRefresh();
    return result;
  }

  // ── existing stream methods (unchanged) ───────────────────────────────────

  Stream<List<OperationStatusAndProgressModel>>
  getMachineOperationStatusAndProgressStream(
      String machineNo, bool fetchFinished) {
    return _service.streamMachinesOperationStatusAndProgress(
        machineNo, fetchFinished);
  }

  Future<List<OperationStatusAndProgressModel>> fetchMachineHistory(
      String machineNo) async {
    return await _service.fetchMachineOperationStatusAndProgress(machineNo, true);
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

  Future<bool> declareProduction(
      String prodOrderNo,
      String operationNo,
      String machineNo,
      double input,
      ) async {
    final result = await _service.declareProduction(
      prodOrderNo,
      operationNo,
      machineNo,
      input,
    );
    triggerRefresh();
    return result;
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
