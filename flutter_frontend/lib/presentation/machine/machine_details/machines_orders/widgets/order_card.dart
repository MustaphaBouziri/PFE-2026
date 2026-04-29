import 'package:flutter/material.dart';

import '../../../../../data/machine/models/erp_order_model.dart';
import '../layout/narrow_layout.dart';
import '../layout/wide_layout.dart';
import '../models/badge_style.dart';

class OrderCard extends StatelessWidget {
  final MachineOrderModel order;
  final BadgeStyle badgeStyle;
  final String machineNo;
  final bool showActions;
  final VoidCallback? onTap;
  final VoidCallback? onSwitchToProgress;

  const OrderCard({super.key, 
    required this.order,
    required this.badgeStyle,
    required this.machineNo,
    this.showActions = true,
    this.onTap,
    this.onSwitchToProgress,
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
                  ? WideLayout(
                order: order,
                badgeStyle: badgeStyle,
                machineNo: machineNo,
                showActions: showActions,
                onSwitchToProgress: onSwitchToProgress,
              )
                  : NarrowLayout(
                order: order,
                badgeStyle: badgeStyle,
                machineNo: machineNo,
                showActions: showActions,
                onSwitchToProgress: onSwitchToProgress,
              );
            },
          ),
        ),
      ),
    );
  }
}