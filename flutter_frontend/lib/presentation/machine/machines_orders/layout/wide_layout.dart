import 'package:flutter/material.dart';

import '../models/badge_style.dart';
import '../widgets/action_buttons.dart';
import '../widgets/badge_and_id.dart';
import '../widgets/info_grid.dart';

class WideLayout extends StatelessWidget {
  final dynamic order;
  final BadgeStyle badgeStyle;

  const WideLayout({super.key, required this.order, required this.badgeStyle});

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
        const SizedBox(width: 16),
        const ActionButtons(),
      ],
    );
  }
}
