import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/presentation/machine/machine_details/shared/utils.dart';
import 'package:provider/provider.dart';

import '../../../../domain/machines/providers/machineOrders_provider.dart';
import '../../../widgets/searchBar.dart';
import 'models/badge_style.dart';
import 'widgets/order_card.dart';

class Machineorderpage extends StatefulWidget {
  final String machineNo;
  final VoidCallback onSwitchToProgress;

  const Machineorderpage({
    super.key,
    required this.machineNo,
    required this.onSwitchToProgress,
  });

  @override
  State<Machineorderpage> createState() => _MachineorderpageState();
}

class _MachineorderpageState extends State<Machineorderpage> {
  String selectedStatus = 'all';
  final List<String> status = ['all', 'Planned', 'Firm Planned', 'Released'];
  bool sortAscending = true;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MachineordersProvider>().getMachineOrders(widget.machineNo);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MachineordersProvider>();
    final machineOrdersList = provider.machineOrders;

    final filteredOrders = machineOrdersList.where((order) {
      final bool statusMatch =
          selectedStatus == 'all' || order.status == selectedStatus;
      final bool searchMatch =
          order.orderNo.toLowerCase().contains(
            searchController.text.toLowerCase(),
          ) ||
          order.itemDescription.toLowerCase().contains(
            searchController.text.toLowerCase(),
          ) ||
          Utils.formatSearchableDate(order.plannedStart).toLowerCase().contains(
            searchController.text.toLowerCase(),
          ) ||
          Utils.formatSearchableDate(order.plannedEnd).toLowerCase().contains(
            searchController.text.toLowerCase(),
          );

      return statusMatch && searchMatch;
    }).toList();

    filteredOrders.sort((a, b) {
  // Status priority: Released=0, Firm Planned=1, Planned=2
  int statusPriority(String? status) {
    switch (status) {
      case 'Released': return 0;
      case 'Firm Planned': return 1;
      case 'Planned': return 2;
      default: return 3;
    }
  }

  final statusComparison = statusPriority(a.status).compareTo(statusPriority(b.status));
  if (statusComparison != 0) return statusComparison;

  // Parse then strip time — compare DATE only
  final aRaw = DateTime.tryParse(a.plannedStart.toString());
  final bRaw = DateTime.tryParse(b.plannedStart.toString());

  if (aRaw == null && bRaw == null) return 0;
  if (aRaw == null) return 1;
  if (bRaw == null) return -1;

  // Date only (year, month, day) — ignore hours/minutes
  final aDate = DateTime(aRaw.year, aRaw.month, aRaw.day);
  final bDate = DateTime(bRaw.year, bRaw.month, bRaw.day);

  final dateComparison = aDate.compareTo(bDate);
  return sortAscending ? dateComparison : -dateComparison;
});

    print('Filtered Orders: ${filteredOrders.length}'); // Debugging line
    for (final order in filteredOrders) {
      print('Order No: ${order.orderNo}, Status: ${order.status}, Planned Start: ${order.plannedStart}, Description: ${order.description}'); // Debugging line
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
          ? Center(
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
          : machineOrdersList.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 48,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'noOrdersFound'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF94A3B8),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GlobalSearchBar(
                    controller: searchController,
                    onSearchChanged: (_) => setState(() {}),
                    dropdownItems: status,
                    selectedValue: selectedStatus,
                    onDropdownChanged: (value) {
                      setState(() => selectedStatus = value!);
                    },
                    sortAscending: sortAscending,
                    onSortPressed: () {
                      setState(() {
                        sortAscending = !sortAscending;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      final style = badgeStyleFromStatus(order.status);

                      return Opacity(
                        opacity: order.status == 'Released' ? 1.0 : 0.75,
                        child: OrderCard(
                          order: order,
                          badgeStyle: style,
                          machineNo: widget.machineNo,
                          onSwitchToProgress: widget.onSwitchToProgress,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
