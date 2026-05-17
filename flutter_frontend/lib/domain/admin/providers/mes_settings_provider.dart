// lib/presentation/admin/providers/mes_settings_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/admin/models/settings_model.dart';
import '../../../data/admin/services/setting_service.dart';
import '../../shared/async_state_mixin.dart';

class MesSettingsProvider with ChangeNotifier, AsyncStateMixin {
  final SettingService _service = SettingService();
  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  SettingModel? settings;
  bool isSaving = false;
  String? saveError;
  bool saveSuccess = false;

  void triggerRefresh() => _refreshController.add(());

  @override
  void dispose() {
    _refreshController.close();
    super.dispose();
  }

  Future<void> fetchSettings() async {
    await runAsync(() async {
      settings = await _service.fetchSettings();
    });
    notifyListeners();
  }

  Future<bool> updateSettings(String newPeriod) async {
    if (settings == null) return false;
    isSaving = true;
    saveError = null;
    saveSuccess = false;
    notifyListeners();

    try {
      final updated = settings!.copyWith(pwChangePeriod: newPeriod);
      await _service.updateSettings(updated);
      settings = updated;
      saveSuccess = true;
      return true;
    } catch (e) {
      saveError = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}