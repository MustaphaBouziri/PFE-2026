import 'package:pfe_mes/data/admin/models/mes_log_model.dart';

import '../../../core/app_constants.dart';
import '../../shared/http_client.dart';
import '../../shared/http_response_parser.dart';

class LogService {
  Future<List<ActivityLogModel>> fetchActivityLog(int hoursBack) async {
    final response = await HttpClient.post(
        AppConstants.fetchActivityLog,
        {'hoursBack': hoursBack.toDouble()}
    );

    final list = HttpResponseParser.parseList(response, label: 'activity log');
    return list.map((e) => ActivityLogModel.fromJson(e)).toList();
  }

  Future<List<MachineDashboardModel>> fetchMachineDashboard(
    int hoursBack,
  ) async {
    final response = await HttpClient.post(
        AppConstants.fetchMachineDashboard,
        {'hoursBack':  hoursBack.toDouble()},
    );

    final list = HttpResponseParser.parseList(
      response,
      label: 'machine dashboard',
    );
    return list.map((e) => MachineDashboardModel.fromJson(e)).toList();
  }
}
