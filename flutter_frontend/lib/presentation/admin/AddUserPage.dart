import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/data/admin/models/mes_user_model.dart';
import 'package:pfe_mes/domain/auth/providers/auth_provider.dart';
import 'package:pfe_mes/presentation/admin/widgets/Button.dart';
import 'package:pfe_mes/presentation/admin/widgets/MesListRow.dart';
import 'package:pfe_mes/presentation/admin/widgets/addUserDialog.dart';
import 'package:pfe_mes/presentation/admin/widgets/infoContainer.dart';
import 'package:pfe_mes/presentation/admin/widgets/tableHeader.dart';
import 'package:pfe_mes/presentation/widgets/searchBar.dart';
import 'package:provider/provider.dart';

import '../../domain/admin/providers/erp_employee_provider.dart';
import '../../domain/admin/providers/erp_workCenter_provider.dart';
import '../../domain/admin/providers/mes_user_provider.dart';
import '../tutorials/admin_dashboard_tutorial.dart';
import '../widgets/employee_avatar.dart';
import 'generatePasswordDialog.dart';
import 'widgets/changeRoleDialog.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  String selectedRole = 'All';
  final List<String> roles = ['All', 'Admin', 'Supervisor', 'Operator'];
  final TextEditingController searchController = TextEditingController();
  int _currentPage = 0;
  static const int _pageSize = 10;
  int? _hoveredIndex;

  bool isLoading = false;

  // Keys for tutorial
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _roleDropdownKey = GlobalKey();
  final GlobalKey _addUserKey = GlobalKey();
  final GlobalKey _tableKey = GlobalKey();

  bool _tutorialShown = false;

  void _openAddUserDialog() async {
    setState(() => isLoading = true);
    try {
      await context.read<ErpEmployeeProvider>().fetchEmployees();
      await context.read<ErpWorkcenterProvider>().fetchWorkCenters();
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => const AddUserDialog(),
        ).then((_) {
          // trigger refresh when dialog closes
          context.read<MesUserProvider>().triggerRefresh();
        });
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Color _roleColor(String role, bool isActive) {
    if (!isActive) {
      return const Color(0xFF64748B);
    } else {
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
  }

  Color _roleBg(String role, bool isActive) {
    if (!isActive) {
      return const Color(0xFFF1F5F9);
    } else {
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

  static const _shadow = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 12,
    spreadRadius: 1,
    offset: Offset(0, 4),
  );

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MesUserProvider>();
    final authProvider = context.watch<AuthProvider>();

    // get currently loged in user id
    final currentUserId = authProvider.userData?['userId'] as String? ?? '';

    return StreamBuilder<List<MesUser>>(
      stream: provider.fetchMesUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        final users = snapshot.data!;

        // Show tutorial if data loaded and not shown yet
        if (!_tutorialShown && users.isNotEmpty) {
          _tutorialShown = true;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) async => await AdminDashboardTutorial.show(context, [
              _searchKey,
              _roleDropdownKey,
              _addUserKey,
              _tableKey,
            ]),
          );
        }

        final filteredUsers = users.where((user) {
          final roleMatch = selectedRole == 'All' || user.role == selectedRole;
          final searchMatch =
              user.fullName.toLowerCase().contains(
                searchController.text.toLowerCase(),
              ) ||
              user.email.toLowerCase().contains(
                searchController.text.toLowerCase(),
              );
          return roleMatch && searchMatch;
        }).toList();

        final totalPages = (filteredUsers.length / _pageSize).ceil();
        final pageUsers = filteredUsers
            .skip(_currentPage * _pageSize)
            .take(_pageSize)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "usersRolesManagement".tr(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  "manageUsers".tr(),
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
            actions: [
              Buttons(text: "exportUsers".tr(), isprimary: false, onTap: () {}),
              const SizedBox(width: 8),
              Container(
                key: _addUserKey,
                child: Buttons(
                  text: "addNewUser".tr(),
                  isprimary: true,
                  onTap: _openAddUserDialog,
                  isLoading: isLoading,
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // info containers
                Row(
                  children: [
                    Expanded(
                      child: InfoContainer(
                        title: "totalUsers".tr(),
                        value: users.length,
                        icon: Icons.people_outline,
                        iconColor: const Color(0xFF2563EB),
                        iconBg: const Color(0xFFEFF6FF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InfoContainer(
                        title: "active".tr(),
                        value: users.where((u) => u.role != 'Pending').length,
                        icon: Icons.check_circle_outline,
                        iconColor: const Color(0xFF16A34A),
                        iconBg: const Color(0xFFF0FDF4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InfoContainer(
                        title: "pendingApproval".tr(),
                        value: users.where((u) => u.role == 'Pending').length,
                        icon: Icons.hourglass_empty_outlined,
                        iconColor: const Color(0xFFD39D2B),
                        iconBg: const Color(0xFFFEFCE8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InfoContainer(
                        title: "totalRoles".tr(),
                        value: roles.length - 1,
                        icon: Icons.admin_panel_settings_outlined,
                        iconColor: const Color(0xFF7C3AED),
                        iconBg: const Color(0xFFF5F3FF),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // search bar
                Container(
                  key: _searchKey,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [_shadow],
                  ),
                  child: GlobalSearchBar(
                    controller: searchController,
                    onSearchChanged: (val) => setState(() => _currentPage = 0),
                    dropdownItems: roles,
                    selectedValue: selectedRole,
                    onDropdownChanged: (val) => setState(() {
                      selectedRole = val ?? 'All';
                      _currentPage = 0;
                    }),
                  ),
                ),

                const SizedBox(height: 16),

                // list container
                Container(
                  key: _tableKey,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [_shadow],
                  ),
                  child: Column(
                    children: [
                      // header
                      const TableHeader(),
                      // rows
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pageUsers.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: Colors.grey.shade100),
                        itemBuilder: (context, index) {
                          final user = pageUsers[index];
                          final bool hovered = _hoveredIndex == index;

                          // Check if this is the logged-in user
                          final isCurrentUser = user.userId == currentUserId;

                          return MouseRegion(
                            onEnter: (_) =>
                                setState(() => _hoveredIndex = index),
                            onExit: (_) => setState(() => _hoveredIndex = null),

                            child: Container(
                              color: !user.isActive
                                  ? const Color(0xFFF1F5F9)
                                  : hovered
                                  ? const Color(
                                      0xFFF8FAFC,
                                    ) // hover only if active
                                  : Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Opacity(
                                opacity: user.isActive ? 1.0 : 0.5,
                                child: Row(
                                  children: [
                                    // user
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          EmployeeAvatar(
                                            fallbackLabel: _initials(
                                              user.fullName,
                                            ),
                                            radius: 18,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  user.fullName,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                Text(
                                                  user.email,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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

                                    // role
                                    MesListRow(
                                      label: user.role,
                                      flex: 2,
                                      color: _roleColor(
                                        user.role,
                                        user.isActive,
                                      ),
                                      bg: _roleBg(user.role, user.isActive),
                                    ),

                                    // department
                                    MesListRow(
                                      label: user.workCenterNameTextFormat,
                                      flex: 2,
                                      isActive: user.isActive,
                                    ),

                                    // status
                                    MesListRow(
                                      label: user.isOnline
                                          ? 'Online'
                                          : 'Offline',
                                      flex: 2,
                                      color: user.isOnline
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFF64748B),
                                      bg: user.isOnline
                                          ? const Color(0xFFF0FDF4)
                                          : const Color(0xFFF1F5F9),
                                    ),

                                    // last active
                                    MesListRow(
                                      label: user.lastSeenAt,
                                      flex: 2,
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                      isActive: user.isActive,
                                    ),

                                    // actions — hide for logged-in user
                                    SizedBox(
                                      width: 60,
                                      child: isCurrentUser
                                          ? const SizedBox.shrink() // Hide action icon for current user /if i dont do it there will be layout shift
                                          : PopupMenuButton<String>(
                                              color: Colors.white,
                                              icon: const Icon(
                                                Icons.more_vert,
                                                size: 20,
                                                color: Color(0xFF64748B),
                                              ),
                                              onSelected: (val) {
                                                if (val == 'activate') {
                                                  context
                                                      .read<AuthProvider>()
                                                      .toggleUserActiveStatus(
                                                        user.userId,
                                                        true,
                                                      )
                                                      .then(
                                                        (_) => context
                                                            .read<
                                                              MesUserProvider
                                                            >()
                                                            .triggerRefresh(),
                                                      );
                                                } else if (val ==
                                                    'deactivate') {
                                                  context
                                                      .read<AuthProvider>()
                                                      .toggleUserActiveStatus(
                                                        user.userId,
                                                        false,
                                                      )
                                                      .then(
                                                        (_) => context
                                                            .read<
                                                              MesUserProvider
                                                            >()
                                                            .triggerRefresh(),
                                                      );
                                                } else if (val ==
                                                    'editRoleDepartement') {
                                                  _openEditRoleDepartement(
                                                    context,
                                                    user,
                                                  );
                                                } else if (val ==
                                                        'generatePassword' &&
                                                    user.isActive) {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) =>
                                                        GeneratePasswordDialog(
                                                          userId: user.userId,
                                                          authId: user.authId,
                                                        ),
                                                  );
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                PopupMenuItem(
                                                  value: 'editRoleDepartement',
                                                  child: Text(
                                                    'changeRole'.tr(),
                                                  ),
                                                ),
                                                if (user.isActive)
                                                  PopupMenuItem(
                                                    value: 'generatePassword',
                                                    child: Text(
                                                      'generatePassword'.tr(),
                                                    ),
                                                  ),
                                                if (!isCurrentUser)
                                                  user.isActive
                                                      ? PopupMenuItem(
                                                          value: 'deactivate',
                                                          child: Text(
                                                            'deactivate'.tr(),
                                                            style: TextStyle(
                                                              color: Color(
                                                                0xFFDC2626,
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                      : PopupMenuItem(
                                                          value: 'activate',
                                                          child: Text(
                                                            'activate'.tr(),
                                                            style: TextStyle(
                                                              color: Color(
                                                                0xFF16A34A,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                              ],
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // pagination
                      if (totalPages > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: _currentPage > 0
                                    ? () => setState(() => _currentPage--)
                                    : null,
                              ),
                              Text(
                                '${_currentPage + 1} / $totalPages',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: _currentPage < totalPages - 1
                                    ? () => setState(() => _currentPage++)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || fullName.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> _openEditRoleDepartement(
    BuildContext context,
    MesUser user,
  ) async {
    // Ensure work centers are loaded before opening the dialog.
    await context.read<ErpWorkcenterProvider>().fetchWorkCenters();

    if (!context.mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeRoleDialog(user: user),
    );

    if (!context.mounted) return;
    if (result == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('roleUpdatedSuccessfully'.tr())));
    }
  }
}
