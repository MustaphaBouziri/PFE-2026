import 'package:flutter/material.dart';
import 'package:pfe_mes/data/admin/models/mes_user_model.dart';
import 'package:pfe_mes/presentation/admin/AddUser/widgets/user_action_menu.dart';
import 'package:pfe_mes/presentation/widgets/employee_avatar.dart';
import 'package:pfe_mes/presentation/widgets/expandableText.dart';
import 'package:easy_localization/easy_localization.dart';

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
    final roleBg    = _calculateRoleBg(user.role, user.isActive);

    return RepaintBoundary(
      child: Container(
        // amber left-edge stripe for pending rows
        decoration: BoxDecoration(
          color: Colors.white,
          border: user.isPendingSetup
              ? const Border(
            left: BorderSide(color: Color(0xFFD39D2B), width: 3),
          )
              : null,
        ),
        padding: EdgeInsets.only(
          // compensate for the 3px border so content doesn't shift
          left: user.isPendingSetup ? 13 : 16,
          right: 16,
          top: 12,
          bottom: 12,
        ),
        child: Opacity(
          opacity: user.isActive ? 1.0 : 0.5,
          child: Row(
            children: [
              /// Avatar + Name + Email (+ pending badge)
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
                          // Name row — badge sits right after the name
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.fullName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              if (user.isPendingSetup) ...[
                                const SizedBox(width: 6),
                                const _PendingBadge(),
                              ],
                            ],
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
              BadgeListCell(label: user.role, flex: 2, color: roleColor, bg: roleBg),

              // Work Center
              TextListCell(label: user.workCenterNameTextFormat, flex: 2),

              // Online Status
              BadgeListCell(
                label: user.isOnline ? 'online' : 'offline',
                flex: 2,
                color: user.isOnline ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                bg:    user.isOnline ? const Color(0xFFF0FDF4) : const Color(0xFFF1F5F9),
              ),

              // Last Seen
              TextListCell(
                label: user.lastSeenAt,
                flex: 2,
                textStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),

              // Actions
              SizedBox(
                width: 60,
                child: isCurrentUser ? const SizedBox.shrink() : UserActionMenu(user: user),
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
      case 'Admin':      return const Color(0xFF7C3AED);
      case 'Supervisor': return const Color(0xFF2563EB);
      case 'Operator':   return const Color(0xFF16A34A);
      default:           return const Color(0xFF64748B);
    }
  }

  Color _calculateRoleBg(String role, bool isActive) {
    if (!isActive) return const Color(0xFFF1F5F9);
    switch (role) {
      case 'Admin':      return const Color(0xFFF5F3FF);
      case 'Supervisor': return const Color(0xFFEFF6FF);
      case 'Operator':   return const Color(0xFFF0FDF4);
      default:           return const Color(0xFFF1F5F9);
    }
  }
}

// ── Pending badge ─────────────────────────────────────────────────────────────

class _PendingBadge extends StatelessWidget {
  const _PendingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCE8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD39D2B), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.lock_clock_outlined, size: 10, color: Color(0xFFD39D2B)),
          SizedBox(width: 3),
          Text(
            'Pending Setup',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFFD39D2B),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared cell widgets (unchanged) ──────────────────────────────────────────

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
            label.tr(),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ),
      ),
    );
  }
}

class TextListCell extends StatelessWidget {
  final String label;
  final int flex;
  final TextStyle? textStyle;

  const TextListCell({super.key, required this.label, this.flex = 2, this.textStyle});

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