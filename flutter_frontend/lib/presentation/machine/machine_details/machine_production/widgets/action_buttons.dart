import 'package:flutter/material.dart';
import 'package:pfe_mes/presentation/machine/machine_details/machine_production/models/status_style.dart';
import 'package:easy_localization/easy_localization.dart';
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

  OperationStatusStyle operationToggleStyle(String status) {
    //normalized status i mean like if its runninng it same as resume
    final normalized = status.trim().toLowerCase();

    if (normalized == 'running') {
      return operationStatusStyleFromStatus('Paused');
    } else {
      return operationStatusStyleFromStatus('Running');
    }
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
    final toggleStyle = operationToggleStyle(widget.operationStatus);
    final toggleBtn = ElevatedButton.icon(
      onPressed: (_isToggleLoading || !_canToggle) ? null : _runToggle,
      icon: _isToggleLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(
              _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 16,
              color: toggleStyle.badgeText,
            ),
      label: Text(
        _isRunning ? 'pause'.tr() : 'resume'.tr(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: toggleStyle.badgeText,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: toggleStyle.badgeBg,
        disabledBackgroundColor: toggleStyle.progressColor,
        foregroundColor: Colors.white,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: toggleStyle.badgeBorder, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );

    if (widget.fullWidth) {
      return SizedBox(width: double.infinity, child: toggleBtn);
    }
    return toggleBtn;
  }
}