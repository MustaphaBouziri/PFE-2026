import 'package:flutter/material.dart';
import 'package:pfe_mes/data/admin/models/mes_log_model.dart';
import 'package:pfe_mes/domain/admin/providers/mes_log_provider.dart';
import 'package:pfe_mes/presentation/admin/widgets/MachineCard.dart';
import 'package:pfe_mes/presentation/widgets/expandableText.dart';
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
      context.read<LogProvider>().fetchMachineDashboard();
    });
  }

  String _label(int h) {
    if (h < 24) return 'Last ${h}h';
    if (h == 24) return 'Last 24h';
    if (h == 48) return 'Last 48h';
    return 'Last 7d';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LogProvider>();
    final machines = provider.machineDashboardList;
    final filteredMachine = machines .where( (m) => m.machineName.toLowerCase().contains( searchController.text.toLowerCase(), ) || m.workCenterNo.toLowerCase().contains( searchController.text.toLowerCase(), ), ) .toList();

    

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Machine Dashboard',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          DropdownButton<int>(
            value: provider.selectedHours,
            underline: const SizedBox(),
            items: provider.hourOptions
                .map((h) => DropdownMenuItem(value: h, child: Text(_label(h))))
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
                    : constraints.maxWidth < 1024
                    ? 2
                    : 3;
                return Column(
                  children: [
                    // search bar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GlobalSearchBar(controller: searchController, onSearchChanged: (_) => setState(() {}), ),
                    ),
                    // machine grid
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.6,
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
