import 'package:flutter/material.dart';

import '../models/status_style.dart';
import '../widgets/action_buttons.dart';
import '../widgets/info_grid.dart';
import '../widgets/progress_bar.dart';
import '../widgets/status_badge.dart';

/// Single-column stacked layout for narrow viewports (< 520 px).
/// Mirrors the role of [NarrowLayout] in machineOrderPage.
///
/// Order: badge → status + last updated → progress bar → hint → toggle button
class OperationNarrowLayout extends StatelessWidget {
  final String prodOrderNo;
  final String operationNo;
  final String operationStatus;
  final String? lastUpdatedAt;
  final double progress;
  final OperationStatusStyle style;
  final VoidCallback? onTogglePauseResume;

  const OperationNarrowLayout({
    super.key,
    required this.prodOrderNo,
    required this.operationNo,
    required this.operationStatus,
    this.lastUpdatedAt,
    required this.progress,
    required this.style,
    this.onTogglePauseResume,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Badge + identifiers ──────────────────────────────────────────
        OperationStatusBadge(
          prodOrderNo: prodOrderNo,
          operationNo: operationNo,
          style: style,
        ),

        const SizedBox(height: 12),

        // ── Status + Last Updated ────────────────────────────────────────
        OperationInfoGrid(
          lastUpdatedAt: lastUpdatedAt,
        ),

        const SizedBox(height: 12),

        // ── Progress bar ─────────────────────────────────────────────────
        OperationProgressBar(progress: progress, style: style),

        const SizedBox(height: 8),

        // ── Tap hint ─────────────────────────────────────────────────────
        Row(
          children: [
            Icon(Icons.touch_app_rounded, size: 12, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Text(
              'Tap card to view details',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Pause / Resume ───────────────────────────────────────────────
        OperationActionButtons(
          fullWidth: true,
          operationStatus: operationStatus,
          onTogglePauseResume: onTogglePauseResume,
        ),
      ],
    );
  }
}