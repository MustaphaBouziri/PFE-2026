import 'package:flutter/material.dart';
import 'package:pfe_mes/data/admin/models/mes_user_model.dart';
import 'package:easy_localization/easy_localization.dart';


class Stats extends StatelessWidget {
  final List<MesUser> users;
  final List<String> roles;

  const Stats({
    super.key,
    required this.users,
    required this.roles,
  });

  @override
  Widget build(BuildContext context) {
    final activeCount = users.where((u) => u.role != 'Pending').length;
    final pendingCount = users.where((u) => u.role == 'Pending').length;

    return RepaintBoundary(
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              title: "totalUsers".tr(),
              value: users.length,
              icon: Icons.people_outline,
              iconColor: const Color(0xFF2563EB),
              iconBg: const Color(0xFFEFF6FF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              title: "active".tr(),
              value: activeCount,
              icon: Icons.check_circle_outline,
              iconColor: const Color(0xFF16A34A),
              iconBg: const Color(0xFFF0FDF4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              title: "pendingApproval".tr(),
              value: pendingCount,
              icon: Icons.hourglass_empty_outlined,
              iconColor: const Color(0xFFD39D2B),
              iconBg: const Color(0xFFFEFCE8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              title: "totalRoles".tr(),
              value: roles.length - 1,
              icon: Icons.admin_panel_settings_outlined,
              iconColor: const Color(0xFF7C3AED),
              iconBg: const Color(0xFFF5F3FF),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              spreadRadius: 1,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //value + icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}