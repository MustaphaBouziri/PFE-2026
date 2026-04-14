import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../models/status_style.dart';
import '../widgets/action_buttons.dart';
import '../widgets/info_grid.dart';
import '../widgets/progress_bar.dart';
import '../widgets/status_badge.dart';

class OperationWideLayout extends StatelessWidget {
  final String prodOrderNo;
  final String operationNo;
  final String operationStatus;
  final String? declaredAt;
  final double progress;
  final OperationStatusStyle style;
  final VoidCallback? onTogglePauseResume;

  const OperationWideLayout({
    super.key,
    required this.prodOrderNo,
    required this.operationNo,
    required this.operationStatus,
    this.declaredAt,
    required this.progress,
    required this.style,
    this.onTogglePauseResume,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
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
              OperationInfoGrid(lastUpdatedAt: declaredAt),
              const SizedBox(height: 12),
              OperationProgressBar(progress: progress, style: style),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.touch_app_rounded, size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    'tapCardToViewDetails'.tr(),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: 1,
          height: 80,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          color: const Color(0xFFE2E8F0),
        ),
        OperationActionButtons(
          operationStatus: operationStatus,
          onTogglePauseResume: onTogglePauseResume,
        ),
      ],
    );
  }
}