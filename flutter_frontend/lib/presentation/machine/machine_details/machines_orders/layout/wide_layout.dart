import 'package:flutter/material.dart';

import '../../../../../data/machine/models/erp_order_model.dart';
import '../models/badge_style.dart';
import '../widgets/action_buttons.dart';
import '../widgets/badge_and_id.dart';
import '../widgets/info_grid.dart';

class WideLayout extends StatelessWidget {
  final MachineOrderModel order;
  final BadgeStyle badgeStyle;
  final String machineNo;
  final bool showActions;
  final VoidCallback? onSwitchToProgress;

  const WideLayout({super.key, 
    required this.order,
    required this.badgeStyle,
    required this.machineNo,
    this.showActions = true,
    this.onSwitchToProgress,
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
              BadgeAndId(order: order, badgeStyle: badgeStyle),
              const SizedBox(height: 12),
              InfoGrid(order: order),
            ],
          ),
        ),
        if (showActions) ...[
          const SizedBox(width: 16),
          ActionButtons(
            order: order,
            machineNo: machineNo,
            onSwitchToProgress: onSwitchToProgress,
          ),
        ],
      ],
    );
  }
}