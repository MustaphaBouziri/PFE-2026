import 'dart:async';
import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/core/storage/session_storage.dart';
import 'package:pfe_mes/data/machine/models/mes_machine_model.dart';
import 'package:pfe_mes/main.dart';
import 'package:pfe_mes/presentation/admin/machineDashBoard/machineDashboardPage.dart';
import 'package:pfe_mes/presentation/ai/ai_chat_page.dart';
import 'package:pfe_mes/presentation/profilePage.dart';
import 'package:pfe_mes/presentation/widgets/searchBar.dart';
import 'package:provider/provider.dart';

import '../../../domain/auth/providers/auth_provider.dart';
import '../../../domain/machines/providers/mes_machines_provider.dart';
import '../../tutorials/machine_list_tutorial.dart';
import 'widgets/machine_card.dart';

class Machinelistpage extends StatefulWidget {
  const Machinelistpage({super.key});

  @override
  State<Machinelistpage> createState() => _MachinelistpageState();
}

class _MachinelistpageState extends State<Machinelistpage> with RouteAware {
  final SessionStorage _sessionStorage = SessionStorage();
  final TextEditingController searchController = TextEditingController();

  final ValueNotifier<String> searchQuery = ValueNotifier('');
  final ValueNotifier<String> statusFilter = ValueNotifier('all');
  final ValueNotifier<Map<String, List<MachineModel>>> dataNotifier =
      ValueNotifier({});
  final ValueNotifier<bool> loadingNotifier = ValueNotifier(true);
  // chat false = chat close true = chat open
  final ValueNotifier<bool> chatOpen = ValueNotifier(false);

  final List<String> statusOptions = ['all', 'working', 'idle'];
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  void _startStream() {
    if (_subscription != null) {
      return;
    }

    final provider = context.read<MesMachinesProvider>();
    _subscription = provider
        .streamOrderedMachinePerDepartments(_workCenterIds)
        .listen((event) {
          if (!mounted) return;

          dataNotifier.value = event;
          loadingNotifier.value = false;
        });
  }

  void _stopStream() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void didPushNext() {
    _stopStream();
    super.didPushNext();
  }

  @override
  void didPopNext() {
    if (_workCenterIds.isNotEmpty) {
      _startStream();
    }
    super.didPopNext();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _stopStream();
    searchController.dispose();
    searchQuery.dispose();
    statusFilter.dispose();
    dataNotifier.dispose();
    loadingNotifier.dispose();
    chatOpen.dispose();
    super.dispose();
  }

  String _resolveRole() {
    return _sessionStorage.getRole().trim().toLowerCase();
  }

  List<String> _resolveWorkCenterIds() {
    final wcs = _sessionStorage.getWorkCenters();
    return wcs.map((e) => e.toString()).toList();
  }

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
            status == 'all' ||
            machine.status.toLowerCase() == status.toLowerCase();

        return matchesSearch && matchesStatus;
      }).toList();

      if (filtered.isNotEmpty) {
        result[entry.key] = filtered;
      }
    }

    return result;
  }

  void _openChat(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= 600) {
      // for larger screens open the chat panel instead of a dialog
      chatOpen.value = true;
    } else {
      // for smaller screens open the chat as a full-screen dialog
      showDialog(
        context: context,
        builder: (context) => const AiChatPage(isDialog: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD:flutter_frontend/lib/presentation/machine/machine_List/machineListPage.dart
=======
    // final authProvider = context.read<AuthProvider>();
    final role = _sessionStorage.getRole().toString();
>>>>>>> temp2:flutter_frontend/lib/presentation/machine/machineList/machineListPage.dart
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final isTablet = width >= 820 && width <= 1032;
<<<<<<< HEAD:flutter_frontend/lib/presentation/machine/machine_List/machineListPage.dart
    final role = _resolveRole();
=======
>>>>>>> temp2:flutter_frontend/lib/presentation/machine/machineList/machineListPage.dart

    return Scaffold(
      // chat button : listen to chatOpen (true or false )
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: chatOpen,
        builder: (_, isChatOpen, __) {
          final isWide = MediaQuery.of(context).size.width >= 600;
          // this to stop making the button on top of the chat pannel when its open (chatOpen = true) and the screen is anything but Phone (width >= 600)
          if (isChatOpen && isWide) return const SizedBox();
          // else show the button
          return IconButton(
            onPressed: () => _openChat(context),
            icon: const Icon(Icons.chat_outlined, size: 30),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: const Color(0xFFE2E8F0),
            ),
          );
        },
      ),
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
                    icon: const Icon(
                      Icons.dashboard,
                      size: 16,
                      color: Color(0xFF0F172A),
                    ),
                    label: Text(
                      'machineDashboard'.tr(),
                      style: const TextStyle(color: Color(0xFF0F172A)),
                    ),
                  ),
          ],
        ),
      ),
      //listens to chatOpen to decide whether to show the chat panel as a dialog
      body: ValueListenableBuilder<bool>(
        valueListenable: chatOpen,
        builder: (_, isChatOpen, __) {
          return Stack(
            children: [
              // body
              _buildBody(),

              // chat panel for larger screens
              if (isChatOpen && MediaQuery.of(context).size.width >= 600)
                Positioned(
                  right: 0,
                  bottom: 0,
                  top: isTablet ? null : 0,
                  height: isTablet ? height * 0.8 : null,
                  width: 400,
                  child: AiChatPage(
                    isDialog: false,
                    onClose: () => chatOpen.value = false,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_workCenterIds.isEmpty) {
      return Center(child: Text('noWorkCenterAssigned'.tr()));
    }

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
                label: 'working'.tr(),
              ),
              const SizedBox(width: 8),
              _statusLegendBadge(
                color: const Color.fromARGB(255, 134, 134, 134),
                label: 'idle'.tr(),
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
            onDropdownChanged: (val) => statusFilter.value = val ?? 'all',
          ),
        ),
        const SizedBox(height: 8),

        // machine list
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

                      if (groupedMachines.isEmpty) {
                        return Center(child: Text('noMachinesFound'.tr()));
                      }

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
                                              : constraints.maxWidth < 1440
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
