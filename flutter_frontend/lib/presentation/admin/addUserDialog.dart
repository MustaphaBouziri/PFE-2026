import 'package:flutter/material.dart';
import 'package:pfe_mes/presentation/widgets/searchBar.dart';
import 'package:provider/provider.dart';

import '../../domain/admin/providers/erp_employee_provider.dart';
import '../../domain/admin/providers/erp_workCenter_provider.dart';
import '../../domain/admin/providers/mes_user_provider.dart';
import '../widgets/employee_avatar.dart';

class AddUserDialog extends StatefulWidget {
  const AddUserDialog({super.key});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  int? selectedEmployeeIndex;
  int? selectedRoleIndex;
  int? selectedWorkCenterIndex;
  String? selectedEmployeeId;
  String? selectWorkCenterId;
  String? selectedRole;

  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final employees = context.watch<ErpEmployeeProvider>().employees;
    final workCenters = context.watch<ErpWorkcenterProvider>().workCenters;
    final mesUserProvider = context.read<MesUserProvider>();

    final filteredEmployees = employees
        .where(
          (e) =>
              e.fullName.toLowerCase().contains(
                searchController.text.toLowerCase(),
              ) ||
              e.email.toLowerCase().contains(
                searchController.text.toLowerCase(),
              ),
        )
        .toList();

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add New MES User',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // employee search
                    const Text(
                      'Select Employee',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // search bar wrapped to remove its internal spacing mismatch
                    Theme(
                      data: Theme.of(context).copyWith(
                        inputDecorationTheme: const InputDecorationTheme(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                      ),
                      child: GlobalSearchBar(
                        controller: searchController,
                        onSearchChanged: (_) => setState(() {}),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // employee list
                    SizedBox(
                      height: 250,
                      child: ListView.separated(
                        itemCount: filteredEmployees.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final employee = filteredEmployees[index];
                          final isSelected = selectedEmployeeIndex == index;

                          return GestureDetector(
                            onTap: () => setState(() {
                              selectedEmployeeIndex = index;
                              selectedEmployeeId = employee.employeeId;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blue.shade50
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                children: [
                                  EmployeeAvatar(
                                    employee: employee,
                                    radius: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          employee.fullName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          employee.email,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // role selection
                    const Text(
                      'Select Role',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _roleButton(
                          0,
                          'Operator',
                          const Color(0xFF2563EB),
                          const Color(0xFFEFF6FF),
                        ),
                        const SizedBox(width: 10),
                        _roleButton(
                          1,
                          'Supervisor',
                          const Color(0xFF16A34A),
                          const Color(0xFFF0FDF4),
                        ),
                        const SizedBox(width: 10),
                        _roleButton(
                          2,
                          'Admin',
                          const Color(0xFF7C3AED),
                          const Color(0xFFF5F3FF),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // work center selection
                    const Text(
                      'Select Work Center',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 200,
                      child: ListView.separated(
                        itemCount: workCenters.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final wc = workCenters[index];
                          final isSelected = selectedWorkCenterIndex == index;

                          return GestureDetector(
                            onTap: () => setState(() {
                              selectedWorkCenterIndex = index;
                              selectWorkCenterId = wc.id;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFF0FDF4)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF16A34A)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    wc.workCenterName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF16A34A),
                                      size: 18,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // submit
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selectedEmployeeIndex == null ||
                              selectWorkCenterId == null ||
                              selectedRoleIndex == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please select employee, role, and work center',
                                ),
                              ),
                            );
                            return;
                          }
                          final success = await mesUserProvider.addUser(
                            employeeId: selectedEmployeeId!,
                            role: selectedRole!,
                            workCenterNo: selectWorkCenterId!,
                          );
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('User added successfully!'),
                              ),
                            );
                            Navigator.of(context).pop();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  mesUserProvider.errorMessage ??
                                      'Failed to add user',
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Add User',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleButton(int index, String label, Color color, Color bg) {
    final isSelected = selectedRoleIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          selectedRoleIndex = index;
          selectedRole = label;
        }),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? bg : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isSelected ? color : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}
