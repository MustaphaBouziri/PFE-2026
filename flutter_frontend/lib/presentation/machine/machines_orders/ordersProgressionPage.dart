import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pfe_mes/domain/machines/providers/machineOrders_provider.dart';

class OrdersProgressionPage extends StatefulWidget {

  final String machineNo;

  const OrdersProgressionPage({
    super.key,
    required this.machineNo,
  });

  @override
  State<OrdersProgressionPage> createState() =>
      _OrdersProgressionPageState();
}

class _OrdersProgressionPageState
    extends State<OrdersProgressionPage> {

  @override
  Widget build(BuildContext context) {

    final provider =
        Provider.of<MachineordersProvider>(context, listen: false);

    return Scaffold(
     
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream:
            provider.getMachineOperationsStatusStream(widget.machineNo),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final machineOperationsStatus = snapshot.data!;

          if (machineOperationsStatus.isEmpty) {
            return const Center(
              child: Text(
                'No operations currently active for this machine',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: machineOperationsStatus.length,
            itemBuilder: (context, index) {

              final mos = machineOperationsStatus[index];

              final prodOrderNo = mos['prodOrderNo'];
              final operationNo = mos['operationNo'];
              final operationStatus = mos['operationStatus'];
              final lastUpdatedAt = mos['lastUpdatedAt'];

              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      Text(
                        "Order: $prodOrderNo",
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 5),

                      Text("Operation: $operationNo"),

                      const SizedBox(height: 5),

                      Text(
                        "Status: $operationStatus",
                        style: TextStyle(
                          color: operationStatus == "Running"
                              ? Colors.green
                              : operationStatus == "Paused"
                                  ? Colors.orange
                                  : Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        "Last Updated: $lastUpdatedAt",
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}