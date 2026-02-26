import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/erp_order_model.dart';
import 'package:provider/provider.dart';

import '../../../domain/machines/providers/machineOrders_provider.dart';
import '../../widgets/expandableText.dart';

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
                                    child: _infoBlock("Item", machineOrder.itemDescription, true)
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child:_infoBlock("Quantity", machineOrder.orderQuantity, false)
                                  ),
                                  Expanded(
                                    flex: 2,
                                   child: _infoBlock("Planned Start", machineOrder.plannedStart, false)
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: _infoBlock("Planned End", machineOrder.plannedEnd, false)
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

  Widget _infoBlock(dynamic title, dynamic titleValue, bool isExpandable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: Colors.grey)),
        isExpandable
            ? ExpandableText(
                text: titleValue,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
              )
            : Text(
                titleValue,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
      ],
    );
  }
}
