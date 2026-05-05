import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/mes_operation_model.dart';
import 'package:pfe_mes/presentation/machine/machine_details/machine_history/layout/narrow_layout.dart';
import 'package:pfe_mes/presentation/machine/machine_details/machine_history/layout/wide_layout.dart';

import 'package:pfe_mes/presentation/machine/machine_details/machines_orders/models/badge_style.dart';

class HistoryCard extends StatelessWidget {
  final OperationStatusAndProgressModel order;
  final BadgeStyle badgeStyle;
  final VoidCallback? onTap;

  const HistoryCard({super.key, 
    required this.order,
    required this.badgeStyle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0F172A),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return isWide
                  ? WideLayout(order: order, badgeStyle: badgeStyle)
                  : NarrowLayout(order: order, badgeStyle: badgeStyle);
            },
          ),
        ),
      ),
    );
  }
}