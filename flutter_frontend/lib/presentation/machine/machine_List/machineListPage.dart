import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/mes_machine_model.dart';
import 'package:pfe_mes/presentation/admin/machineDashboardPage.dart';
import 'package:pfe_mes/presentation/widgets/searchBar.dart';
import 'package:provider/provider.dart';

import '../../../domain/machines/providers/mes_machines_provider.dart';
import '../../widgets/language_selector.dart';
import 'MachineCard.dart';

class Machinelistpage extends StatefulWidget {
  const Machinelistpage({super.key});

  @override
  State<Machinelistpage> createState() => _MachinelistpageState();
}

class _MachinelistpageState extends State<Machinelistpage> {
  final TextEditingController searchController = TextEditingController();
  String selectedStatus = 'All';
  final List<String> statusOptions = ['All', 'Working', 'Idle'];

  // filter the grouped map — loop each department list and filter machines inside it
  Map<String, List<MachineModel>> _applyFilters(
    Map<String, List<MachineModel>> grouped,
  ) {
    final result = <String, List<MachineModel>>{};
    final query = searchController.text.toLowerCase();

    for (final entry in grouped.entries) {
      final filtered = entry.value.where((machine) {
        final matchesSearch =
            query.isEmpty ||
            machine.machineName.toLowerCase().contains(query) ||
            machine.workCenterName.toLowerCase().contains(query);

        final matchesStatus =
            selectedStatus == 'All' ||
            machine.status.toLowerCase() == selectedStatus.toLowerCase();

        return matchesSearch && matchesStatus;
      }).toList();

      if (filtered.isNotEmpty) {
        result[entry.key] = filtered;
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MesMachinesProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage('https://picsum.photos/200/200'),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ahmed Ben Hamed',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Text(
                  'ID: 00012036',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const Spacer(),
            const LanguageSelector(isCompact: true),
             TextButton.icon(
              onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MachineDashboardPage(),
                    ),
                  );
              },
              icon: const Icon(Icons.dashboard, size: 16),
              label: Text('MachineDashboard'),
              
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.logout, size: 16),
              label: Text('logout'.tr()),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
            ),
          ],
        ),
      ),

      body: StreamBuilder<Map<String, List<MachineModel>>>(
        stream: provider.streamOrderedMachinePerDepartments(["100", "200"]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // apply search and status filter on top of the raw stream data
          final groupedMachines = _applyFilters(snapshot.data!);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      "machinesList".tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              backgroundColor: Color.fromARGB(255, 40, 197, 92),
                              radius: 5,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Working',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              backgroundColor: Color.fromARGB(
                                255,
                                134,
                                134,
                                134,
                              ),
                              radius: 5,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Idle',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // search and status filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GlobalSearchBar(
                  controller: searchController,
                  onSearchChanged: (_) => setState(() {}),
                  dropdownItems: statusOptions,
                  selectedValue: selectedStatus,
                  onDropdownChanged: (val) =>
                      setState(() => selectedStatus = val ?? 'All'),
                ),
              ),

              const SizedBox(height: 8),

              // empty state after filtering
              if (groupedMachines.isEmpty)
                Expanded(child: Center(child: Text('noMachinesFound'.tr())))
              else
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = constraints.maxWidth < 600
                          ? 1
                          : constraints.maxWidth < 1024
                          ? 2
                          : 4;

                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: groupedMachines.entries.map((entry) {
                          final workCenterNo = entry.key;
                          final machinesList = entry.value;
                          final workCenterName = machinesList.isNotEmpty
                              ? machinesList.first.workCenterName
                              : '';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Department title
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      workCenterNo,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      workCenterName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Grid for this department
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: machinesList.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio:
                                          constraints.maxWidth < 900
                                          ? 1.8
                                          : constraints.maxWidth < 1400
                                          ? 1.5
                                          : 1.8,
                                    ),
                                itemBuilder: (context, index) {
                                  return MachineCard(
                                    machine: machinesList[index],
                                  );
                                },
                              ),

                              const SizedBox(height: 24),
                            ],
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
