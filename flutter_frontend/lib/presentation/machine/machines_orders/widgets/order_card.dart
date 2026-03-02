import 'package:flutter/material.dart';

import '../layout/narrow_layout.dart';
import '../layout/wide_layout.dart';
import '../models/badge_style.dart';

class OrderCard extends StatelessWidget {
  final dynamic order;
  final BadgeStyle badgeStyle;

  const OrderCard({super.key, required this.order, required this.badgeStyle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
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
              final isWide = constraints.maxWidth > 520;
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
