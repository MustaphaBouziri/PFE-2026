import 'package:flutter/material.dart';

class AppColors {
  // ── Base surface / layout ──────────────────────────────────────────────────
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface    = Colors.white;
  static const Color border     = Color(0xFFE2E8F0);
  static const Color divider    = Color(0xFFE5E7EB);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted     = Color(0xFF64748B);
  static const Color textDisabled  = Color(0xFF94A3B8);

  // ── Brand ─────────────────────────────────────────────────────────────────
  static const Color primary     = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color error   = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info    = Color(0xFF3B82F6);

  // ── Order status badge palette ────────────────────────────────────────────
  // Running / Released (green)
  static const Color statusGreenBg     = Color(0xFFECFDF5);
  static const Color statusGreenBorder = Color(0xFFA7F3D0);
  static const Color statusGreenText   = Color(0xFF065F46);

  // Paused / Warning (amber)
  static const Color statusAmberBg     = Color(0xFFFFFBEB);
  static const Color statusAmberBorder = Color(0xFFFDE68A);
  static const Color statusAmberText   = Color(0xFF92400E);

  // Finished / Info (blue)
  static const Color statusBlueBg     = Color(0xFFEFF6FF);
  static const Color statusBlueBorder = Color(0xFFBFDBFE);
  static const Color statusBlueText   = Color(0xFF1E40AF);
  static const Color statusBlueText2  = Color(0xFF1D4ED8); // order finished variant

  // Planned / Neutral (grey)
  static const Color statusGrayBg     = Color(0xFFF3F4F6);
  static const Color statusGrayBorder = Color(0xFFE5E7EB);
  static const Color statusGrayText   = Color(0xFF6B7280);
  static const Color statusGrayProg   = Color(0xFF9CA3AF);

  // Firm Planned (violet)
  static const Color statusVioletBg     = Color(0xFFF3F0FF);
  static const Color statusVioletBorder = Color(0xFFDDD6FE);
  static const Color statusVioletText   = Color(0xFF5B21B6);

  // Cancelled (red)
  static const Color statusRedBg     = Color(0xFFFFD1D1);
  static const Color statusRedBorder = Color(0xFFFF9393);
  static const Color statusRedText   = Color(0xFFFF0000);

  // ── Misc ──────────────────────────────────────────────────────────────────
  static const Color disabledButton = Color(0xFFCBD5E1);
  static const Color progressTrack  = Color(0xFFE5E7EB);
}
