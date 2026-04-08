import 'package:flutter/material.dart';

import '../../../../data/auth/services/api_service.dart';
import '../../../../data/machine/barCode/models/mes_barCode_model.dart';
import '../../../../data/machine/barCode/services/mes_barCode_service.dart';

/// Provides barcode data and scan-submission actions to the UI.
/// insertScans retrieves the current session token before calling the
/// service so the backend can attribute each scan to the correct MES user.
class MesBarcodeProvider with ChangeNotifier {
  final MesBarcodeService _service = MesBarcodeService();
  final ApiService _apiService = ApiService();

  List<ItemBarcodeModel> barcodes = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchAllBarcodes() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      barcodes = await _service.fetchAllBarcodes();
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  /// Submits [scans] for [executionId].
  /// Resolves the session token automatically.
  Future<bool> insertScans(
    String executionId,
    List<Map<String, dynamic>> scans
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final token = await _apiService.getToken() ?? '';
      return await _service.insertScans(
        token,
        executionId,
        scans,
      );
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
