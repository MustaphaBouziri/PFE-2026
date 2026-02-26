import 'package:flutter/material.dart';
import 'package:pfe_mes/providers/machineOrders_provider.dart';
import 'package:pfe_mes/widgets/expandableText.dart';
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
      context.read<MachineordersProvider>().getMachineOrders(widget.machineNo);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MachineordersProvider>();
    final machineOrdersList = provider.machineOrders;

    return Scaffold(
      appBar: AppBar(title: Text('Machine Orders - ${widget.machineNo}')),
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
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    color: Colors.white,
                    child: Row(children: const [Text("bluh bluh ")]),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: machineOrdersList.length,
                    itemBuilder: (context, index) {
                      final machineOrder = machineOrdersList[index];

                      final baseColor = machineOrder.status == "Firm Planned"
                          ? const Color(0xFFFFA500)
                          : machineOrder.status == "Planned"
                          ? const Color(0xFF2196F3)
                          : const Color(0xFF4CAF50);
                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 11),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: baseColor.withAlpha(40),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      machineOrder.status,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: baseColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ORD- ${machineOrder.orderNo}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Item:',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                        ExpandableText(
                                          text: machineOrder.itemDescription,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Quantity:',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                        Text(
                                          '${machineOrder.orderQuantity} unit',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Start:',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                        if (machineOrder.plannedStart != null)
                                          Text(
                                            '${machineOrder.plannedStart}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'End:',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                        if (machineOrder.plannedEnd != null)
                                          Text(
                                            '${machineOrder.plannedEnd}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton(
                                          onPressed: () {},
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            backgroundColor: Colors.white,
                                            side: const BorderSide(
                                              color: Color.fromARGB(
                                                94,
                                                158,
                                                158,
                                                158,
                                              ),
                                            ),
                                          ),
                                          child: const Text(
                                            'Close',
                                            style: TextStyle(
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton(
                                          onPressed: () {},
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            backgroundColor: const Color(
                                              0xFF0F172A,
                                            ),
                                            side: const BorderSide(
                                              color: Color.fromARGB(
                                                94,
                                                158,
                                                158,
                                                158,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.play_arrow,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 4),
                                              const Text(
                                                'Start Order',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
