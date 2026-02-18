import 'package:flutter/material.dart';
import 'package:pfe_mes/providers/erp_employee_provider.dart';
import 'package:pfe_mes/providers/erp_workCenter_provider.dart';
import 'package:pfe_mes/providers/mes_user_provider.dart';
import 'package:provider/provider.dart';

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

              // SEARCH
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

              // EMPLOYEE LIST WITH HIGHLIGHT
              SizedBox(
                height: 350,
                child: ListView.builder(
                  itemCount: filteredEmployees.length,
                  itemBuilder: (context, index) {
                    final employee = filteredEmployees[index];
                    final employeeid = employee.employeeId;

                    final isSelected = selectedEmployeeIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedEmployeeIndex = index;
                          selectedEmployeeId = employeeid;
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
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(employee.image),
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

              // ROLE TITLE
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

              // ROLE BUTTONS (INLINE, NO EXTRA WIDGET)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedRoleIndex = 0;
                            selectedRole = 'Operator';
                          });
                        },
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selectedRoleIndex == 0
                                ? Colors.orange
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selectedRoleIndex == 0
                                  ? Colors.orange
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            'Operator',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: selectedRoleIndex == 0
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedRoleIndex = 1;
                            selectedRole = 'Supervisor';
                          });
                        },
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selectedRoleIndex == 1
                                ? Colors.green
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selectedRoleIndex == 1
                                  ? Colors.green
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            'Supervisor',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: selectedRoleIndex == 1
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedRoleIndex = 2;
                            selectedRole = 'Admin';
                          });
                        },
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selectedRoleIndex == 2
                                ? Colors.red
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selectedRoleIndex == 2
                                  ? Colors.red
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            'Admin',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: selectedRoleIndex == 2
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

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
                    final workCenterid = workCenter.id;
                    final bool isSelected =
                        selectedWorkCenterIndex ==
                        index; // sellected is true if selectedWorkcenterIndex==index
                    /*
                    when you click an item, setState triggers a rebuild of the whole ListView.builder,
                    lets say now the sleetctedEmployeeindex = 2  it will force rebuild now for each index isSelected is true ? 0!=2 ok do not apply the selection design verify line by line 
                     */

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedWorkCenterIndex = index;
                          selectWorkCenterId = workCenterid;
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

              ElevatedButton(
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
                      const SnackBar(content: Text('User added successfully!')),
                    );
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          mesUserProvider.errorMessage ?? 'Failed to add user',
                        ),
                      ),
                    );
                  }
                },
                child: Text('Add User'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
