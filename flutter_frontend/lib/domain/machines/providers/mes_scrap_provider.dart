import 'package:flutter/foundation.dart';
import '../../../data/machine/models/mes_scrapCode_model.dart';
import '../../../data/machine/services/mes_scrap_service.dart';

class MesScrapProvider with ChangeNotifier {
  final MesScrapService _service = MesScrapService();

  List<MesScrapCode> scrapCodes = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchScrapCodes() async {
    if (scrapCodes.isNotEmpty) return; // cached — don't re-fetch
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
      final result = await _service.declareScrap(
        executionId: executionId,
        scrapCode: scrapCode,
        quantity: quantity,
        description: description,
      );
      return result;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}