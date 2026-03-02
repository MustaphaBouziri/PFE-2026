import 'package:flutter/material.dart';

import '../models/badge_style.dart';
import '../widgets/action_buttons.dart';
import '../widgets/badge_and_id.dart';
import '../widgets/info_grid.dart';

class NarrowLayout extends StatelessWidget {
  final dynamic order;
  final BadgeStyle badgeStyle;

  const NarrowLayout({
    super.key,
    required this.order,
    required this.badgeStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BadgeAndId(order: order, badgeStyle: badgeStyle),
        const SizedBox(height: 12),
        InfoGrid(order: order),
        const SizedBox(height: 14),
        const ActionButtons(fullWidth: true),
      ],
    );
  }
}
