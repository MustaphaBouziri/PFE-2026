class ConversationTurn {
  final String role; // 'user' | 'assistant'
  final String content;

  const ConversationTurn({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class AiRedirectAction {
  final String actionType;
  final String label;
  final Map<String, dynamic> payload;

  const AiRedirectAction({
    required this.actionType,
    required this.label,
    this.payload = const {},
  });

  factory AiRedirectAction.fromJson(Map<String, dynamic> json) =>
      AiRedirectAction(
        actionType: json['action_type'] ?? '',
        label: json['label'] ?? '',
        payload: Map<String, dynamic>.from(json['payload'] ?? {}),
      );
}

class AiChatResponse {
  final String text;
  final List<AiRedirectAction> actions;
  final String? error;

  const AiChatResponse({
    required this.text,
    this.actions = const [],
    this.error,
  });

  factory AiChatResponse.fromJson(Map<String, dynamic> json) => AiChatResponse(
        text: json['text'] ?? '',
        actions: (json['actions'] as List<dynamic>? ?? [])
            .map((a) => AiRedirectAction.fromJson(a as Map<String, dynamic>))
            .toList(),
        error: json['error'] as String?,
      );
}