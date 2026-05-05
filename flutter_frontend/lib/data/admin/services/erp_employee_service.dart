
import 'package:pfe_mes/data/shared/http_client.dart';
import 'package:pfe_mes/data/shared/http_response_parser.dart';

import '../../../core/app_constants.dart';
import '../models/erp_employees_model.dart';

class ErpEmployeeService {
Future<List<ErpEmployee>> fetchEmployees() async {
  final response =
      await HttpClient.post(AppConstants.fetchAllEmployees, {});

  return HttpResponseParser.parseList(
    response,
    label: 'Fetch all employees',
  )
      .map((json) => ErpEmployee.fromJson(json))
      .toList();
}
}
