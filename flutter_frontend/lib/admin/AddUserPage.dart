import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/erp_employee_provider.dart';
import '../providers/erp_workCenter_provider.dart';
import '../providers/mes_user_provider.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MesUserProvider>().fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MesUserProvider>();
    final users = provider.users;
    final auth = context.watch<AuthProvider>();

    final filteredUsers = users.where((user) {
      final bool roleMatch = selectedRole == 'All' || user.role == selectedRole;
      final bool searchMatch =
          user.fullName.toLowerCase().contains(
            searchController.text.toLowerCase(),
          ) ||
          user.email.toLowerCase().contains(
            searchController.text.toLowerCase(),
          );
      return roleMatch && searchMatch;
    }).toList();

    return Scaffold(
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
          ? Center(child: Text(provider.errorMessage!))
          : Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.black),
                  tooltip: 'Logout',
                  onPressed: () async {
                    await auth.logout();
                  },
                ),
                // ── ADD USER BUTTON ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      await context
                          .read<ErpEmployeeProvider>()
                          .fetchEmployees();
                      await context
                          .read<ErpWorkcenterProvider>()
                          .fetchWorkCenter();

                      showDialog(
                        context: context,
                        builder: (context) => const AddUserDialog(),
                      );
                    },
                    child: const Text('Add User'),
                  ),
                ),

                // ── SEARCH + FILTER ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Search users by name or email',
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 47,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedRole,
                            items: roles
                                .map(
                                  (role) => DropdownMenuItem(
                                    value: role,
                                    child: Text(role),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => selectedRole = value!);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── USER LIST ────────────────────────────────────────
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];

                      return GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => GeneratePasswordDialog(
                              userId: user.userId,
                              authId: user.authId,
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              top: BorderSide(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    // ── BC photo or initials ──
                                    EmployeeAvatar(
                                      // MesUser doesn't carry imageBase64 yet
                                      // (see note below), so this falls back
                                      // to initials derived from fullName.
                                      fallbackLabel: _initials(user.fullName),
                                      radius: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.fullName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          user.email,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(flex: 1, child: Text(user.role)),
                              const Expanded(flex: 1, child: Text('assembly')),
                              const Expanded(
                                flex: 1,
                                child: Text(
                                  'Online',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 120,
                                child: Text(
                                  'Just now',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
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
