import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pfe_mes/data/machine/models/mes_operation_model.dart';
import 'package:pfe_mes/presentation/machine/machine_details/operation_detail/widgets/declaireProductionDialog.dart';

import '../../../../../domain/auth/providers/auth_provider.dart';
import '../../../../../domain/machines/providers/machineOrders_provider.dart';

class ActionButtonsContainer extends StatefulWidget {
  final OperationStatusAndProgressModel operationData;

  const ActionButtonsContainer({
    super.key,
    required this.operationData,
  });

  @override
  State<ActionButtonsContainer> createState() => _ActionButtonsContainerState();
}

class _ActionButtonsContainerState extends State<ActionButtonsContainer> {
  bool _isEndLoading = false;

  bool get _isComplete => widget.operationData.progressPercent >= 100;

  Future<void> _handleEndOrder() async {
    if (_isEndLoading) return;

    final confirmed = await _showEndConfirmDialog();
    if (confirmed != true || !mounted) return;

    setState(() => _isEndLoading = true);

    try {
      final provider = context.read<MachineordersProvider>();

      if (_isComplete) {
        await provider.finishOperation(
          machineNo: widget.operationData.machineNo,
          prodOrderNo: widget.operationData.prodOrderNo,
          operationNo: widget.operationData.operationNo,
        );
      } else {
        await provider.cancelOperation(
          machineNo: widget.operationData.machineNo,
          prodOrderNo: widget.operationData.prodOrderNo,
          operationNo: widget.operationData.operationNo,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isEndLoading = false);
      }
    }
  }

  Future<bool?> _showEndConfirmDialog() {
    if (_isComplete) {
      return showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: const [
              Icon(Icons.check_circle_outline, color: Color(0xFF16A34A)),
              SizedBox(width: 8),
              Text('Finish Production Order'),
            ],
          ),
          content: Text(
            'Production for order ${widget.operationData.prodOrderNo} '
                'is complete (${widget.operationData.progressPercent.toStringAsFixed(0)}%).\n\n'
                'Confirm to mark the order as finished and release the machine.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
              ),
              child: const Text(
                'Finish',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Cancel Production Order'),
          ],
        ),
        content: Text(
          'Order ${widget.operationData.prodOrderNo} is only '
              '${widget.operationData.progressPercent.toStringAsFixed(0)}% complete.\n\n'
              'This action will cancel the order and release the machine. '
              'This cannot be undone.\n\nAre you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Keep Going'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text(
              'Yes, Cancel Order',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final userRole =
        authProvider.userData?['role']?.toString().trim().toLowerCase() ?? '';

    final operationStatus =
    widget.operationData.operationStatus.trim().toLowerCase();

    final bool isSupervisor = userRole == 'supervisor';
    final bool isClosed = ['finished','cancelled'].contains(operationStatus);

    final bool canDeclareProduction = !['finished','cancelled','paused'].contains(operationStatus);
    final bool canReportReject = !['finished','cancelled','paused'].contains(operationStatus);
    final bool canCloseProductionOrder = /*isSupervisor &&*/ !isClosed;
    final bool canPrintLabel =
        ['finished'].contains(operationStatus) || widget.operationData.progressPercent >= 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 24),

          _ActionButton(
            title: 'Declare Production',
            icon: Icons.add_circle_outline,
            buttonColor: const Color(0xFF2563EB),
            isEnabled: canDeclareProduction,
            onTap: canDeclareProduction
                ? () => showDialog(
              context: context,
              builder: (context) => DeclareProductionDialog(
                operationData: widget.operationData,
              ),
            )
                : null,
          ),
          const SizedBox(height: 8),

          _ActionButton(
            title: 'Report Reject',
            icon: Icons.warning_amber_outlined,
            buttonColor: const Color(0xFFDC2626),
            isEnabled: canReportReject,
            onTap: canReportReject ? () {} : null,
          ),
          const SizedBox(height: 8),

          _ActionButton(
            title:
            _isComplete ? 'Finish Production Order' : 'Cancel Production Order',
            icon: _isComplete
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            buttonColor: _isComplete
                ? const Color(0xFF16A34A)
                : const Color(0xFF4B5563),
            isEnabled: canCloseProductionOrder,
            isLoading: _isEndLoading,
            onTap: canCloseProductionOrder ? _handleEndOrder : null,
          ),
          const SizedBox(height: 8),

          _ActionButton(
            title: 'Print Label',
            icon: Icons.print_outlined,
            buttonColor: const Color(0xFF16A34A),
            isEnabled: canPrintLabel,
            onTap: canPrintLabel ? () {} : null,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color buttonColor;
  final VoidCallback? onTap;
  final bool isEnabled;
  final bool isLoading;

  const _ActionButton({
    required this.title,
    required this.icon,
    required this.buttonColor,
    this.onTap,
    this.isEnabled = true,
    this.isLoading = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = widget.isEnabled
        ? (_hovered
        ? widget.buttonColor.withOpacity(0.85)
        : widget.buttonColor)
        : const Color(0xFFCBD5E1);

    final Color textAndIconColor =
    widget.isEnabled ? Colors.white : const Color(0xFF64748B);

    return MouseRegion(
      cursor: widget.isEnabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onEnter: (_) {
        if (widget.isEnabled) {
          setState(() => _hovered = true);
        }
      },
      onExit: (_) {
        if (widget.isEnabled) {
          setState(() => _hovered = false);
        }
      },
      child: Material(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: (widget.isEnabled && !widget.isLoading) ? widget.onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textAndIconColor,
                    ),
                  )
                else
                  Icon(widget.icon, color: textAndIconColor, size: 22),
                const SizedBox(width: 10),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: textAndIconColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}