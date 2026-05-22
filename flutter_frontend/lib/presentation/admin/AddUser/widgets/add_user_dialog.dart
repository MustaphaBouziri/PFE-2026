import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/domain/admin/providers/erp_employee_provider.dart';
import 'package:pfe_mes/domain/admin/providers/erp_workCenter_provider.dart';
import 'package:pfe_mes/domain/admin/providers/mes_user_provider.dart';
import 'package:pfe_mes/presentation/widgets/employee_avatar.dart';
import 'package:pfe_mes/presentation/widgets/searchBar.dart';
import 'package:provider/provider.dart';

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
  String? errorMessage;

  // only supervisor can select multiple work centers
  // operator gets one, admin gets none
  // Use selectedRoleIndex to determine if multi-select (1 = supervisor)
  bool get isMultiSelect => selectedRoleIndex == 1;
  bool get _showWorkCenters => selectedRoleIndex != 2;

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

      // clear work center selections when role changes
      selectedWorkCenterIndexes = [];
      selectedWorkCenterIds = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = context.watch<ErpEmployeeProvider>();
    final workCenterProvider = context.watch<ErpWorkcenterProvider>();
    final mesUserProvider = context.read<MesUserProvider>();

    final employees = employeeProvider.employees;
    final workCenters = workCenterProvider.workCenters;

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

                    // employee list — show error if fetch failed
                    if (employeeProvider.errorMessage != null)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cloud_off_outlined,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'FailedToFetchData'.tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: const Color(0xFF94A3B8),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (employeeProvider.isLoading)
                      SizedBox(
                        height: 250,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.blue.shade600,
                          ),
                        ),
                      )
                    else if (employees.isEmpty)
                      SizedBox(
                        height: 250,
                        child: Center(
                          child: Text(
                            'noEmployeesFound'.tr(),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 250,
                        child: ListView.separated(
                          itemCount: filteredEmployees.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
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
                                        ? const Color.fromARGB(
                                            255,
                                            73,
                                            111,
                                            143,
                                          )
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Simple avatar - just image
                                    EmployeeAvatar(
                                      imageBase64: employee.imageBase64,
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
                    if (_showWorkCenters) ...[
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
                         Text(
                          'multiSelect'.tr(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      const SizedBox(height: 10),

                      // work center list — show error if fetch failed
                      if (workCenterProvider.errorMessage != null)
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_off_outlined,
                                size: 48,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'FailedToFetchData'.tr(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: const Color(0xFF94A3B8),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (workCenterProvider.isLoading)
                        SizedBox(
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.blue.shade600,
                            ),
                          ),
                        )
                      else if (workCenters.isEmpty)
                        SizedBox(
                          height: 200,
                          child: Center(
                            child: Text(
                              'noWorkCentersFound'.tr(),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 200,
                          child: ListView.separated(
                            itemCount: workCenters.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final wc = workCenters[index];
                              final isSelected = selectedWorkCenterIndexes
                                  .contains(index);

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
                    ],

                    const SizedBox(height: 20),

                    // error message display
                    if (errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // submit
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selectedEmployeeId == null) {
                            setState(() {
                              errorMessage = 'pleaseSelectEmployee'.tr();
                            });
                            return;
                          }
                          if (selectedRole == null) {
                            setState(() {
                              errorMessage = 'pleaseSelectRole'.tr();
                            });
                            return;
                          }

                          // Admin (index 2) doesn't need work centers
                          if (selectedRoleIndex != 2 &&
                              selectedWorkCenterIds.isEmpty) {
                            setState(() {
                              errorMessage = 'pleaseSelectAtLeastOneWorkCenter'
                                  .tr();
                            });
                            return;
                          }
                          final success = await mesUserProvider.addUser(
                            employeeId: selectedEmployeeId!,
                            roleInt: selectedRoleIndex!,
                            workCenterList: selectedWorkCenterIds,
                          );
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('userAddedSuccessfully'.tr()),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.of(context).pop();
                          } else {
                            setState(() {
                              errorMessage =
                                  mesUserProvider.errorMessage ??
                                  'failedToAddUser'.tr();
                            });
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
