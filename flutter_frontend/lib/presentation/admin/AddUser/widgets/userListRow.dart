import 'package:flutter/material.dart';
import 'package:pfe_mes/data/admin/models/mes_user_model.dart';
import 'package:pfe_mes/presentation/admin/AddUser/widgets/userActionMenu.dart';
import 'package:pfe_mes/presentation/widgets/employee_avatar.dart';
import 'package:pfe_mes/presentation/widgets/expandableText.dart';

class UserListRow extends StatelessWidget {
  final MesUser user;
  final bool isCurrentUser;

  const UserListRow({
    required Key key,
    required this.user,
    required this.isCurrentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final roleColor = _calculateRoleColor(user.role, user.isActive);
    final roleBg = _calculateRoleBg(user.role, user.isActive);

    return RepaintBoundary(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Opacity(
          opacity: user.isActive ? 1.0 : 0.5,
          child: Row(
            children: [
              /// avatar + Name + Email
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    EmployeeAvatar(imageBase64: user.imageBase64, radius: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            user.email,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Role
              BadgeListCell(
                label: user.role,
                flex: 2,
                color: roleColor,
                bg: roleBg,
              ),

              // Work Center
              TextListCell(label: user.workCenterNameTextFormat, flex: 2),

              // Online Status
              BadgeListCell(
                label: user.isOnline ? 'Online' : 'Offline',
                flex: 2,
                color: user.isOnline
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF64748B),
                bg: user.isOnline
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFF1F5F9),
              ),

              // Last Seen
              TextListCell(
                label: user.lastSeenAt,
                flex: 2,
                textStyle: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),

              // Actions
              SizedBox(
                width: 60,
                child: isCurrentUser
                    ? const SizedBox.shrink()
                    : UserActionMenu(user: user),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _calculateRoleColor(String role, bool isActive) {
    if (!isActive) return const Color(0xFF64748B);
    switch (role) {
      case 'Admin':
        return const Color(0xFF7C3AED);
      case 'Supervisor':
        return const Color(0xFF2563EB);
      case 'Operator':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _calculateRoleBg(String role, bool isActive) {
    if (!isActive) return const Color(0xFFF1F5F9);
    switch (role) {
      case 'Admin':
        return const Color(0xFFF5F3FF);
      case 'Supervisor':
        return const Color(0xFFEFF6FF);
      case 'Operator':
        return const Color(0xFFF0FDF4);
      default:
        return const Color(0xFFF1F5F9);
    }
  }
}

// for badge like role and online status
class BadgeListCell extends StatelessWidget {
  final String label;
  final int flex;
  final Color color;
  final Color bg;

  const BadgeListCell({
    super.key,
    required this.label,
    required this.color,
    required this.bg,
    this.flex = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

// for text only like work center ...
class TextListCell extends StatelessWidget {
  final String label;
  final int flex;
  final TextStyle? textStyle;

  const TextListCell({
    super.key,
    required this.label,
    this.flex = 2,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: Alignment.centerLeft,
        child: ExpandableText(
          text: label,
          maxLines: 1,
          style: textStyle ?? const TextStyle(fontSize: 13),
        ),
      ),
    );
  }
}
