import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/presentation/admin/widgets/Button.dart';
import 'package:pfe_mes/presentation/admin/widgets/MesListRow.dart';
import 'package:pfe_mes/presentation/admin/widgets/infoContainer.dart';
import 'package:pfe_mes/presentation/admin/widgets/tableHeader.dart';
import 'package:pfe_mes/presentation/widgets/searchBar.dart';
import 'package:provider/provider.dart';

import '../../domain/admin/providers/erp_employee_provider.dart';
import '../../domain/admin/providers/erp_workCenter_provider.dart';
import '../../domain/admin/providers/mes_user_provider.dart';
import '../widgets/employee_avatar.dart';
import 'addUserDialog.dart';
import 'generatePasswordDialog.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MesUserProvider>().fetchUsers();
    });
  }
  bool isLoading = false;

void _openAddUserDialog() async {
  setState(() => isLoading = true);
  try {
    await context.read<ErpEmployeeProvider>().fetchEmployees();
    await context.read<ErpWorkcenterProvider>().fetchWorkCenter();
    if (mounted) {
      showDialog(context: context, builder: (context) => const AddUserDialog());
    }
  } finally {
    if (mounted) setState(() => isLoading = false);
  }
}

  Color _roleColor(String role) {
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

  Color _roleBg(String role) {
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

  static const _shadow = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 12,
    spreadRadius: 1,
    offset: Offset(0, 4),
  );

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MesUserProvider>();
    final users = provider.users;

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
          children:  [
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
          Buttons(
            text: "addNewUser".tr(),
            isprimary: true,
            onTap: _openAddUserDialog,
            isLoading: isLoading,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
          ? Center(child: Text(provider.errorMessage!))
          : SingleChildScrollView(
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [_shadow],
                    ),
                    child: GlobalSearchBar(
                      controller: searchController,
                      onSearchChanged: (val) =>
                          setState(() => _currentPage = 0),
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
                            const String status = 'Online';
                            final bool isOnline = status == 'Online';
                            final bool hovered = _hoveredIndex == index;

                            return MouseRegion(
                              onEnter: (_) =>
                                  setState(() => _hoveredIndex = index),
                              onExit: (_) =>
                                  setState(() => _hoveredIndex = null),
                              child: GestureDetector(
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (context) => GeneratePasswordDialog(
                                    userId: user.userId,
                                    authId: user.authId,
                                  ),
                                ),
                                child: Container(
                                  color: hovered
                                      ? const Color(0xFFF8FAFC)
                                      : Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
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
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                        color: _roleColor(user.role),
                                        bg: _roleBg(user.role),
                                      ),

                                      // department
                                      MesListRow(
                                        label: user.workCenterNameTextFormat,
                                        flex: 2,
                                      ),

                                      // status
                                      MesListRow(
                                        label: status,
                                        flex: 2,
                                        color: isOnline
                                            ? const Color(0xFF16A34A)
                                            : const Color(0xFF64748B),
                                        bg: isOnline
                                            ? const Color(0xFFF0FDF4)
                                            : const Color(0xFFF1F5F9),
                                      ),

                                      // last active
                                      MesListRow(
                                        label: 'Just now',
                                        flex: 2,
                                        textStyle: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),

                                      // actions
                                      SizedBox(
                                        width: 60,
                                        child: PopupMenuButton<String>(
                                          icon: const Icon(
                                            Icons.more_vert,
                                            size: 20,
                                            color: Color(0xFF64748B),
                                          ),
                                          onSelected: (val) {},
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Text('edit'.tr()),
                                            ),
                                            PopupMenuItem(
                                              value: 'reset',
                                              child: Text('resetPassword'.tr()),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Color(0xFFDC2626),
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
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || fullName.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
