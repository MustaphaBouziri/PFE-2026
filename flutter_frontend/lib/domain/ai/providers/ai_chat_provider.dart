import 'package:flutter/foundation.dart';
import '../../../data/ai/models/ai_chat_model.dart';
import '../../../data/ai/services/ai_chat_service.dart';

class AiChatProvider with ChangeNotifier {
  final AiChatService _service = AiChatService();

  final List<ConversationTurn> _history = [];
  List<ConversationTurn> get history => List.unmodifiable(_history);

  bool isLoading = false;
  String? errorMessage;
  AiChatResponse? lastResponse;

  Future<AiChatResponse?> sendMessage({
    required String message,
    required String userId,
    required String role,
    required List<String> workCenters,
    required String token,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    _history.add(ConversationTurn(role: 'user', content: message));

    try {
      final response = await _service.sendMessage(
        message: message,
        userId: userId,
        role: role,
        workCenters: workCenters,
        token: token,
        history: _history.length > 1
            ? _history.sublist(0, _history.length - 1)
            : [],
      );
      _history.add(ConversationTurn(role: 'assistant', content: response.text));
      lastResponse = response;
      isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      errorMessage = e.toString();
      _history.removeLast(); // remove the user message on failure
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void clearHistory() {
    _history.clear();
    lastResponse = null;
    errorMessage = null;
    notifyListeners();
  }
}