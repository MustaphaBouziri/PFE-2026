// lib/data/admin/services/setting_service.dart
import 'package:pfe_mes/core/storage/session_storage.dart';
import 'package:pfe_mes/data/admin/models/settings_model.dart';
import '../../../core/app_constants.dart';
import '../../shared/http_client.dart';
import '../../shared/http_response_parser.dart';

class SettingService {
  final SessionStorage _sessionStorage = SessionStorage();

  Future<SettingModel> fetchSettings() async {
    final response = await HttpClient.post(AppConstants.fetchSettings, {});
    final settings = HttpResponseParser.parseObject(
      response,
      label: 'settings',
    );
    return SettingModel.fromJson(settings);
  }

  Future<void> updateSettings(SettingModel updated) async {
    final token = _sessionStorage.getToken();

    final response = await HttpClient.post(AppConstants.updateSettings, {
      'pwChangePeriodDays': int.tryParse(updated.pwChangePeriod.trim()),
      'twoFAEnabled': updated.twoFAEnabled,
      'token': token,
    });

    final data = HttpResponseParser.parseSuccess(response);

  }
}
