import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/ai/providers/ai_chat_provider.dart';
import '../../domain/auth/providers/auth_provider.dart';
import '../../data/ai/models/ai_chat_model.dart';
import 'package:easy_localization/easy_localization.dart';

class AiChatPage extends StatefulWidget {
  final VoidCallback? onClose;
  final bool isDialog;

  const AiChatPage({
    super.key,
    this.onClose,
    this.isDialog = true,
  });

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


    await ai.sendMessage(
      message: text,
    );

    _scrollToBottom();
  }

  void _handleAction(BuildContext context, AiRedirectAction action) {
    switch (action.actionType) {
      case 'redirect_machine':
        final machineNo = action.payload['machineNo'] as String? ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navigate to machine $machineNo')),
        );
        break;
      case 'redirect_operation':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(action.label)),
        );
        break;
      case 'redirect_machine_list':
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
      default:
        break;
    }
  }

  void _handleClose() {
    if (widget.isDialog) {
      Navigator.pop(context);
    } else {
      widget.onClose?.call();
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
    if (widget.isDialog) {
      return Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 800, maxHeight: 800),
          child: _buildChatContent(),
        ),
      );
    }

    //  panel version
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: _buildChatContent(),
    );
  }

  Widget _buildChatContent() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
               Text(
                'aiAssistant'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'clearChat'.tr(),
                onPressed: () => context.read<AiChatProvider>().clearHistory(),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _handleClose,
              ),
            ],
          ),
        ),
        // Chat Content
        Expanded(
          child: Consumer<AiChatProvider>(
            builder: (context, aiProvider, _) {
              _scrollToBottom();
              return Column(
                children: [
                  Expanded(
                    child: aiProvider.history.isEmpty
                        ? const _EmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: aiProvider.history.length,
                            itemBuilder: (context, index) {
                              final turn = aiProvider.history[index];
                              final hasActions =
                                  turn.role == 'assistant' &&
                                  aiProvider.lastResponse?.actions.isNotEmpty ==
                                      true &&
                                  index == aiProvider.history.length - 1;

                              return Column(
                                children: [
                                  _MessageBubble(turn: turn),
                                  if (hasActions)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: _ActionButtons(
                                        actions:
                                            aiProvider.lastResponse!.actions,
                                        onTap: (action) =>
                                            _handleAction(context, action),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                  ),
                  if (aiProvider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        aiProvider.errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        // Input Bar
        Consumer<AiChatProvider>(
          builder: (context, aiProvider, _) {
            return _InputBar(
              controller: _controller,
              isLoading: aiProvider.isLoading,
              onSend: _send,
            );
          },
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) =>  Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
           const Icon(Icons.smart_toy_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'askMessage'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
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
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          turn.content,
          style: TextStyle(
            color: isUser ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
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
            .map(
              (action) => ElevatedButton(
                onPressed: () => onTap(action),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFe2e8f0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  action.label,
                  style: const TextStyle(color: Color(0xFF0F172A)),
                ),
              ),
            )
            .toList(),
      );
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

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
                    hintText: 'askAssistant'.tr(),
                    filled: true,
                    fillColor: const Color(0xFFe5e7eb),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              isLoading
                  ? const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton.filled(
                      onPressed: onSend,
                      icon: const Icon(Icons.send),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                      ),
                    ),
            ],
          ),
        ),
      );
}