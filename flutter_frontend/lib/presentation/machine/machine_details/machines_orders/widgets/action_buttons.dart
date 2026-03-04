import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../data/machine/models/erp_order_model.dart';
import '../../../../../domain/machines/providers/machineOrders_provider.dart';
import '../../machine_production/ordersProgressionPage.dart';

class ActionButtons extends StatelessWidget {
  final bool fullWidth;
  final MachineOrderModel order;
  final String machineNo;

  const ActionButtons({
    super.key,
    this.fullWidth = false,
    required this.order,
    required this.machineNo,
  });

  Future<void> _start(BuildContext context) async {
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
      if (!context.mounted) return;

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
  }

  Widget _startButton(BuildContext context) {
    // ── Active: Released ──────────────────────────────────────────────────
    if (order.status == "Released") {
      return ElevatedButton.icon(
        onPressed: () => _start(context),
        icon: const Icon(
          Icons.play_arrow_rounded,
          size: 16,
          color: Colors.white,
        ),
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
    }

    // ── Inactive: any other status — greyed out, non-tappable ─────────────
    return ElevatedButton.icon(
      onPressed: null,
      icon: const Icon(
        Icons.play_arrow_rounded,
        size: 16,
        color: Color(0xFFB0B7C3),
      ),
      label: const Text(
        'Start Order',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFFB0B7C3),
        ),
      ),
      style: ElevatedButton.styleFrom(
        disabledBackgroundColor: const Color(0xFFF1F5F9),
        disabledForegroundColor: const Color(0xFFB0B7C3),
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final closeBtn = OutlinedButton(
      onPressed: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Not implemented"),
          content: const Text("Close action is not implemented yet."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      ),
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

    if (fullWidth) {
      return Row(
        children: [
          Expanded(child: closeBtn),
          const SizedBox(width: 10),
          Expanded(child: _startButton(context)),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [closeBtn, const SizedBox(width: 10), _startButton(context)],
    );
  }
}
