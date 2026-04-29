import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/core/storage/session_storage.dart';
import 'package:pfe_mes/domain/admin/providers/mes_log_provider.dart';
import 'package:pfe_mes/domain/auth/providers/auth_provider.dart';
import 'package:pfe_mes/presentation/admin/widgets/MachineCard.dart';
import 'package:pfe_mes/presentation/widgets/searchBar.dart';
import 'package:provider/provider.dart';

class MachineDashboardPage extends StatefulWidget {
  const MachineDashboardPage({super.key});

  @override
  State<MachineDashboardPage> createState() => _MachineDashboardPageState();
}

class _MachineDashboardPageState extends State<MachineDashboardPage> {
  final TextEditingController searchController = TextEditingController();

  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final SessionStorage sessionStorage = SessionStorage();
    final workCenters = sessionStorage.getWorkCenters() as List<String>;
    context.read<LogProvider>().fetchMachineDashboard(workCenters);
  });
}

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LogProvider>();
    final machines = provider.machineDashboardList;

    final filteredMachine = machines
        .where(
          (m) =>
              m.machineName.toLowerCase().contains(
                searchController.text.toLowerCase(),
              ) ||
              m.workCenterNo.toLowerCase().contains(
                searchController.text.toLowerCase(),
              ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'machineDashboardTitle'.tr(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          DropdownButton<int>(
            value: provider.selectedHours,
            underline: const SizedBox(),
            items: provider.hourOptions
                .map(
                  (h) => DropdownMenuItem(
                    value: h,
                    child: Text(provider.labelFor(h)),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) {
                provider.setHours(val);
                provider.fetchMachineDashboard();
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
          ? Center(child: Text(provider.errorMessage!))
          : LayoutBuilder(
              builder: (context, constraints) {
              
                final crossCount = constraints.maxWidth < 600
                    ? 1
                    : constraints.maxWidth < 1366
                    ? 2
                    : 3;
                return Column(
                  children: [
                    // search bar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GlobalSearchBar(
                        controller: searchController,
                        onSearchChanged: (_) => setState(() {}),
                      ),
                    ),
                    // machine grid
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: constraints.maxWidth < 900
                              ? 1.4
                              : constraints.maxWidth < 1366
                                  ? 2
                                  : 1.7,
                        ),
                        itemCount: filteredMachine.length,
                        itemBuilder: (context, index) {
                          return AdminMachineCard(
                            machine: filteredMachine[index],
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
