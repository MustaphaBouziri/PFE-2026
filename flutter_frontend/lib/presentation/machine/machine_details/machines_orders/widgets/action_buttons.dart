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
  bool _isStartLoading = false;
  bool _isCancelLoading = false;

  bool get _canStart => widget.order.status == 'Released';

  // ── Start ──────────────────────────────────────────────────────────────────

  Future<void> _handleStart() async {
    if (_isStartLoading || !_canStart) return;
    setState(() => _isStartLoading = true);

    try {
      final provider = context.read<MachineordersProvider>();
      final success = await provider.startOrder(
        widget.order.orderNo,
        widget.order.operationNo,
        widget.machineNo,
      );
      if (!mounted) return;
      if (success) widget.onSwitchToProgress?.call();
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isStartLoading = false);
    }
  }

  // ── Close (cancel — orders page orders are never at 100 %) ────────────────

  Future<void> _handleClose() async {
    if (_isCancelLoading) return;

    // Confirm before cancelling
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Cancel Order'),
        content: Text(
          'Are you sure you want to cancel order ${widget.order.orderNo}?\n\n'
              'This will mark the operation as finished and free the machine.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isCancelLoading = true);

    try {
      final provider = context.read<MachineordersProvider>();

      await provider.cancelOperation(
        machineNo: widget.machineNo,
        prodOrderNo: widget.order.orderNo,
        operationNo: widget.order.operationNo,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isCancelLoading = false);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildStartButton() {
    if (_canStart) {
      return ElevatedButton.icon(
        onPressed: _isStartLoading ? null : _handleStart,
        icon: _isStartLoading
            ? const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Colors.white),
        )
            : const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
        label: const Text(
          'Start Order',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          disabledBackgroundColor: const Color(0xFF0F172A),
          disabledForegroundColor: Colors.white,
          foregroundColor: Colors.white,
          overlayColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      );
    }

    // Disabled appearance when status is not Released
    return ElevatedButton.icon(
      onPressed: null,
      icon: const Icon(Icons.play_arrow_rounded,
          size: 16, color: Color(0xFFB0B7C3)),
      label: const Text(
        'Start Order',
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFFB0B7C3)),
      ),
      style: ElevatedButton.styleFrom(
        disabledBackgroundColor: const Color(0xFFF1F5F9),
        disabledForegroundColor: const Color(0xFFB0B7C3),
        shadowColor: Colors.transparent,
        elevation: 0,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  Widget _buildCloseButton() {
    return OutlinedButton.icon(
      onPressed: _isCancelLoading ? null : _handleClose,
      icon: _isCancelLoading
          ? const SizedBox(
        width: 14,
        height: 14,
        child:
        CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF334155)),
      )
          : const Icon(Icons.close_rounded, size: 16),
      label: const Text(
        'Close',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF334155),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final closeBtn = _buildCloseButton();
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
