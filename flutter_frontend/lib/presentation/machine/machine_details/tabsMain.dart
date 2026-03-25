import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/machines/providers/machineOrders_provider.dart';
import '../../widgets/navBar.dart';
import 'machine_consumption/machineConsumptionPage.dart';
import 'machine_history/machineHistoryPage.dart';
import 'machines_orders/machineOrderPage.dart';
import 'machine_production/ordersProgressionPage.dart';

class MachineMainPage extends StatefulWidget {
  final String machineNo;
  final String machineName;

  const MachineMainPage({
    super.key,
    required this.machineNo,
    required this.machineName,
  });

  @override
  State<MachineMainPage> createState() => _MachineMainPageState();
}

class _MachineMainPageState extends State<MachineMainPage> {
  int selectedIndex = 0;

  void _handleStartOrderSuccess() {
    setState(() {
      selectedIndex = 1;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MachineordersProvider>().getMachineOrders(widget.machineNo);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.precision_manufacturing_outlined,
              size: 20,
              color: Colors.grey,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.machineName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'ID: ${widget.machineNo}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          TopNavigationBar(
            selectedIndex: selectedIndex,
            onTabChanged: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
          ),
          Expanded(
            child: IndexedStack(
              index: selectedIndex,
              children: [
                Machineorderpage(
                  machineNo: widget.machineNo,
                  onSwitchToProgress: _handleStartOrderSuccess,
                ),
                OrdersProgressionPage(machineNo: widget.machineNo),
                OrderConsumptionPage(),
                MachineHistoryPage(machineNo: widget.machineNo),
              ],
            ),
          ),
        ],
      ),
    );
  }
}