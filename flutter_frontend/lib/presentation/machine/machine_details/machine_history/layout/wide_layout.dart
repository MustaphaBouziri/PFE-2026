import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/mes_operation_model.dart';
import 'package:pfe_mes/presentation/machine/machine_details/machine_history/widgets/history_badge_and_id.dart.dart';
import 'package:pfe_mes/presentation/machine/machine_details/machine_history/widgets/history_info_grid.dart.dart';
import 'package:pfe_mes/presentation/machine/machine_details/machines_orders/models/badge_style.dart';


class WideLayout extends StatelessWidget {
  final OperationStatusAndProgressModel order;
  final BadgeStyle badgeStyle;

  const WideLayout({super.key, 
    required this.order,
    required this.badgeStyle,
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
              HistoryBadgeAndId(order: order, badgeStyle: badgeStyle),
              const SizedBox(height: 12),
              HistoryInfoGrid(order: order),
            ],
          ),
        ),
      ],
    );
  }
}