import 'package:flutter/material.dart';

import '../models/badge_style.dart';

class BadgeAndId extends StatelessWidget {
  final dynamic order;
  final BadgeStyle badgeStyle;

  const BadgeAndId({super.key, required this.order, required this.badgeStyle});

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
          'ORD-${order.orderNo}',
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
