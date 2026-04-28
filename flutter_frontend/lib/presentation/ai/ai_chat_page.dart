import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/ai/providers/ai_chat_provider.dart';
import '../../domain/auth/providers/auth_provider.dart';
import '../../data/ai/models/ai_chat_model.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final auth = context.read<AuthProvider>();
    final ai = context.read<AiChatProvider>();

    final userData = auth.userData ?? {};
    final userId = userData['authId']?.toString() ?? '';
    final role = userData['role']?.toString() ?? 'Operator';
    final rawWc = userData['workCenters'];
    final workCenters = rawWc is List
        ? List<String>.from(rawWc)
        : <String>[];
    final token = auth.token;

    await ai.sendMessage(
      message: text,
      userId: userId,
      role: role,
      workCenters: workCenters,
      token: token,
    );

    _scrollToBottom();
  }

  void _handleAction(BuildContext ctx, AiRedirectAction action) {
    // Navigation based on action_type
    // Callers can extend this switch for deeper navigation
    switch (action.actionType) {
      case 'redirect_machine':
        final mno = action.payload['machineNo'] as String? ?? '';
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Navigate to machine $mno')),
        );
        break;
      case 'redirect_operation':
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(action.label)),
        );
        break;
      case 'redirect_machine_list':
        Navigator.of(ctx).popUntil((r) => r.isFirst);
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MES Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear chat',
            onPressed: () => context.read<AiChatProvider>().clearHistory(),
          ),
        ],
      ),
      body: Consumer<AiChatProvider>(
        builder: (context, ai, _) {
          _scrollToBottom();
          return Column(
            children: [
              Expanded(
                child: ai.history.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: ai.history.length +
                            (ai.lastResponse?.actions.isNotEmpty == true ? 1 : 0),
                        itemBuilder: (ctx, i) {
                          if (i < ai.history.length) {
                            final turn = ai.history[i];
                            return _MessageBubble(turn: turn);
                          }
                          // Action buttons row after last assistant message
                          return _ActionButtons(
                            actions: ai.lastResponse!.actions,
                            onTap: (a) => _handleAction(ctx, a),
                          );
                        },
                      ),
              ),
              if (ai.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    ai.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              _InputBar(
                controller: _controller,
                isLoading: ai.isLoading,
                onSend: _send,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Ask me anything about your machines,\norders, or production.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
}

class _MessageBubble extends StatelessWidget {
  final ConversationTurn turn;
  const _MessageBubble({required this.turn});

  @override
  Widget build(BuildContext context) {
    final isUser = turn.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(turn.content,
            style: TextStyle(
                color: isUser ? Colors.white : const Color(0xFF0F172A),
                fontSize: 14)),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final List<AiRedirectAction> actions;
  final void Function(AiRedirectAction) onTap;
  const _ActionButtons({required this.actions, required this.onTap});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 4,
        children: actions
            .map((a) => OutlinedButton(
                  onPressed: () => onTap(a),
                  child: Text(a.label, style: const TextStyle(fontSize: 12)),
                ))
            .toList(),
      );
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;
  const _InputBar(
      {required this.controller,
      required this.isLoading,
      required this.onSend});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: 'Ask the MES assistant…',
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              isLoading
                  ? const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton.filled(
                      onPressed: onSend,
                      icon: const Icon(Icons.send),
                      style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A)),
                    ),
            ],
          ),
        ),
      );
}
