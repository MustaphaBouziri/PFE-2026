import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../data/machine/models/erp_order_model.dart';
import '../../../../../domain/machines/providers/machineOrders_provider.dart';

class ActionButtons extends StatefulWidget {
  final MachineOrderModel order;
  final String machineNo;
  final bool fullWidth;
  final VoidCallback? onSwitchToProgress;

  const ActionButtons({
    super.key,
    required this.order,
    required this.machineNo,
    this.fullWidth = false,
    this.onSwitchToProgress,
  });

  @override
  State<ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<ActionButtons> {
  bool _isLoading = false;

  bool get _canStart => widget.order.status == "Released";

  Future<void> _handleStart() async {
    if (_isLoading || !_canStart) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<MachineordersProvider>();

      final success = await provider.startOrder(
        widget.order.orderNo,
        widget.order.operationNo,
        widget.machineNo,
      );

      if (!mounted) return;

      if (success) {
        widget.onSwitchToProgress?.call();
      }
    } catch (e) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Cannot Start Operation"),
          content: Text(e.toString().replaceFirst("Exception: ", "")),
          backgroundColor: Colors.white,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildStartButton() {
    if (_canStart) {
      return ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleStart,
        icon: _isLoading
            ? const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Icon(
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
          disabledBackgroundColor: const Color(0xFF0F172A),
          disabledForegroundColor: Colors.white,
          foregroundColor: Colors.white,
          overlayColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      );
    }

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return OutlinedButton(
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: const Text(
        'Close',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final closeBtn = _buildCloseButton(context);
    final startBtn = _buildStartButton();

    if (widget.fullWidth) {
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
      children: [
        closeBtn,
        const SizedBox(width: 10),
        startBtn,
      ],
    );
  }
}