import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/core/storage/session_storage.dart';
import 'package:pfe_mes/domain/admin/providers/mes_log_provider.dart';
import 'package:pfe_mes/domain/auth/providers/auth_provider.dart';
import 'package:pfe_mes/presentation/admin/machineDashBoard/widgets/machine_dashboard_card.dart';
import 'package:pfe_mes/presentation/widgets/searchBar.dart';
import 'package:provider/provider.dart';

class MachineDashboardPage extends StatefulWidget {
  const MachineDashboardPage({super.key});

  @override
  State<MachineDashboardPage> createState() => _MachineDashboardPageState();
}

class _MachineDashboardPageState extends State<MachineDashboardPage> {
  final TextEditingController searchController = TextEditingController();

  // Grid configuration breakpoints
  static const List<_GridBreakpoint> _breakpoints = [
    _GridBreakpoint(
      maxWidth: 450,
      crossCount: 1,
      aspectRatio: 1.4,
      isSmallPhone: true,
    ),
    _GridBreakpoint(
      maxWidth: 700,
      crossCount: 1,
      aspectRatio: 2.0,
      isSmallPhone: false,
    ),
    _GridBreakpoint(
      maxWidth: 1000,
      crossCount: 2,
      aspectRatio: 1.6,
      isSmallPhone: false,
    ),
    _GridBreakpoint(
      maxWidth: 1300,
      crossCount: 2,
      aspectRatio: 2,
      isSmallPhone: false,
    ),
    _GridBreakpoint(
      maxWidth: double.infinity,
      crossCount: 3,
      aspectRatio: 1.8,
      isSmallPhone: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final SessionStorage sessionStorage = SessionStorage();
      final workCenters = sessionStorage.getWorkCenters();
      context.read<LogProvider>().fetchMachineDashboard(workCenters);
    });
  }

  // Optimized helper method using lookup instead of cascading if-else
  Map<String, dynamic> _getGridParameters(double availableWidth) {
    final effectiveWidth = availableWidth - 32;
    const spacing = 12.0;

    final breakpoint = _breakpoints.firstWhere(
      (bp) => effectiveWidth < bp.maxWidth,
      orElse: () => _breakpoints.last,
    );

    return {
      'crossCount': breakpoint.crossCount,
      'childAspectRatio': breakpoint.aspectRatio,
      'maxWidth': breakpoint.crossCount == 3
          ? (effectiveWidth - (spacing * 2)) / breakpoint.crossCount
          : breakpoint.crossCount == 2
          ? (effectiveWidth - spacing) / breakpoint.crossCount
          : effectiveWidth,
      'isSmallPhone': breakpoint.isSmallPhone,
    };
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
          ? Center(child:Column(
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
              ),)
          : LayoutBuilder(
              builder: (context, constraints) {
                final gridParams = _getGridParameters(constraints.maxWidth);

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
                          crossAxisCount: gridParams['crossCount'],
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: gridParams['childAspectRatio'],
                        ),
                        itemCount: filteredMachine.length,
                        itemBuilder: (context, index) {
                          return MachineDashBoardCard(
                            machine: filteredMachine[index],
                            isSmallPhone: gridParams['isSmallPhone'],
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

// Breakpoint configuration class
class _GridBreakpoint {
  final double maxWidth;
  final int crossCount;
  final double aspectRatio;
  final bool isSmallPhone;

  const _GridBreakpoint({
    required this.maxWidth,
    required this.crossCount,
    required this.aspectRatio,
    required this.isSmallPhone,
  });
}
