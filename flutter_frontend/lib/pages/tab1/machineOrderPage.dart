import 'package:flutter/material.dart';
import 'package:pfe_mes/providers/machineOrders_provider.dart';
import 'package:provider/provider.dart';

class Machineorderpage extends StatefulWidget {
  final String machineNo;
  const Machineorderpage({super.key, required this.machineNo});

  @override
  State<Machineorderpage> createState() => _MachineorderpageState();
}

class _MachineorderpageState extends State<Machineorderpage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<MachineordersProvider>()
          .getMachineOrders(widget.machineNo);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MachineordersProvider>();
    final machineOrdersList = provider.machineOrders;

    return Scaffold(
      appBar: AppBar(
        title: Text('Machine Orders - ${widget.machineNo}'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
              ? Center(child: Text(provider.errorMessage!))
              : machineOrdersList.isEmpty
                  ? const Center(child: Text('No Orders Found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: machineOrdersList.length,
                      itemBuilder: (context, index) {
                        final machineOrder = machineOrdersList[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Order: ${machineOrder.orderNo}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        machineOrder.status,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                            
                                Text(
                                  'Item: ${machineOrder.itemNo}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  machineOrder.itemDescription,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),

                                const SizedBox(height: 8),

                          
                                Text(
                                  'Operation: ${machineOrder.operationNo} - ${machineOrder.operationDescription}',
                                  style: const TextStyle(fontSize: 14),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  'Quantity: ${machineOrder.orderQuantity}',
                                  style: const TextStyle(fontSize: 14),
                                ),

                                const SizedBox(height: 8),

                            
                                if (machineOrder.plannedStart != null)
                                  Text(
                                    'Start: ${machineOrder.plannedStart}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                if (machineOrder.plannedEnd != null)
                                  Text(
                                    'End: ${machineOrder.plannedEnd}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}