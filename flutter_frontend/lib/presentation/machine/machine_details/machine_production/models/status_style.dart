import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// Styling descriptor for an operation's status badge and progress bar.
/// Mirrors the role of [BadgeStyle] in the machineOrderPage layer.
class OperationStatusStyle {
  final Color badgeBg;
  final Color badgeBorder;
  final Color badgeText;
  final Color progressColor;
  final Color leftRail;
  final String label;

  const OperationStatusStyle({
    required this.badgeBg,
    required this.badgeBorder,
    required this.badgeText,
    required this.progressColor,
    required this.label,
    required this.leftRail,
  });
}

/// Maps a raw [operationStatus] string coming from the API to an
/// [OperationStatusStyle].  Keeps all colour decisions in one place.
OperationStatusStyle operationStatusStyleFromStatus(String status) {
  switch (status) {
    case 'Running':
      return  OperationStatusStyle(
        badgeBg: const Color(0xFFECFDF5),
        badgeBorder: const Color(0xFFA7F3D0),
        badgeText: const Color(0xFF065F46),
        progressColor: const Color(0xFF22C55E),
        leftRail: const Color(0xFF22C55E),
        label: 'running'.tr(),
      );
    case 'Cancelled':
      return  OperationStatusStyle(
        badgeBg: const Color(0xFFFDECEC),
        badgeBorder: const Color(0xFFF3A7A7),
        badgeText: const Color(0xFF5F0606),
        progressColor: const Color(0xFFC52222),
        leftRail: const Color(0xFFC52222),
        label: 'cancelled'.tr(),
      );

    case 'Paused':
      return  OperationStatusStyle(
        badgeBg: const Color(0xFFFFFBEB),
        badgeBorder: const Color(0xFFFDE68A),
        badgeText: const Color(0xFF92400E),
        progressColor: const Color(0xFFF59E0B),
        leftRail: const Color(0xFFF59E0B),
        label: 'paused'.tr(),
      );

    case 'Finished':
      return  OperationStatusStyle(
        badgeBg: const Color(0xFFEFF6FF),
        badgeBorder: const Color(0xFFBFDBFE),
        badgeText: const Color(0xFF1E40AF),
        progressColor: const Color(0xFF3B82F6),
        leftRail: const Color(0xFF3B82F6),
        label: 'finished'.tr(),
      );

    case 'Idle':
    default:
      return  OperationStatusStyle(
        badgeBg: const Color(0xFFF3F4F6),
        badgeBorder: const Color(0xFFE5E7EB),
        badgeText: const Color(0xFF6B7280),
        progressColor: const Color(0xFF9CA3AF),
        leftRail: const Color(0xFF9CA3AF),
        label: 'idle'.tr(),
      );
  }
}
