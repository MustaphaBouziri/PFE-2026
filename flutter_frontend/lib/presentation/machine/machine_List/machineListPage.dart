import 'dart:async';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/core/storage/session_storage.dart';
import 'package:pfe_mes/data/machine/models/mes_machine_model.dart';
import 'package:pfe_mes/main.dart';
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

// we now make the page aware(RouteAware) of navigation changes using the RouteObserver defined in main.dart
// this will unlock these methodes : didPushNext and didPopNext
class _MachinelistpageState extends State<Machinelistpage> with RouteAware {
  final TextEditingController searchController = TextEditingController();
  final SessionStorage _sessionStorage = SessionStorage();

  final ValueNotifier<String> searchQuery = ValueNotifier('');
  final ValueNotifier<String> statusFilter = ValueNotifier('All');
  final ValueNotifier<Map<String, List<MachineModel>>> dataNotifier =
      ValueNotifier({});
  final ValueNotifier<bool> loadingNotifier = ValueNotifier(true);

  final List<String> statusOptions = ['All', 'Working', 'Idle'];
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _machineCardKey = GlobalKey();
  final GlobalKey _profileKey = GlobalKey();

  bool _tutorialShown = false;
  late List<String> _workCenterIds;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _workCenterIds = _resolveWorkCenterIds();

    if (_workCenterIds.isNotEmpty) {
      _startStream();
    }
  }

  // register this page to be the global observer
  // its like saying : hey flutter notify me when navigation heppens
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  // this will be triggered when u navigate back to this page  or first time this page is created  a new subscription will be made
  void _startStream() {
    // this to prevent duplicate streams without it  on every resume = new stream = multiple api calls
    // im already listening to the stream dont start a new one
    // without it every time i come back to the page it will start a new subscription and i will have multiple streams listening and making api calls at the same time (3 subs = 3 api call evry 20 sec )
    if (_subscription != null) {
      return; // already streaming
    }

    final provider = context.read<MesMachinesProvider>();
    //subscribe to the stream and update notifiers on new data
    _subscription = provider
        .streamOrderedMachinePerDepartments(_workCenterIds)
        .listen((event) {
          // event is the data eitted evry 20 sec
          if (!mounted) return;

          dataNotifier.value = event;
          loadingNotifier.value = false;
        });
  }

  // cancels the active stream subscription: stop api calls free memmory
  //stream exist but subscription is cancel it only makes the page stop listening to the strezm
  void _stopStream() {
    _subscription?.cancel();
    _subscription = null;
  }

  // route aware methode : this will be triggered when we open another page on top like nav.push
  @override
  void didPushNext() {
    _stopStream();
    super.didPushNext();
  }

  // route aware methode : this will be triggered when we come back to this page after closing the top page like nav.pop we restart the page
  @override
  void didPopNext() {
    if (_workCenterIds.isNotEmpty) {
      _startStream();
    }
    super.didPopNext();
  }

  // when the page is closed permanently we want to stop the stream and free memmory and also unsubscribe from the global observer to stop listening to navigation changes
  @override
  void dispose() {
    routeObserver.unsubscribe(this);

    // Stop listening to stream
    _stopStream();

    /// Dispose controllers and notifiers
    searchController.dispose();
    searchQuery.dispose();
    statusFilter.dispose();
    dataNotifier.dispose();
    loadingNotifier.dispose();

    super.dispose();
  }

  String _resolveRole() {
    return _sessionStorage.getRole().toString().trim().toLowerCase() ?? '';
  }

  List<String> _resolveWorkCenterIds() {
    final wcs = _sessionStorage.getWorkCenters() as List<String>;
    if (wcs is List) return wcs.map((e) => e.toString()).toList();
  }

  //filter without modifying original data and without triggering unnecessary rebuilds
  Map<String, List<MachineModel>> _applyFilters(
    Map<String, List<MachineModel>> grouped,
    String query,
    String status,
  ) {
    final result = <String, List<MachineModel>>{};
    final q = query.toLowerCase();

    for (final entry in grouped.entries) {
      final filtered = entry.value.where((machine) {
        final matchesSearch =
            q.isEmpty ||
            machine.machineName.toLowerCase().contains(q) ||
            machine.workCenterName.toLowerCase().contains(q);

        final matchesStatus =
            status == 'All' ||
            machine.status.toLowerCase() == status.toLowerCase();

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
    final authProvider = context.read<AuthProvider>();
    final role = _resolveRole();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              key: _profileKey,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfilePage()),
                );
              },
              child: Selector<AuthProvider, Uint8List?>(
                selector: (_, p) => p.profileImageBytes,
                builder: (_, imageBytes, __) {
                  return CircleAvatar(
                    radius: 18,
                    backgroundImage: imageBytes != null
                        ? MemoryImage(imageBytes)
                        : const NetworkImage('https://picsum.photos/200/200'),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sessionStorage.getFullName().toString(),
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
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            const Spacer(),
            role.toLowerCase() == 'operator'
                ? const SizedBox()
                : TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MachineDashboardPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.dashboard, size: 16),
                    label: Text('machineDashboard'.tr()),
                  ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_workCenterIds.isEmpty) {
      return Center(child: Text('noWorkCenterAssigned'.tr()));
    }
    // we use ValueListenableBuilder to listen to loading state and show a loader until data is ready
    // we do this because we want to show the tutorial only after data is loaded and the UI is ready
    return ValueListenableBuilder<bool>(
      valueListenable: loadingNotifier,
      builder: (_, loading, __) {
        if (loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return _buildMachineList();
      },
    );
  }

  // the entire body ui meaning the search + the list machine
  Widget _buildMachineList() {
    return Column(
      children: [
        /// header
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

        /// SEARCH
        Padding(
          key: _searchKey,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GlobalSearchBar(
            controller: searchController,
            onSearchChanged: (val) => searchQuery.value = val,
            dropdownItems: statusOptions,
            selectedValue: statusFilter.value,
            onDropdownChanged: (val) => statusFilter.value = val ?? 'All',
          ),
        ),
        const SizedBox(height: 8),

        // machine list
        // only this part will be rebuilt when search query or status filter changes because we used ValueListenableBuilder on the notifiers that are only updated when search or filter changes
        Expanded(
          child: ValueListenableBuilder<Map<String, List<MachineModel>>>(
            valueListenable: dataNotifier,
            builder: (_, data, __) {
              return ValueListenableBuilder<String>(
                valueListenable: searchQuery,
                builder: (_, query, __) {
                  return ValueListenableBuilder<String>(
                    valueListenable: statusFilter,
                    builder: (_, status, __) {
                      final groupedMachines = _applyFilters(
                        data,
                        query,
                        status,
                      );
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

                      // in case nothing
                      if (groupedMachines.isEmpty) {
                        return Center(child: Text('noMachinesFound'.tr()));
                      }

                      // Layout
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth < 600
                              ? 1
                              : constraints.maxWidth < 1024
                              ? 2
                              : 4;

                          return ListView(
                            padding: const EdgeInsets.all(16),
                            children: groupedMachines.entries.map((entry) {
                              final machinesList = entry.value;
                              final workCenterName = machinesList.isNotEmpty
                                  ? machinesList.first.workCenterName
                                  : '';

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(entry.key),
                                        const SizedBox(width: 8),
                                        Text(
                                          workCenterName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: machinesList.length,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          crossAxisSpacing: 16,
                                          mainAxisSpacing: 16,
                                          childAspectRatio:
                                              constraints.maxWidth < 900
                                              ? 2.5
                                              : constraints.maxWidth < 1400
                                              ? 1.5
                                              : 2.0,
                                        ),
                                    itemBuilder: (_, index) => MachineCard(
                                      machine: machinesList[index],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              );
                            }).toList(),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
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
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color, radius: 5),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
