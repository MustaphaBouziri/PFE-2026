import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/machines/providers/machineOrders_provider.dart';
import 'models/badge_style.dart';
import 'widgets/order_card.dart';

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
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: machineOrdersList.length,
                    itemBuilder: (context, index) {
                      final order = machineOrdersList[index];
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
