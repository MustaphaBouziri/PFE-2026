import 'package:flutter/foundation.dart';
import 'package:pfe_mes/models/erp_employees_model.dart';
import 'package:pfe_mes/services/erp_employee_service.dart';

class ErpEmployeeProvider with ChangeNotifier{
  final ErpEmployeeService _service = ErpEmployeeService();

  List<ErpEmployee> employees = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchEmployees () async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      employees= await _service.fetchEmployees();

      
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

}