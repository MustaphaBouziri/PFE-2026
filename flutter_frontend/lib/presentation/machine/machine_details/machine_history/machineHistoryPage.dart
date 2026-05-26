import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/mes_operation_model.dart';
import 'package:pfe_mes/domain/machines/providers/machineOrders_provider.dart';
import 'package:pfe_mes/presentation/machine/machine_details/machine_history/widgets/history_card.dart';
import 'package:pfe_mes/presentation/machine/machine_details/machines_orders/models/badge_style.dart';
import 'package:pfe_mes/presentation/machine/machine_details/operation_detail/operationDetailPage.dart';
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

  late Future<List<OperationStatusAndProgressModel>> _historyFuture;

  @override
  void initState() {
    super.initState();

    _historyFuture = context.read<MachineordersProvider>().fetchMachineHistory(
      widget.machineNo,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      body: FutureBuilder<List<OperationStatusAndProgressModel>>(
        future: _historyFuture,

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
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
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF94A3B8),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            );
          }

          final allOrders = snapshot.data ?? [];
          final filteredOrdersHistory = allOrders.where((order) {
            final query = searchController.text.toLowerCase();

            return order.prodOrderNo.toLowerCase().contains(query) ||
                order.itemDescription.toLowerCase().contains(query) ||
                order.startDateTime.toLowerCase().contains(query);
          }).toList();

          filteredOrdersHistory.sort((a, b) {
            final comparison = a.startDateTime.compareTo(b.startDateTime);

            return sortAscending ? comparison : -comparison;
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Padding(
                padding: const EdgeInsets.all(16),

                child: GlobalSearchBar(
                  controller: searchController,

                  onSearchChanged: (_) {
                    setState(() {});
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
                child: filteredOrdersHistory.isEmpty
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
                              'noHistoryFound'.tr(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF94A3B8),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),

                        itemCount: filteredOrdersHistory.length,

                        itemBuilder: (context, index) {
                          final orderHistory = filteredOrdersHistory[index];

                          final style = badgeStyleFromStatus(
                            orderHistory.operationStatus,
                          );

                          return HistoryCard(
                            order: orderHistory,
                            badgeStyle: style,

                            onTap: () {
                              Navigator.push(
                                context,

                                MaterialPageRoute(
                                  builder: (_) => OperationDetailPage(
                                    operationData: orderHistory,
                                  ),
                                ),
                              );
                            },
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
