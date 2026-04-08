import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/presentation/widgets/searchBar.dart';
import 'package:provider/provider.dart';

import '../../../domain/admin/providers/erp_employee_provider.dart';
import '../../../domain/admin/providers/erp_workCenter_provider.dart';
import '../../../domain/admin/providers/mes_user_provider.dart';
import '../../widgets/employee_avatar.dart';

class AddUserDialog extends StatefulWidget {
  const AddUserDialog({super.key});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  int? selectedEmployeeIndex;
  int? selectedRoleIndex;

  // changed from single to list to support multi select for supervisor
  List<int> selectedWorkCenterIndexes = [];
  List<String> selectedWorkCenterIds = [];

  String? selectedEmployeeId;
  String? selectedRole;

  // only supervisor can select multiple work centers
  // operator gets one, admin gets none
  bool get isMultiSelect => selectedRole == 'Supervisor';

  final TextEditingController searchController = TextEditingController();

  // handles work center tap — toggle off if already selected,
  // clear and replace if operator, just add if supervisor
  void workCenterSelection(int index, String workCenterId) {
    setState(() {
      if (selectedWorkCenterIndexes.contains(index)) {
        // toggle off — same item tapped again
        selectedWorkCenterIndexes.remove(index);
        selectedWorkCenterIds.remove(workCenterId);
      } else {
        if (!isMultiSelect && selectedWorkCenterIndexes.isNotEmpty) {
          // operator already has one selected — clear it first
          selectedWorkCenterIndexes.clear();
          selectedWorkCenterIds.clear();
        }
        // add the new selection
        selectedWorkCenterIndexes.add(index);
        selectedWorkCenterIds.add(workCenterId);
      }
    });
  }

  void _selectRole(int index, String role) {
    setState(() {
      selectedRoleIndex = index;
      selectedRole = role;

      selectedWorkCenterIndexes = [];
      selectedWorkCenterIds = [];
    });
  }

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
                  Text(
                    'addNewMesUser'.tr(),
                    style: const TextStyle(
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
                    Text(
                      'selectEmployee'.tr(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),

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
                    Text(
                      'selectRole'.tr(),
                      style: const TextStyle(
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
                          'operator'.tr(),
                          const Color(0xFF2563EB),
                          const Color(0xFFEFF6FF),
                        ),
                        const SizedBox(width: 10),
                        _roleButton(
                          1,
                          'supervisor'.tr(),
                          const Color(0xFF16A34A),
                          const Color(0xFFF0FDF4),
                        ),
                        const SizedBox(width: 10),
                        _roleButton(
                          2,
                          'admin'.tr(),
                          const Color(0xFF7C3AED),
                          const Color(0xFFF5F3FF),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // work center selection
                    Text(
                      'selectWorkCenter'.tr(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    // hint shown only for supervisor
                    if (isMultiSelect)
                      const Text(
                        'You can select multiple departments',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    const SizedBox(height: 10),

                    // work center list
                    SizedBox(
                      height: 200,
                      child: ListView.separated(
                        itemCount: workCenters.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final wc = workCenters[index];
                          final isSelected = selectedWorkCenterIndexes.contains(
                            index,
                          );

                          return GestureDetector(
                            onTap: () => workCenterSelection(index, wc.id),
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
                              selectedWorkCenterIds.isEmpty ||
                              selectedRoleIndex == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'pleaseSelectEmployeeRoleWorkCenter'.tr(),
                                ),
                              ),
                            );
                            return;
                          }
                          final success = await mesUserProvider.addUser(
                            employeeId: selectedEmployeeId!,
                            roleInt: selectedRoleIndex!,
                            // pass the full list — provider handles sending it to BC
                            workCenterList: selectedWorkCenterIds,
                          );
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('userAddedSuccessfully'.tr()),
                              ),
                            );
                            Navigator.of(context).pop();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  mesUserProvider.errorMessage ??
                                      'failedToAddUser'.tr(),
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
                        child: Text(
                          'addUser'.tr(),
                          style: const TextStyle(
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
        onTap: () => _selectRole(index, label),
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
