
import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/mes_operation_model.dart';

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
//________________machine operations status stream __________



 /* Stream<List<OperationStatusAndProgressModel>>  getMachineOperationsStatusStream(String machineNo) {
    return _service.streamMachinesOperationStatusAndProgress(machineNo);
  }*/

   Stream<List<OperationStatusAndProgressModel>>  getMachineOperationStatusAndProgressStream(String machineNo) {
    return _service.streamMachinesOperationStatusAndProgress(machineNo);
  }

  Stream<OperationStatusAndProgressModel?>  fetchOperationLiveDataStream(String machineNo,String prodOderNo,String operationNo) {
    return _service.streamFetchOperationLiveData(machineNo, prodOderNo, operationNo);
  }

  //_______declaire Production 
  Future<bool> declareProduction(
  String prodOderNo,
  String operationNo,
  String machineNo,
  double input
) async {
  final result = await _service.declareProduction(prodOderNo, operationNo, machineNo, input);
  

  return result;
}
}
