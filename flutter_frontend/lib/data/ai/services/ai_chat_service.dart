import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pfe_mes/core/storage/session_storage.dart';
import '../../../core/app_constants.dart';
import '../models/ai_chat_model.dart';

class AiChatService {
  final SessionStorage _sessionStorage = SessionStorage();
  Future<AiChatResponse> sendMessage({
    required String message,
    List<ConversationTurn> history = const [],
  }) async {
    final token = _sessionStorage.getToken();
    final userId = _sessionStorage.getUserId();
    final role = _sessionStorage.getRole();
    final workCenters = _sessionStorage.getWorkCenters();

    final body = jsonEncode({
      'message': message,
      'user_context': {
        'user_id': userId,
        'role': role,
        'work_centers': workCenters,
        'token': token,
      },
      'conversation_history': history.map((t) => t.toJson()).toList(),
    });

    final response = await http.post(
      Uri.parse(AppConstants.aiChatUrl),
      headers: AppConstants.jsonHeaders,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AiChatResponse.fromJson(data);
    }
    throw Exception('AI chat failed: ${response.statusCode} ${response.body}');
  }
}