import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/domain/auth/providers/auth_provider.dart';
import 'package:pfe_mes/presentation/admin/AddUser/AddUserPage.dart';
import 'package:pfe_mes/presentation/admin/activityLogPage.dart';

import 'package:pfe_mes/presentation/admin/machineDashboardPage.dart';
import 'package:pfe_mes/presentation/machine/barCode/barCodeListPage.dart';
import 'package:pfe_mes/presentation/profilePage.dart';
import 'package:provider/provider.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final imageBytes = authProvider.profileImageBytes;

    return Scaffold(
      body: Row(
        children: [
          // sidebar
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // app name
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                Divider(color: Colors.white.withOpacity(0.1), height: 1),

                const SizedBox(height: 8),

                // menu items
                SidebarItem(
                  icon: Icons.people_outline,
                  label: 'usersRoles'.tr(),
                  isSelected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                SidebarItem(
                  icon: Icons.precision_manufacturing_outlined,
                  label: 'machineDashboard'.tr(),
                  isSelected: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                SidebarItem(
                  icon: Icons.bar_chart_outlined,
                  label: 'activityLogs'.tr(),
                  isSelected: _selectedIndex == 2,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
                SidebarItem(
                  icon: Icons.settings_outlined,
                  label: "Barcode List",
                  isSelected: _selectedIndex == 3,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
                SidebarItem(
                  icon: Icons.settings_outlined,
                  label: 'settings'.tr(),
                  isSelected: _selectedIndex == 4,
                  onTap: () => setState(() => _selectedIndex = 4),
                ),

                const Spacer(),

                Divider(color: Colors.white.withOpacity(0.1), height: 1),

                // user info
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: imageBytes != null
                              ? MemoryImage(imageBytes)
                              : const NetworkImage(
                                      'https://picsum.photos/200/200',
                                    )
                                    as ImageProvider,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authProvider.userData?['fullName']?.toString() ??
                                  'User',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              authProvider.userData?['authId']?.toString() ??
                                  '',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // page content
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                const AddUserPage(),
                const MachineDashboardPage(),
                const ActivityLogPage(),
                const BarcodeListPage(),
                Center(
                  child: Text(
                    'Settings Page - Coming Soon!',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
