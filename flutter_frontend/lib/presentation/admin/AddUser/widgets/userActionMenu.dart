import 'package:flutter/material.dart';
import 'package:pfe_mes/data/admin/models/mes_user_model.dart';
import 'package:pfe_mes/domain/admin/providers/erp_workCenter_provider.dart';
import 'package:pfe_mes/domain/admin/providers/mes_user_provider.dart';
import 'package:pfe_mes/domain/auth/providers/auth_provider.dart';
import 'package:pfe_mes/presentation/admin/AddUser/widgets/changeRoleDialog.dart';
import 'package:pfe_mes/presentation/admin/AddUser/widgets/generatePasswordDialog.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

class UserActionMenu extends StatelessWidget {
  final MesUser user;

  const UserActionMenu({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: PopupMenuButton<String>(
        color: Colors.white,
        icon: const Icon(
          Icons.more_vert,
          size: 20,
          color: Color(0xFF64748B),
        ),
        onSelected: (val) => _handleMenuAction(context, val, user),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'editRoleDepartement',
            child: Text('changeRole'.tr()),
          ),
          if (user.isActive)
            PopupMenuItem(
              value: 'generatePassword',
              child: Text('generatePassword'.tr()),
            ),
          user.isActive
              ? PopupMenuItem(
                  value: 'deactivate',
                  child: Text(
                    'deactivate'.tr(),
                    style: const TextStyle(color: Color(0xFFDC2626)),
                  ),
                )
              : PopupMenuItem(
                  value: 'activate',
                  child: Text(
                    'activate'.tr(),
                    style: const TextStyle(color: Color(0xFF16A34A)),
                  ),
                ),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String val, MesUser user) {
    switch (val) {
      case 'activate':
        context
            .read<AuthProvider>()
            .toggleUserActiveStatus(user.userId, true)
            .then((_) => context.read<MesUserProvider>().triggerRefresh());
        break;
      case 'deactivate':
        context
            .read<AuthProvider>()
            .toggleUserActiveStatus(user.userId, false)
            .then((_) => context.read<MesUserProvider>().triggerRefresh());
        break;
      case 'editRoleDepartement':
        _openChangeRoleDialog(context, user);
        break;
      case 'generatePassword':
        if (user.isActive) {
          showDialog(
            context: context,
            builder: (context) => GeneratePasswordDialog(
              userId: user.userId,
              authId: user.authId,
            ),
          );
        }
        break;
    }
  }

  Future<void> _openChangeRoleDialog(
    BuildContext context,
    MesUser user,
  ) async {
    await context.read<ErpWorkcenterProvider>().fetchWorkCenters();

    if (!context.mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeRoleDialog(user: user),
    );

    if (!context.mounted) return;
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('roleUpdatedSuccessfully'.tr())),
      );
    }
  }
}
