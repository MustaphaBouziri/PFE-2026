import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:pfe_mes/core/app_constants.dart';
import 'package:pfe_mes/data/machine/models/mes_machine_model.dart';
import 'package:pfe_mes/domain/machines/providers/mes_machines_provider.dart';
import 'package:pfe_mes/presentation/machine/machineDashBoard/machineDashboardPage.dart';
import 'package:pfe_mes/presentation/machine/machine_details/tabsMain.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/storage/session_storage.dart';
import '../../domain/ai/providers/ai_chat_provider.dart';
import '../../domain/auth/providers/auth_provider.dart';
import '../../data/ai/models/ai_chat_model.dart';
import 'package:easy_localization/easy_localization.dart';

class AiChatPage extends StatefulWidget {
  final VoidCallback? onClose;
  final bool isDialog;

  const AiChatPage({super.key, this.onClose, this.isDialog = true});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Map<String, List<MachineModel>> _debugMachines = {};
  bool _debugMachinesLoading = false;
  String? _debugMachinesError;
  bool _showDebug = false;

  static const bool _aiDebugEnabled = AppConstants.aiDebug;

  // ── Role helpers ──────────────────────────────────────────────────────────

  String get _currentRole => SessionStorage().getRole().trim().toLowerCase();

  bool get _isSupervisor => _currentRole == 'supervisor';

  /// Returns only the actions the current role is allowed to see/execute.
  /// Operators cannot be redirected to the machine dashboard.
  List<AiRedirectAction> _filterActions(List<AiRedirectAction> actions) {
    return actions.where((a) {
      if (a.actionType == 'redirect_machine_dashboard') return _isSupervisor;
      return true;
    }).toList();
  }

  Future<void> _loadDebugMachines() async {
    if (_debugMachinesLoading) return;
    setState(() {
      _debugMachinesLoading = true;
      _debugMachinesError = null;
    });
    try {
      final wcs = SessionStorage().getWorkCenters();
      final provider = context.read<MesMachinesProvider>();
      final result = await provider
          .streamOrderedMachinePerDepartments(wcs)
          .first;
      setState(() {
        _debugMachines = result;
        _debugMachinesLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugMachinesError = e.toString();
        _debugMachinesLoading = false;
      });
    }
  }

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

    await ai.sendMessage(message: text);

    _scrollToBottom();
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _navigateTo(Widget page) {
    final navigator = Navigator.of(context);
    if (widget.isDialog) {
      navigator.pop();
    } else {
      widget.onClose?.call();
    }
    navigator.push(MaterialPageRoute(builder: (_) => page));
  }

  void _handleAction(AiRedirectAction action) {
    final actionType = action.actionType;
    final payload = (action.payload as Map<String, dynamic>?) ?? {};
    final machineNo = payload['machineNo'] as String? ?? '';
    final machineName = payload['machineName'] as String? ?? machineNo;

    switch (actionType) {
      case 'redirect_machine_list':
        final navigator = Navigator.of(context);
        if (widget.isDialog) {
          navigator.pop();
        } else {
          widget.onClose?.call();
        }
        navigator.popUntil((route) => route.isFirst);
        break;

      case 'redirect_machine_waiting_operations':
        if (machineNo.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('missingMachineNo'.tr())));
          return;
        }
        _navigateTo(
          MachineMainPage(
            machineNo: machineNo,
            machineName: machineName,
            initialTabIndex: 0,
          ),
        );
        break;

      case 'redirect_machine_ongoing_operations':
        if (machineNo.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('missingMachineNo'.tr())));
          return;
        }
        _navigateTo(
          MachineMainPage(
            machineNo: machineNo,
            machineName: machineName,
            initialTabIndex: 1,
          ),
        );
        break;

      case 'redirect_history':
        if (machineNo.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('missingMachineNo'.tr())));
          return;
        }
        _navigateTo(
          MachineMainPage(
            machineNo: machineNo,
            machineName: machineName,
            initialTabIndex: 2,
          ),
        );
        break;

      case 'redirect_machine_dashboard':
        if (!_isSupervisor) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('actionNotAllowed'.tr())));
          return;
        }
        _navigateTo(const MachineDashboardPage());
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('unknownAction'.tr(args: [actionType]))),
        );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              bottom: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
          ),
          child: Row(
            children: [
              Text(
                'aiAssistant'.tr(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (_aiDebugEnabled)
                IconButton(
                  icon: Icon(
                    Icons.bug_report_outlined,
                    color: _showDebug ? const Color(0xFF795548) : null,
                  ),
                  tooltip: 'Toggle debug panel',
                  onPressed: () {
                    setState(() => _showDebug = !_showDebug);
                    if (_showDebug &&
                        _debugMachines.isEmpty &&
                        !_debugMachinesLoading) {
                      _loadDebugMachines();
                    }
                  },
                ),
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
                  if (_showDebug && _aiDebugEnabled)
                    LimitedBox(
                      maxHeight: 220,
                      child: SingleChildScrollView(
                        child: _DebugActionPanel(
                          machines: _debugMachines,
                          isLoading: _debugMachinesLoading,
                          errorMessage: _debugMachinesError,
                          onRetry: _loadDebugMachines,
                          onInject: (response) {
                            final ai = context.read<AiChatProvider>();
                            ai.injectDebugResponse(
                              userMessage:
                                  '[DEBUG] ${response.actions.first.actionType}',
                              response: response,
                            );
                            _scrollToBottom();
                          },
                        ),
                      ),
                    ),
                  Expanded(
                    child: aiProvider.history.isEmpty
                        ? const _EmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: aiProvider.history.length,
                            itemBuilder: (context, index) {
                              final turn = aiProvider.history[index];
                              final isLastAssistant =
                                  turn.role == 'assistant' &&
                                  index == aiProvider.history.length - 1;

                              // Apply role-based filtering before rendering buttons
                              final filteredActions =
                                  isLastAssistant &&
                                      aiProvider
                                              .lastResponse
                                              ?.actions
                                              .isNotEmpty ==
                                          true
                                  ? _filterActions(
                                      aiProvider.lastResponse!.actions,
                                    )
                                  : <AiRedirectAction>[];

                              return Column(
                                children: [
                                  _MessageBubble(turn: turn),
                                  if (filteredActions.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: _ActionButtons(
                                        actions: filteredActions,
                                        onTap: (action) =>
                                            _handleAction(action),
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
                        style: const TextStyle(color: Colors.red, fontSize: 12),
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
  Widget build(BuildContext context) => Center(
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

  Future<void> _openLink(String? href) async {
    if (href == null) return;

    final uri = Uri.tryParse(href);
    if (uri == null) return;

    if (uri.scheme != 'http' && uri.scheme != 'https') return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isUser = turn.role == 'user';

    final textColor = isUser ? Colors.white : const Color(0xFF0F172A);

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
        child: isUser
            ? Text(turn.content, style: const TextStyle(color: Colors.white))
            : MarkdownBody(
                data: turn.content,
                selectable: true,
                onTapLink: (text, href, title) {
                  _openLink(href);
                },
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                    .copyWith(
                      p: TextStyle(color: textColor, fontSize: 14, height: 1.4),
                      h1: TextStyle(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      h2: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      strong: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                      code: const TextStyle(
                        fontFamily: 'monospace',
                        backgroundColor: Color(0xFFE2E8F0),
                        color: Color(0xFF0F172A),
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

// ══════════════════════════════════════════════════════════════════════════════
// DEBUG PANEL — remove before production
// ══════════════════════════════════════════════════════════════════════════════
class _DebugActionPanel extends StatelessWidget {
  final Map<String, List<MachineModel>> machines;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final void Function(AiChatResponse) onInject;

  const _DebugActionPanel({
    required this.machines,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onInject,
  });

  AiChatResponse _make(
    String text,
    String actionType,
    String label, [
    Map<String, dynamic> payload = const {},
  ]) {
    return AiChatResponse(
      text: text,
      actions: [
        AiRedirectAction(
          actionType: actionType,
          label: label,
          payload: payload,
        ),
      ],
    );
  }

  // one debug button chip
  Widget _chip(String label, AiChatResponse response) {
    return GestureDetector(
      onTap: () => onInject(response),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF795548),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF8E1),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── header row ──────────────────────────────────────────────────
          Row(
            children: [
              const Text(
                '🛠 DEBUG — Redirect Action Tests',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF795548),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onRetry,
                child: const Icon(
                  Icons.refresh,
                  size: 16,
                  color: Color(0xFF795548),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // ── loading / error / empty ──────────────────────────────────────
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Loading machines…',
                    style: TextStyle(fontSize: 11, color: Color(0xFF795548)),
                  ),
                ],
              ),
            )
          else if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '⚠ $errorMessage',
                style: const TextStyle(fontSize: 11, color: Colors.red),
              ),
            )
          else if (machines.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'No machines found for your work centers.',
                style: TextStyle(fontSize: 11, color: Color(0xFF795548)),
              ),
            )
          else ...[
            // ── per-machine action buttons ───────────────────────────────
            ...machines.entries.expand((entry) {
              final wcNo = entry.key;
              final list = entry.value;
              return [
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 4),
                  child: Text(
                    'WC: $wcNo',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF795548),
                    ),
                  ),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: list.expand((machine) {
                    final p = {
                      'machineNo': machine.machineNo,
                      'machineName': machine.machineName,
                    };
                    return [
                      _chip(
                        '${machine.machineName} › Orders',
                        _make(
                          '🟢 [DEBUG] redirect_machine_waiting_operations\n'
                              'Machine: ${machine.machineName} (${machine.machineNo})\n'
                              'Status: ${machine.status}',
                          'redirect_machine_waiting_operations',
                          '→ Orders: ${machine.machineName}',
                          p,
                        ),
                      ),
                      _chip(
                        '${machine.machineName} › Ongoing',
                        _make(
                          '🟡 [DEBUG] redirect_machine_ongoing_operations\n'
                              'Machine: ${machine.machineName} (${machine.machineNo})\n'
                              'Status: ${machine.status}',
                          'redirect_machine_ongoing_operations',
                          '→ Ongoing: ${machine.machineName}',
                          p,
                        ),
                      ),
                      _chip(
                        '${machine.machineName} › History',
                        _make(
                          '🟠 [DEBUG] redirect_history\n'
                              'Machine: ${machine.machineName} (${machine.machineNo})\n'
                              'Status: ${machine.status}',
                          'redirect_history',
                          '→ History: ${machine.machineName}',
                          p,
                        ),
                      ),
                    ];
                  }).toList(),
                ),
              ];
            }),
          ],

          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFD7CCC8)),
          const SizedBox(height: 6),

          // ── static tests (no machine needed) ────────────────────────────
          const Text(
            'Static tests',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF795548),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip(
                '→ Machine List',
                _make(
                  '🔵 [DEBUG] redirect_machine_list\nGoes back to the machine list page.',
                  'redirect_machine_list',
                  '→ Machine List',
                ),
              ),
              _chip(
                '→ Dashboard',
                _make(
                  '🟣 [DEBUG] redirect_machine_dashboard\nOpens the machine dashboard (supervisor only).',
                  'redirect_machine_dashboard',
                  '→ Dashboard',
                ),
              ),
              _chip(
                '→ Unknown Action',
                _make(
                  '⛔ [DEBUG] unknown_action\nShould show unknown action snackbar.',
                  'unknown_action',
                  '→ Unknown',
                ),
              ),
              _chip(
                '→ Missing machineNo',
                _make(
                  '❌ [DEBUG] missing machineNo\nShould show missing machine snackbar.',
                  'redirect_machine_ongoing_operations',
                  '→ No Machine',
                  {'machineNo': '', 'machineName': ''},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
