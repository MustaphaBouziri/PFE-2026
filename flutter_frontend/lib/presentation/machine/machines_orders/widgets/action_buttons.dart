import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/machine/models/erp_order_model.dart';
import '../../../../domain/machines/providers/machineOrders_provider.dart';
import '../ordersProgressionPage.dart';

class ActionButtons extends StatelessWidget {
  final bool fullWidth;
  final MachineOrderModel order;
  final String machineNo;

  ActionButtons({
    this.fullWidth = false,
    required this.order,
    required this.machineNo,
  });

  @override
  Widget build(BuildContext context) {
    final closeBtn = OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF334155),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: const Text(
        'Close',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );

    final startBtn = ElevatedButton.icon(
      onPressed: () async {
        try {
          final provider = context.read<MachineordersProvider>();
          final success = await provider.startOrder(
            order.orderNo,
            order.operationNo,
            machineNo,
          );
          if (!context.mounted) return;
          if (success) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrdersProgressionPage(machineNo: machineNo),
              ),
            );
          }
        } catch (e) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Cannot Start Operation"),
              content: Text(e.toString().replaceFirst("Exception: ", "")),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
      },
      icon: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
      label: const Text(
        'Start Order',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0F172A),
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );

    if (fullWidth) {
      return Row(
        children: [
          Expanded(child: closeBtn),
          const SizedBox(width: 10),
          Expanded(child: startBtn),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [closeBtn, const SizedBox(width: 10), startBtn],
    );
  }
}
