import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/mes_machine_model.dart';
import 'package:pfe_mes/presentation/admin/machineDashboardPage.dart';
import 'package:pfe_mes/presentation/profilePage.dart';
import 'package:pfe_mes/presentation/widgets/searchBar.dart';
import 'package:provider/provider.dart';

import '../../../domain/auth/providers/auth_provider.dart';
import '../../../domain/machines/providers/mes_machines_provider.dart';
import '../../tutorials/machine_list_tutorial.dart';
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

  // Keys for tutorial
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _machineCardKey = GlobalKey();
  final GlobalKey _profileKey = GlobalKey();

  bool _tutorialShown = false;

  /// Returns the normalised role string ('operator', 'supervisor', 'admin').
  String _resolveRole() {
    return context
            .read<AuthProvider>()
            .userData?['role']
            ?.toString()
            .trim()
            .toLowerCase() ??
        '';
  }

  /// Returns the list of work-center IDs the current user should see.
  ///
  /// • Supervisor→ their assigned work centers (possibly multiple)
  /// • Operator  → their single assigned work center
  ///
  /// Returns null while the admin list is still loading.
  List<String>? _resolveWorkCenterIds() {
    final role = _resolveRole();

    // Supervisor and Operator both store their WC list in AuthProvider.
    final wcs = context.read<AuthProvider>().userData?['workCenters'];
    if (wcs is List) return wcs.map((e) => e.toString()).toList();

    // Fallback: single workCenter field (legacy shape).
    final single = context
        .read<AuthProvider>()
        .userData?['workCenter']
        ?.toString();
    if (single != null && single.isNotEmpty) return [single];

    return [];
  }

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
    // watch so the machine list rebuilds if the session changes
    final authProvider = context.watch<AuthProvider>();
    final role = authProvider.userData?['role']?.toString() ?? '';
    final provider = Provider.of<MesMachinesProvider>(context, listen: false);

    final workCenterIds = _resolveWorkCenterIds();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              key: _profileKey,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundImage: const NetworkImage(
                  'https://picsum.photos/200/200',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authProvider.userData?['fullName']?.toString() ?? 'User',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: role == 'Supervisor'
                        ? Color(0xFF16A34A)
                        : Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            const Spacer(),
            role.toLowerCase() =='operator' ? const SizedBox() :
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MachineDashboardPage(),
                  ),
                );
              },
              icon: const Icon(
                Icons.dashboard,
                size: 16,
                color: Color(0xFF0F172A),
              ),
              label: Text(
                'machineDashboard'.tr(),
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),

      body: _buildBody(provider, workCenterIds),
    );
  }

  Widget _buildBody(MesMachinesProvider provider, List<String>? workCenterIds) {
    // The user has no assigned work centers at all.
    if (workCenterIds == null || workCenterIds.isEmpty) {
      return Center(child: Text('noWorkCenterAssigned'.tr()));
    }
// the new fix : basicaly its like saying am i currently looking at this page ? if no dont build the stream builder and just return an empty container
    final isVisible = ModalRoute.of(context)?.isCurrent ?? false;

    
    if (!isVisible) {
      return const SizedBox(); // why ? its an empty widget takes no space does nothing basicly like saying render nothing,
    }
    return StreamBuilder<Map<String, List<MachineModel>>>(
      // KEY: the stream is now driven by the resolved list, not a hardcoded
      // constant.  A new StreamBuilder key forces a fresh subscription when
      // the list changes (e.g. after an admin reassigns a supervisor).
      key: ValueKey(workCenterIds.join(',')),
      stream: provider.streamOrderedMachinePerDepartments(workCenterIds),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // apply search and status filter on top of the raw stream data
        final groupedMachines = _applyFilters(snapshot.data!);

        // Show tutorial if data loaded and not shown yet
        if (!_tutorialShown && groupedMachines.isNotEmpty) {
          _tutorialShown = true;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) async => await MachineListTutorial.show(context, [
              _profileKey,
              _searchKey,
              GlobalKey(),
              GlobalKey(),
              _machineCardKey,
            ]),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    'machinesList'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  _statusLegendBadge(
                    color: const Color.fromARGB(255, 40, 197, 92),
                    label: 'Working',
                  ),
                  const SizedBox(width: 8),
                  _statusLegendBadge(
                    color: const Color.fromARGB(255, 134, 134, 134),
                    label: 'Idle',
                  ),
                ],
              ),
            ),

            // Search + status filter
            Padding(
              key: _searchKey,
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
                    final crossAxisCount = constraints.maxWidth < 600
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
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                                    childAspectRatio: constraints.maxWidth < 900
                                        ? 2.5
                                        : constraints.maxWidth < 1400
                                        ? 1.5
                                        : 2.0, //pc
                                  ),
                              itemBuilder: (context, index) {
                                final isFirstVisibleCard =
                                    groupedMachines.entries.first.value ==
                                        machinesList &&
                                    index == 0;
                                return isFirstVisibleCard
                                    ? Container(
                                        key: _machineCardKey,
                                        child: MachineCard(
                                          machine: machinesList[index],
                                        ),
                                      )
                                    : MachineCard(machine: machinesList[index]);
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
    );
  }

  Widget _statusLegendBadge({required Color color, required String label}) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(backgroundColor: color, radius: 5),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
