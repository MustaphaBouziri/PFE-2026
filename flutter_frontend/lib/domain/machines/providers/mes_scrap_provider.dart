import 'package:flutter/foundation.dart';

import '../../../data/auth/services/api_service.dart';
import '../../../data/machine/models/mes_scrapCode_model.dart';
import '../../../data/machine/services/mes_scrap_service.dart';

/// Provides scrap-code data and scrap-declaration actions to the UI.
/// declareScrap retrieves the current session token before calling the
/// service so the backend knows which MES user performed the action.
class MesScrapProvider with ChangeNotifier {
  final MesScrapService _service = MesScrapService();
  final ApiService _apiService = ApiService();

  List<MesScrapCode> scrapCodes = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchScrapCodes() async {
    if (scrapCodes.isNotEmpty) return; // serve from cache
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      scrapCodes = await _service.fetchScrapCodes();
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  /// Declares scrapped units for [executionId].
  /// Resolves the session token automatically.
  Future<bool> declareScrap({
    required String executionId,
    required String scrapCode,
    required double quantity,
    String description = '',
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final token = await _apiService.getToken() ?? '';
      return await _service.declareScrap(
        token: token,
        executionId: executionId,
        scrapCode: scrapCode,
        quantity: quantity,
        description: description,
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
