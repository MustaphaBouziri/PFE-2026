import 'package:flutter/material.dart';

class OperationActionButtons extends StatefulWidget {
  final bool fullWidth;
  final String operationStatus;
  final VoidCallback? onTogglePauseResume;

  const OperationActionButtons({
    super.key,
    this.fullWidth = false,
    required this.operationStatus,
    this.onTogglePauseResume,
  });

  @override
  State<OperationActionButtons> createState() => _OperationActionButtonsState();
}

class _OperationActionButtonsState extends State<OperationActionButtons> {
  bool _isToggleLoading = false;

  bool get _isRunning =>
      widget.operationStatus.trim().toLowerCase() == 'running';

  bool get _canToggle {
    final status = widget.operationStatus.trim().toLowerCase();
    return status == 'running' || status == 'paused';
  }

  Future<void> _runToggle() async {
    if (widget.onTogglePauseResume == null) return;
    setState(() => _isToggleLoading = true);
    try {
      await Future.microtask(widget.onTogglePauseResume!);
    } finally {
      if (mounted) setState(() => _isToggleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final toggleBtn = ElevatedButton.icon(
      onPressed: (_isToggleLoading || !_canToggle) ? null : _runToggle,
      icon: _isToggleLoading
          ? const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      )
          : Icon(
        _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
        size: 16,
        color: Colors.white,
      ),
      label: Text(
        _isRunning ? 'Pause' : 'Resume',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isRunning ? const Color(0xFFF59E0B) : const Color(0xFF22C55E),
        disabledBackgroundColor: _isRunning ? const Color(0xFFF59E0B) : const Color(0xFF22C55E),
        disabledForegroundColor: Colors.white,
        foregroundColor: Colors.white,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );

    if (widget.fullWidth) {
      return SizedBox(width: double.infinity, child: toggleBtn);
    }

    return toggleBtn;
  }
}