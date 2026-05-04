import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/core/storage/session_storage.dart';
import 'package:pfe_mes/data/admin/models/mes_user_model.dart';
import 'package:pfe_mes/domain/auth/providers/auth_provider.dart';
import 'package:pfe_mes/presentation/admin/AddUser/widgets/stat_card.dart';

import 'package:pfe_mes/presentation/admin/AddUser/widgets/button.dart';
import 'package:pfe_mes/presentation/admin/AddUser/widgets/add_user_dialog.dart';
import 'package:pfe_mes/presentation/admin/addUser/widgets/user_list_table.dart';

import 'package:pfe_mes/presentation/widgets/searchBar.dart';
import 'package:provider/provider.dart';
import '../../../domain/admin/providers/erp_employee_provider.dart';
import '../../../domain/admin/providers/erp_workCenter_provider.dart';
import '../../../domain/admin/providers/mes_user_provider.dart';
import '../../tutorials/admin_dashboard_tutorial.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final SessionStorage _sessionStorage = SessionStorage();
  String selectedRole = 'all';
  final List<String> roles = const ['all', 'Admin', 'Supervisor', 'Operator'];

  final TextEditingController searchController = TextEditingController();

  int _currentPage = 0;
  static const int _pageSize = 10;

  bool isLoading = false;
  bool _tutorialShown = false;

  late final Stream<List<MesUser>> _usersStream;

  Timer? _debounce;
  String _searchQuery = '';

  // keys
  late final GlobalKey _searchKey;
  late final GlobalKey _addUserKey;
  late final GlobalKey _tableKey;

  @override
  void initState() {
    super.initState();

    _searchKey = GlobalKey();
    _addUserKey = GlobalKey();
    _tableKey = GlobalKey();

    _usersStream = context.read<MesUserProvider>().fetchMesUsers();

    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;

      setState(() {
        _searchQuery = searchController.text;
        _currentPage = 0;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _openAddUserDialog() async {
    setState(() => isLoading = true);

    try {
      await context.read<ErpEmployeeProvider>().fetchEmployees();
      await context.read<ErpWorkcenterProvider>().fetchWorkCenters();

      if (mounted) {
        showDialog(context: context, builder: (_) => const AddUserDialog());
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  List<MesUser> _filter(List<MesUser> users) {
    if (selectedRole == 'all' && _searchQuery.isEmpty) return users;

    final q = _searchQuery.toLowerCase();

    return users.where((u) {
      final roleMatch = selectedRole == 'all' || u.role == selectedRole;

      final searchMatch =
          q.isEmpty ||
          u.fullName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);

      return roleMatch && searchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _sessionStorage.getUserId() as String;

    return StreamBuilder<List<MesUser>>(
      stream: _usersStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: _buildAppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: _buildAppBar(),
            body: Center(child: Text(snapshot.error.toString())),
          );
        }

        final users = snapshot.data!;

        // tutorial once
        if (!_tutorialShown && users.isNotEmpty) {
          _tutorialShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AdminDashboardTutorial.show(context, [
              _searchKey,
              _addUserKey,
              _tableKey,
            ]);
          });
        }

        final filtered = _filter(users);

        final totalPages = (filtered.length / _pageSize).ceil();

        final pageUsers = filtered
            .skip(_currentPage * _pageSize)
            .take(_pageSize)
            .toList();

        return Scaffold(
          appBar: _buildAppBar(),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Stats(users: users, roles: roles),
                    const SizedBox(height: 16),
                    _SearchSection(
                      searchKey: _searchKey,
                      searchController: searchController,
                      roles: roles,
                      selectedRole: selectedRole,
                      onRoleChanged: (val) {
                        setState(() {
                          selectedRole = val ?? 'all';
                          _currentPage = 0;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: UserListTable(
                  users: pageUsers,
                  totalPages: totalPages,
                  currentPage: _currentPage,
                  onPageChanged: (p) => setState(() => _currentPage = p),
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text("manageUsers".tr()),
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
    );
  }
}

// Search section
class _SearchSection extends StatelessWidget {
  final GlobalKey searchKey;
  final TextEditingController searchController;
  final List<String> roles;
  final String selectedRole;
  final ValueChanged<String?> onRoleChanged;

  const _SearchSection({
    required this.searchKey,
    required this.searchController,
    required this.roles,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        key: searchKey,
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
          onSearchChanged: (_) {},
          dropdownItems: roles,
          selectedValue: selectedRole,
          onDropdownChanged: onRoleChanged,
        ),
      ),
    );
  }
}

List<MesUser> filterUsersIsolate(Map<String, dynamic> params) {
  final users = params['users'] as List<MesUser>;
  final role = params['role'] as String;
  final query = (params['query'] as String).toLowerCase();

  if (role == 'all' && query.isEmpty) return users;

  return users.where((user) {
    final matchesRole = role == 'all' || user.role == role;

    final matchesSearch =
        query.isEmpty ||
        user.fullName.toLowerCase().contains(query) ||
        user.email.toLowerCase().contains(query);

    return matchesRole && matchesSearch;
  }).toList();
}
