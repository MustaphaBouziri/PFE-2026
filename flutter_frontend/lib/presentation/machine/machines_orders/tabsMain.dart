import 'package:flutter/material.dart';
import 'package:pfe_mes/presentation/machine/machines_orders/machineOrderPage.dart';
import 'package:pfe_mes/presentation/machine/machines_orders/ordersProgressionPage.dart';
import 'package:pfe_mes/presentation/widgets/navBar.dart';

class MachineMainPage extends StatefulWidget {
  final String machineNo;

  const MachineMainPage({super.key, required this.machineNo});

  @override
  State<MachineMainPage> createState() => _MachineMainPageState();
}

class _MachineMainPageState extends State<MachineMainPage> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
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
                Machineorderpage(machineNo: widget.machineNo),
                OrdersProgressionPage(machineNo: widget.machineNo),
                //Page3(machineNo: widget.machineNo),
                //Page4(machineNo: widget.machineNo),
              ],
            ),
          ),
        ],
      ),
    );
  }
}