import 'package:flutter/material.dart';
import 'package:pfe_mes/domain/machines/providers/machineOrders_provider.dart';
import 'package:pfe_mes/presentation/machine/machine_details/machine_production/ordersProgressionPage.dart';
import 'package:pfe_mes/presentation/machine/machine_details/machines_orders/models/badge_style.dart';
import 'package:pfe_mes/presentation/machine/machine_details/machines_orders/widgets/order_card.dart';
import 'package:pfe_mes/presentation/widgets/searchBar.dart';
import 'package:provider/provider.dart';

class MachineHistoryPage extends StatefulWidget {
  final String machineNo;

  const MachineHistoryPage({super.key, required this.machineNo});

  @override
  State<MachineHistoryPage> createState() => _MachineHistoryPageState();
}

class _MachineHistoryPageState extends State<MachineHistoryPage> {
  bool sortAscending = true;
  final TextEditingController searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MachineordersProvider>().fetchMachineHistory(
        widget.machineNo,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MachineordersProvider>();
    final machineOrdersList = provider.machineOrdersHistory;

    final filteredOrdersHistory = machineOrdersList.where((order) {
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

      return searchMatch;
    }).toList();

    filteredOrdersHistory.sort((a, b) {
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
                    itemCount: filteredOrdersHistory.length,
                    itemBuilder: (context, index) {
                      final orderHistory = filteredOrdersHistory[index];
                      final style = badgeStyleFromStatus(orderHistory.status);

                      return OrderCard(
                        order: orderHistory,
                        badgeStyle: style,
                        machineNo: widget.machineNo,
                        showActions: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrdersProgressionPage(
                                machineNo: widget.machineNo,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
