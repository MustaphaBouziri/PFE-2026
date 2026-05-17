// lib/data/admin/services/setting_service.dart
import 'package:pfe_mes/data/admin/models/settings_model.dart';
import '../../../core/app_constants.dart';
import '../../shared/http_client.dart';
import '../../shared/http_response_parser.dart';

class SettingService {
  Future<SettingModel> fetchSettings() async {
    final response = await HttpClient.post(AppConstants.fetchSettings, {});
    final settings = HttpResponseParser.parseObject(
      response,
      label: 'settings',
    );
    return SettingModel.fromJson(settings);
  }

  Future<void> updateSettings(SettingModel updated) async {
    await HttpClient.post(AppConstants.updateSettings, updated.toJson());
  }
}
