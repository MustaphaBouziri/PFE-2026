import 'package:flutter/material.dart';

/// Pause / Resume toggle button only — Details are accessed by tapping the card.
/// Supports [fullWidth] mode for narrow (single-column) layouts.
/// Mirrors the role of [ActionButtons] in machineOrderPage.
///
/// [onTogglePauseResume] is optional and left as a stub until the backend
/// endpoint is wired up.
class OperationActionButtons extends StatelessWidget {
  final bool fullWidth;
  final String operationStatus;

  /// Called when the user taps Pause or Resume.
  final VoidCallback? onTogglePauseResume;

  const OperationActionButtons({
    super.key,
    this.fullWidth = false,
    required this.operationStatus,
    this.onTogglePauseResume,
  });

  bool get _isRunning => operationStatus == 'Running';

  @override
  Widget build(BuildContext context) {
    final toggleBtn = ElevatedButton.icon(
      onPressed: onTogglePauseResume,
      icon: Icon(
        _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
        size: 16,
        color: Colors.white,
      ),
      label: Text(
        _isRunning ? 'Pause' : 'Resume',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isRunning
            ? const Color(0xFFF59E0B) // amber for Pause
            : const Color(0xFF22C55E), // green for Resume
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: toggleBtn);
    }

    return toggleBtn;
  }
}