import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/erp_employees_model.dart';

/// Displays an employee's photo from BC blob (base64) with initials fallback.
class EmployeeAvatar extends StatelessWidget {
  final ErpEmployee? employee;

  /// Used in places where you only have a base64 string (e.g. MesUser list).
  final String? imageBase64;

  /// Fallback label shown when there's no image (usually first letter of name).
  final String fallbackLabel;

  final double radius;

  const EmployeeAvatar({
    super.key,
    this.employee,
    this.imageBase64,
    this.fallbackLabel = '?',
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final base64Str = imageBase64 ?? employee?.imageBase64;

    if (base64Str != null && base64Str.isNotEmpty) {
      try {
        // Strip data URI prefix if present: "data:image/jpeg;base64,..."
        final clean = base64Str.contains(',')
            ? base64Str.split(',').last
            : base64Str;

        final bytes = base64Decode(clean);
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (_) {
        // Fall through to initials avatar if decoding fails
      }
    }

    // Fallback: colored circle with initials
    final label = employee != null
        ? _initials(employee!.fullName)
        : fallbackLabel;

    return CircleAvatar(
      radius: radius,
      backgroundColor: _colorFromLabel(label),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Color _colorFromLabel(String label) {
    // Deterministic color based on initials so it's stable across rebuilds
    final colors = [
      Colors.indigo,
      Colors.teal,
      Colors.deepPurple,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.pink,
    ];
    final code = label.codeUnits.fold(0, (a, b) => a + b);
    return colors[code % colors.length];
  }
}