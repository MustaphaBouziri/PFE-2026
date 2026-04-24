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
          context.read<MesUserProvider>().triggerRefresh();
        });
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MesUserProvider>();
    final authProvider = context.watch<AuthProvider>();

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
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  "manageUsers".tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
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
          body: Column(
            children: [
              Padding(
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
                            value: users
                                .where((u) => u.role != 'Pending')
                                .length,
                            icon: Icons.check_circle_outline,
                            iconColor: const Color(0xFF16A34A),
                            iconBg: const Color(0xFFF0FDF4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InfoContainer(
                            title: "pendingApproval".tr(),
                            value: users
                                .where((u) => u.role == 'Pending')
                                .length,
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
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 12,
                            spreadRadius: 1,
                            offset: Offset(0, 4),
                          ),
                        ],
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
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Expanded(
                //user list table
                child: _UserListTable(
                  users: pageUsers,
                  totalPages: totalPages,
                  currentPage: _currentPage,
                  onPageChanged: (newPage) =>
                      setState(() => _currentPage = newPage),
                  currentUserId: currentUserId,
                  tableKey: _tableKey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UserListTable extends StatefulWidget {
  final List<MesUser> users;
  final int totalPages;
  final int currentPage;
  final Function(int) onPageChanged;
  final String currentUserId;
  final GlobalKey tableKey;

  const _UserListTable({
    required this.users,
    required this.totalPages,
    required this.currentPage,
    required this.onPageChanged,
    required this.currentUserId,
    required this.tableKey,
  });

  @override
  State<_UserListTable> createState() => _UserListTableState();
}

class _UserListTableState extends State<_UserListTable> {
  static const _shadow = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 12,
    spreadRadius: 1,
    offset: Offset(0, 4),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      key: widget.tableKey,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [_shadow],
      ),
      child: Column(
        children: [
          const TableHeader(),
          Expanded(
            child: widget.users.isEmpty
                ? Center(
                    child: Text(
                      'noUsersFound'.tr(),
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: widget.users.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (context, index) {
                      final user = widget.users[index];
                      // what repaintBoundary does is it creates a separate layer for each user row, so when we hover over a row and it rebuilds to change the color, it only repaints that specific row's layer instead of the entire list
                      return RepaintBoundary(
                        child: _UserRow(
                          key: ValueKey(user.userId),
                          user: user,
                          isCurrentUser: user.userId == widget.currentUserId,
                        ),
                      );
                    },
                  ),
          ),

          if (widget.totalPages > 1)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: widget.currentPage > 0
                        ? () => widget.onPageChanged(widget.currentPage - 1)
                        : null,
                  ),
                  Text(
                    '${widget.currentPage + 1} / ${widget.totalPages}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: widget.currentPage < widget.totalPages - 1
                        ? () => widget.onPageChanged(widget.currentPage + 1)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// sperated the user list mainly to stop stream from fetching every time we hover
// the problem on hover the list will rebuild and mouse region will trigger a setState to change the color of the hovered row but since the list is being rebuilt it will fetch the stream again and again on evry hover
// thats why we separated the user list into its own widget to have its own state and only rebuild the hovered row instead of the whole list
class _UserRow extends StatefulWidget {
  final MesUser user;
  final bool isCurrentUser;

  const _UserRow({
    required Key key,
    required this.user,
    required this.isCurrentUser,
  }) : super(key: key);

  @override
  State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
  bool _isHovered = false;

  late final String _initials = _calculateInitials(widget.user.fullName);
  late final Color _roleColor = _calculateRoleColor(
    widget.user.role,
    widget.user.isActive,
  );
  late final Color _roleBg = _calculateRoleBg(
    widget.user.role,
    widget.user.isActive,
  );

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      // animatedContainer what it does is it animates the color change when hovering over a row, making the UI feel smoother and more responsive.
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: !widget.user.isActive
            ? const Color(0xFFF1F5F9)
            : _isHovered
            ? const Color(0xFFF8FAFC)
            : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Opacity(
          opacity: widget.user.isActive ? 1.0 : 0.5,
          child: Row(
            children: [
              // user info widget
              _UserInfoSection(user: widget.user, initials: _initials),

              // role
              MesListRow(
                label: widget.user.role,
                flex: 2,
                color: _roleColor,
                bg: _roleBg,
              ),

              // department
              MesListRow(
                label: widget.user.workCenterNameTextFormat,
                flex: 2,
                isActive: widget.user.isActive,
              ),

              // status
              MesListRow(
                label: widget.user.isOnline ? 'Online' : 'Offline',
                flex: 2,
                color: widget.user.isOnline
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF64748B),
                bg: widget.user.isOnline
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFF1F5F9),
              ),

              // last active
              MesListRow(
                label: widget.user.lastSeenAt,
                flex: 2,
                textStyle: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
                isActive: widget.user.isActive,
              ),

              //actions widget
              SizedBox(
                width: 60,
                child: widget.isCurrentUser
                    ? const SizedBox.shrink()
                    : _UserActionMenu(user: widget.user),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateInitials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || fullName.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
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

class _UserInfoSection extends StatelessWidget {
  final MesUser user;
  final String initials;

  const _UserInfoSection({required this.user, required this.initials});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 3,
      child: Row(
        children: [
          EmployeeAvatar(fallbackLabel: initials, radius: 18),
          const SizedBox(width: 10),
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
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserActionMenu extends StatelessWidget {
  final MesUser user;

  const _UserActionMenu({required this.user});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: Colors.white,
      icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF64748B)),
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

  Future<void> _openChangeRoleDialog(BuildContext context, MesUser user) async {
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
