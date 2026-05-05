import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

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
      return  BadgeStyle(
        bg: const Color(0xFFF3F0FF),
        border: const Color(0xFFDDD6FE),
        text: const Color(0xFF5B21B6),
        label: 'firmPlanned'.tr(),
      );
    case 'Planned':
      return  BadgeStyle(
        bg: const  Color(0xFFF3F4F6),
        border: const Color(0xFFE5E7EB),
        text: const Color(0xFF6B7280),
        label: 'planned'.tr(),
      );
    case 'Finished':
      return  BadgeStyle(
        bg: const Color(0xFFEFF6FF),
        border: const Color(0xFFBFDBFE),
        text: const Color(0xFF1D4ED8),
        label: 'finished'.tr(),
      );
    case 'Cancelled':
      return  BadgeStyle(
        bg: const Color(0xFFFFD1D1),
        border: const Color(0xFFFF9393),
        text: const Color(0xFFFF0000),
        label: 'cancelled'.tr(),
      );
    case 'Released':
    default:
      return  BadgeStyle(
        bg: const Color(0xFFECFDF5),
        border: const Color(0xFFA7F3D0),
        text: const Color(0xFF065F46),
        label: 'released'.tr(),
      );
  }
}
