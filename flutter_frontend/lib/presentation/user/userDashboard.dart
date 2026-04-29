import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/core/storage/session_storage.dart';
import 'package:provider/provider.dart';

import '../../domain/auth/providers/auth_provider.dart';

class UserDashboard extends StatelessWidget {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final SessionStorage _sessionStorage = SessionStorage();
    final auth = context.watch<AuthProvider>();
    final userData = _sessionStorage.getUserData() as Map<String, dynamic>;

    final String name = userData?['name']?.toString() ?? 'User';
    final String role = userData?['role']?.toString() ?? '';
    final String userId = userData?['userId']?.toString() ?? '';
    final String workCenter = userData?['workCenterNo']?.toString() ?? '—';

    Color roleColor;
    IconData roleIcon;
    switch (role) {
      case 'Supervisor':
        roleColor = Colors.green;
        roleIcon = Icons.supervisor_account;
        break;
      case 'Operator':
        roleColor = Colors.orange;
        roleIcon = Icons.engineering;
        break;
      default:
        roleColor = Colors.blueGrey;
        roleIcon = Icons.person;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: Text(
          'mesSystem'.tr(),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await auth.logout();
            },
          ),
        ],
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 48,
                  backgroundColor: roleColor.withOpacity(0.15),
                  child: Icon(roleIcon, size: 48, color: roleColor),
                ),

                const SizedBox(height: 24),

                // Welcome
                Text(
                  'welcomeBack'.tr(),
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),

                const SizedBox(height: 32),

                // Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.badge_outlined,
                        label: 'userId'.tr(),
                        value: userId,
                      ),
                      const Divider(height: 28),
                      _InfoRow(
                        icon: roleIcon,
                        label: 'role'.tr(),
                        value: role,
                        valueColor: roleColor,
                      ),
                      const Divider(height: 28),
                      _InfoRow(
                        icon: Icons.factory_outlined,
                        label: 'workCenter'.tr(),
                        value: workCenter.isEmpty ? '—' : workCenter,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Logout button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0F172A)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      await auth.logout();
                    },
                    icon: const Icon(Icons.logout, color: Color(0xFF0F172A)),
                    label: Text(
                      'logout'.tr(),
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: const Color(0xFF0F172A)),
        const SizedBox(width: 14),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: valueColor ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
