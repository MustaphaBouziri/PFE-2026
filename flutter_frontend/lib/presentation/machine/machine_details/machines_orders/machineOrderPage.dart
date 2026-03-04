import 'package:flutter/material.dart';
import 'package:pfe_mes/presentation/widgets/searchBar.dart';
import 'package:provider/provider.dart';

import '../../../../domain/machines/providers/machineOrders_provider.dart';
import 'models/badge_style.dart';
import 'widgets/order_card.dart';

class Machineorderpage extends StatefulWidget {
  final String machineNo;

  const Machineorderpage({super.key, required this.machineNo});

  @override
  State<Machineorderpage> createState() => _MachineorderpageState();
}

class _MachineorderpageState extends State<Machineorderpage> {
  String selectedStatus = 'All';
  final List<String> status = ['All', 'Planned', 'Firm Planned', 'Released'];
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
          selectedStatus == 'All' || order.status == selectedStatus;
      final bool searchMatch =
          order.orderNo.toLowerCase().contains(
            searchController.text.toLowerCase(),
          ) ||
          order.itemDescription.toLowerCase().contains(
            searchController.text.toLowerCase(),
          ) ||
          order.plannedStart.toString().contains(
            searchController.text.toLowerCase(),
          ) ||
          order.plannedEnd.toString().toLowerCase().contains(
            searchController.text.toLowerCase(),
          );

      return statusMatch && searchMatch;
    }).toList();

    filteredOrders.sort((a, b) {
      final comparison = a.plannedStart!.compareTo(b.plannedStart!);
      return sortAscending ? comparison : -comparison;
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
          ? Center(child: Text(provider.errorMessage!))
          : machineOrdersList.isEmpty
          ? const Center(child: Text('No Orders Found'))
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
                        opacity: order.status == 'Firm Planned' ? 1.0 : 0.75,
                        child: OrderCard(
                          order: order,
                          badgeStyle: style,
                          machineNo: widget.machineNo,
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
