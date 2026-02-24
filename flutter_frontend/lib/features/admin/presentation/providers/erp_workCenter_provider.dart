import 'package:flutter/foundation.dart';
import 'package:pfe_mes/models/erp_workCenter_model.dart';
import 'package:pfe_mes/services/erp_workCenter_service.dart';

class ErpWorkcenterProvider with ChangeNotifier{
  final ErpWorkcenterService _service = ErpWorkcenterService();

  List<ErpWorkCenter> workCenters = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchWorkCenter () async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      workCenters= await _service.fetchWorkCenters();

      
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

}