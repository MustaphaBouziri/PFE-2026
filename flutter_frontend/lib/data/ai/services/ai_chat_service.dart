import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/app_constants.dart';
import '../models/ai_chat_model.dart';

class AiChatService {
  Future<AiChatResponse> sendMessage({
    required String message,
    required String userId,
    required String role,
    required List<String> workCenters,
    required String token,
    List<ConversationTurn> history = const [],
  }) async {
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