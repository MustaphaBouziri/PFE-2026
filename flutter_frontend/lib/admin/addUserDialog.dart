import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/erp_employee_provider.dart';
import '../providers/erp_workCenter_provider.dart';
import '../providers/mes_user_provider.dart';
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
    final provider = context.watch<ErpEmployeeProvider>();
    final employees = provider.employees;

    final workCenterProvider = context.watch<ErpWorkcenterProvider>();
    final workCenters = workCenterProvider.workCenters;

    final mesUserProvider = context.read<MesUserProvider>();

    final filteredEmployees = employees.where((e) {
      return e.fullName.toLowerCase().contains(
            searchController.text.toLowerCase(),
          ) ||
          e.email.toLowerCase().contains(searchController.text.toLowerCase());
    }).toList();

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(30),
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER ──────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add New Mes User',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Select an Employee',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 12),

              // ── SEARCH ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search employee...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),

              const SizedBox(height: 12),

              // ── EMPLOYEE LIST ────────────────────────────────────────────
              SizedBox(
                height: 350,
                child: ListView.builder(
                  itemCount: filteredEmployees.length,
                  itemBuilder: (context, index) {
                    final employee = filteredEmployees[index];
                    final isSelected = selectedEmployeeIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedEmployeeIndex = index;
                          selectedEmployeeId = employee.employeeId;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
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
                            width: 1.5,
                          ),
                        ),
                        child: ListTile(
                          // ── BC blob photo or initials fallback ──
                          leading: EmployeeAvatar(
                            employee: employee,
                            radius: 22,
                          ),
                          title: Text(employee.fullName),
                          subtitle: Text(employee.email),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.blue,
                                )
                              : const Icon(Icons.add),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // ── ROLE SECTION ─────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: const Color.fromARGB(255, 253, 238, 227),
                child: const Text(
                  'Select Role',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _roleButton(0, 'Operator', Colors.orange),
                    const SizedBox(width: 12),
                    _roleButton(1, 'Supervisor', Colors.green),
                    const SizedBox(width: 12),
                    _roleButton(2, 'Admin', Colors.red),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── WORK CENTER SECTION ───────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: const Color.fromARGB(255, 234, 253, 227),
                child: const Text(
                  'Select WorkCenter',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 250,
                child: ListView.builder(
                  itemCount: workCenters.length,
                  itemBuilder: (context, index) {
                    final workCenter = workCenters[index];
                    final isSelected = selectedWorkCenterIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedWorkCenterIndex = index;
                          selectWorkCenterId = workCenter.id;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.green.shade50
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Colors.green
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          workCenter.workCenterName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── SUBMIT ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
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
                    child: const Text('Add User'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleButton(int index, String label, Color color) {
    final isSelected = selectedRoleIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedRoleIndex = index;
            selectedRole = label;
          });
        },
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
