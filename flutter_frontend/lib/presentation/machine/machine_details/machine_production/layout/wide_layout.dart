import 'package:flutter/material.dart';

import '../models/status_style.dart';
import '../widgets/action_buttons.dart';
import '../widgets/info_grid.dart';
import '../widgets/progress_bar.dart';
import '../widgets/status_badge.dart';

/// Two-column layout: info on the left, Pause/Resume on the right.
/// Used at widths > 600 px. Mirrors the role of [WideLayout] in machineOrderPage.
///
/// Left column order: badge → status + last updated → progress bar → tap hint
class OperationWideLayout extends StatelessWidget {
  final String prodOrderNo;
  final String operationNo;
  final String operationStatus;
  final String? lastUpdatedAt;
  final double progress;
  final OperationStatusStyle style;
  final VoidCallback? onTogglePauseResume;

  const OperationWideLayout({
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Left: badge + meta + progress + hint ─────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OperationStatusBadge(
                prodOrderNo: prodOrderNo,
                operationNo: operationNo,
                style: style,
              ),
              const SizedBox(height: 12),
              OperationInfoGrid(lastUpdatedAt: lastUpdatedAt),
              const SizedBox(height: 12),
              OperationProgressBar(progress: progress, style: style),
              const SizedBox(height: 8),
              // ── Tap hint ───────────────────────────────────────────────
              Row(
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 12,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap card to view details',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Divider ──────────────────────────────────────────────────────
        Container(
          width: 1,
          height: 80,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          color: const Color(0xFFE2E8F0),
        ),

        // ── Right: Pause / Resume only ───────────────────────────────────
        OperationActionButtons(
          operationStatus: operationStatus,
          onTogglePauseResume: onTogglePauseResume,
        ),
      ],
    );
  }
}
