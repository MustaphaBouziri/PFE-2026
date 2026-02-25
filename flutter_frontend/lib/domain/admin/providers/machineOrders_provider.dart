import 'package:flutter/material.dart';

import '../../../data/admin/models/erp_order_model.dart';
import '../../../data/auth/services/erp_order_service.dart';

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
}
