import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/mes_operation_model.dart';
import 'package:pfe_mes/presentation/machine/machine_details/machine_production/models/status_style.dart';
import 'package:pfe_mes/presentation/machine/machine_details/machine_production/widgets/progress_bar.dart';

class CurrentOrderInfoContainer extends StatefulWidget {
  final OperationStatusAndProgressModel operationData;
  const CurrentOrderInfoContainer({super.key, required this.operationData});

  @override
  State<CurrentOrderInfoContainer> createState() =>
      _CurrentOrderInfoContainerState();
}

class _CurrentOrderInfoContainerState
    extends State<CurrentOrderInfoContainer> {
  @override
  Widget build(BuildContext context) {
    final style = operationStatusStyleFromStatus(
      widget.operationData.operationStatus,
    );

    final double progress = widget.operationData.orderQuantity != 0
        ? (widget.operationData.progressPercent / 100).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title
          Text(
            "currentProductionOrder".tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 24),

          // order number + product name
          _InfoRow(
            leftLabel: "orderNumber".tr(),
            leftValue: widget.operationData.operationNo,
            rightLabel: "productName".tr(),
            rightValue: widget.operationData.itemDescription,
          ),

          const SizedBox(height: 12),

          // required quantity + produced quantity
          _InfoRow(
            leftLabel: "requiredQuantity".tr(),
            leftValue:
                "${widget.operationData.orderQuantity} ${"unit".tr()}",
            rightLabel: "producedQuantity".tr(),
            rightValue:
                "${widget.operationData.totalProducedQuantity} ${"unit".tr()}",
          ),

          const SizedBox(height: 12),

          // scraps (styled like others)
          _InfoRow(
            leftLabel: "scrapQuantity".tr(),
            leftValue:
                "${widget.operationData.scrapQuantity} ${"unit".tr()}",
            rightLabel: "",
            rightValue: "",
          ),

          const SizedBox(height: 12),

          OperationProgressBar(progress: progress, style: style),
        ],
      ),
    );
  }
}

// ──label + value ──────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  const _InfoRow({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                leftLabel,
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ),
            Expanded(
              child: Text(
                rightLabel,
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                leftValue,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            Expanded(
              child: Text(
                rightValue,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}