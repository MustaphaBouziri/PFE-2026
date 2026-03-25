import 'package:flutter/material.dart';

class BadgeStyle {
  final Color bg;
  final Color border;
  final Color text;
  final String label;

  const BadgeStyle({
    required this.bg,
    required this.border,
    required this.text,
    required this.label,
  });
}

BadgeStyle badgeStyleFromStatus(String status) {
  switch (status) {
    case 'Firm Planned':
      return const BadgeStyle(
        bg: Color(0xFFF3F0FF),
        border: Color(0xFFDDD6FE),
        text: Color(0xFF5B21B6),
        label: 'FIRM PLANNED',
      );
    case 'Planned':
      return const BadgeStyle(
        bg: Color(0xFFF3F4F6),
        border: Color(0xFFE5E7EB),
        text: Color(0xFF6B7280),
        label: 'PLANNED',
      );
    case 'Finished':
      return const BadgeStyle(
        bg: Color(0xFFEFF6FF),
        border: Color(0xFFBFDBFE),
        text: Color(0xFF1D4ED8),
        label: 'FINISHED',
      );
    case 'Cancelled':
      return const BadgeStyle(
        bg: Color(0xFFFFD1D1),
        border: Color(0xFFFF9393),
        text: Color(0xFFFF0000),
        label: 'CANCELLED',
      );
    case 'Released':
    default:
      return const BadgeStyle(
        bg: Color(0xFFECFDF5),
        border: Color(0xFFA7F3D0),
        text: Color(0xFF065F46),
        label: 'RELEASED',
      );
  }
}
