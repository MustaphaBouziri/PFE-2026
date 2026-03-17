import 'package:flutter/material.dart';

import '../../../../../data/machine/models/erp_order_model.dart';
import '../models/badge_style.dart';
import '../widgets/action_buttons.dart';
import '../widgets/badge_and_id.dart';
import '../widgets/info_grid.dart';

class NarrowLayout extends StatelessWidget {
  final MachineOrderModel order;
  final BadgeStyle badgeStyle;
  final String machineNo;
  final bool showActions;

  const NarrowLayout({
    required this.order,
    required this.badgeStyle,
    required this.machineNo,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BadgeAndId(order: order, badgeStyle: badgeStyle),
        const SizedBox(height: 12),
        InfoGrid(order: order),
        if (showActions) ...[
          const SizedBox(height: 14),
          ActionButtons(fullWidth: true, order: order, machineNo: machineNo),
        ],
      ],
    );
  }
}