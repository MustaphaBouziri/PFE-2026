import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/mes_operation_model.dart';
import 'package:pfe_mes/presentation/machine/machine_details/machines_orders/models/badge_style.dart';

class HistoryBadgeAndId extends StatelessWidget {
  final OperationStatusAndProgressModel order;
  final BadgeStyle badgeStyle;

  const HistoryBadgeAndId({super.key, required this.order, required this.badgeStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: badgeStyle.bg,
            border: Border.all(color: badgeStyle.border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            badgeStyle.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: badgeStyle.text,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'ORD-${order.prodOrderNo}',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}