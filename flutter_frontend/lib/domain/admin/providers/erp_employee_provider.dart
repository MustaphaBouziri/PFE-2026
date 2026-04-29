import 'package:flutter/foundation.dart';
import 'package:pfe_mes/data/admin/models/erp_employees_model.dart';
import 'package:pfe_mes/data/admin/services/erp_employee_service.dart';
import 'package:pfe_mes/domain/shared/async_state_mixin.dart';

class ErpEmployeeProvider with ChangeNotifier, AsyncStateMixin {
  final ErpEmployeeService _service = ErpEmployeeService();

  List<ErpEmployee> employees = [];

  Future<void> fetchEmployees() async {
    await runAsync(() async {
      employees = await _service.fetchEmployees();
    });
  }
  
}
