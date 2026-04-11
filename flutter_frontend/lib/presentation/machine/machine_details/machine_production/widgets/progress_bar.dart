import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/status_style.dart';

/// Horizontal progress bar with a percentage label.
/// Progress value must be normalised to [0.0 – 1.0].
///
/// The fill colour is driven by [OperationStatusStyle.progressColor] so it
/// stays consistent with the status badge on the same card.
class OperationProgressBar extends StatelessWidget {
  final double progress; // 0.0 → 1.0
  final OperationStatusStyle style;

  const OperationProgressBar({
    super.key,
    required this.progress,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    final percentage = (clampedProgress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Track + fill ─────────────────────────────────────────────────
        Row(
                children: [
                  Expanded(
                    child: Text(
                      "overallProgress".tr(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: style.progressColor,
                    ),
                  ),
                ],
              ),
          const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: clampedProgress,
            minHeight: 10,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor:
            AlwaysStoppedAnimation<Color>(style.progressColor),

          ),
        ),

      ],
    );
  }
}