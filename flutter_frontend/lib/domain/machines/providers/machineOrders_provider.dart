import 'package:flutter/material.dart';

import '../../../data/machine/models/erp_order_model.dart';
import '../../../data/machine/services/erp_order_service.dart';

class MachineordersProvider with ChangeNotifier {
  final ErpMachineOrdersService _service = ErpMachineOrdersService();

  List<MachineOrderModel> machineOrders = [];
  bool isLoading = false;
  String? errorMessage;

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
  String prodOderNo,
  String operationNo,
  String machineNo,
) async {
  final result = await _service.getStartOperationValidation(
    prodOderNo,
    operationNo,
    machineNo,
  );

  return result;
}
}
