import 'package:flutter/material.dart';

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
      return const OperationStatusStyle(
        badgeBg: Color(0xFFECFDF5),
        badgeBorder: Color(0xFFA7F3D0),
        badgeText: Color(0xFF065F46),
        progressColor: Color(0xFF22C55E),
        leftRail: Color(0xFF22C55E),
        label: 'RUNNING',
      );

    case 'Paused':
      return const OperationStatusStyle(
        badgeBg: Color(0xFFFFFBEB),
        badgeBorder: Color(0xFFFDE68A),
        badgeText: Color(0xFF92400E),
        progressColor: Color(0xFFF59E0B),
        leftRail: Color(0xFFF59E0B),
        label: 'PAUSED',
      );

    case 'Finished':
      return const OperationStatusStyle(
        badgeBg: Color(0xFFEFF6FF),
        badgeBorder: Color(0xFFBFDBFE),
        badgeText: Color(0xFF1E40AF),
        progressColor: Color(0xFF3B82F6),
        leftRail: Color(0xFF3B82F6),
        label: 'FINISHED',
      );

    case 'Idle':
    default:
      return const OperationStatusStyle(
        badgeBg: Color(0xFFF3F4F6),
        badgeBorder: Color(0xFFE5E7EB),
        badgeText: Color(0xFF6B7280),
        progressColor: Color(0xFF9CA3AF),
        leftRail: Color(0xFF9CA3AF),
        label: 'IDLE',
      );
  }
}
