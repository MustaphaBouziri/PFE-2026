import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/presentation/machine/DeclarationLabelPage.dart';
import 'package:pfe_mes/presentation/machine/printLabelPage.dart';
import 'package:provider/provider.dart';

import '../../../../../data/machine/models/mes_operation_model.dart';
import '../../../../../domain/auth/providers/auth_provider.dart';
import '../../../../../domain/machines/providers/machineOrders_provider.dart';
import 'declaireProductionDialog.dart';
import 'declare_scrap_dialog.dart';
import 'package:barcode/src/barcode.dart';

class ActionButtonsContainer extends StatefulWidget {
  final OperationStatusAndProgressModel operationData;

  const ActionButtonsContainer({super.key, required this.operationData});

  @override
  State<ActionButtonsContainer> createState() => _ActionButtonsContainerState();
}

class _ActionButtonsContainerState extends State<ActionButtonsContainer> {
  bool _isEndLoading = false;

  bool get _isComplete => widget.operationData.progressPercent >= 100;

  String get _operationStatus =>
      widget.operationData.operationStatus.trim().toLowerCase();

  bool get _isClosed => ['finished', 'cancelled'].contains(_operationStatus);

  bool get _canDeclareProduction =>
      !['finished', 'cancelled', 'paused'].contains(_operationStatus);

  bool get _canReportReject =>
      !['finished', 'cancelled', 'paused'].contains(_operationStatus);

  bool get _canCloseOrder => !_isClosed;

  bool get _canPrintLabel =>
      _operationStatus == 'finished' ||
      widget.operationData.progressPercent >= 100;

  // ── End-order logic ───────────────────────────────────────────────────────

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

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted)
        _showErrorDialog(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isEndLoading = false);
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
            children: [
              const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A)),
              const SizedBox(width: 8),
              Text('finishProductionOrder'.tr()),
            ],
          ),
          content: Text(
            'productionCompleteConfirm'.tr(
              args: [
                widget.operationData.prodOrderNo,
                widget.operationData.progressPercent.toStringAsFixed(0),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
              ),
              child: Text(
                'finish'.tr(),
                style: const TextStyle(color: Colors.white),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            Text('cancelProductionOrder'.tr()),
          ],
        ),
        content: Text(
          'productionCancelConfirm'.tr(
            args: [
              widget.operationData.prodOrderNo,
              widget.operationData.progressPercent.toStringAsFixed(0),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('noKeepGoing'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: Text(
              'yesCancelOrder'.tr(),
              style: const TextStyle(color: Colors.white),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('error'.tr()),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
          Text(
            'quickActions'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 24),

          _ActionButton(
            title: 'declareProduction'.tr(),
            icon: Icons.add_circle_outline,
            buttonColor: const Color(0xFF2563EB),
            isEnabled: _canDeclareProduction,
            onTap: _canDeclareProduction
                ? () async {
                    final declaredQty = await showDialog<double>(
                      context: context,
                      builder: (_) => DeclareProductionDialog(
                        operationData: widget.operationData,
                      ),
                    );
                    if (declaredQty != null && declaredQty > 0 && mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeclarationLabelPage(
                            operationData: widget.operationData,
                            quantity: declaredQty.toInt(),
                          ),
                        ),
                      );
                    }
                  }
                : null,
          ),
          const SizedBox(height: 8),

          _ActionButton(
            title: 'reportReject'.tr(),
            icon: Icons.warning_amber_outlined,
            buttonColor: const Color(0xFFDC2626),
            isEnabled: _canReportReject,
            onTap: _canReportReject
                ? () => showDialog(
                    context: context,
                    builder: (_) => DeclareScrapDialog(
                      executionId: widget.operationData.executionId,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),

          _ActionButton(
            title: _isComplete
                ? 'finishProductionOrder'.tr()
                : 'cancelProductionOrder'.tr(),
            icon: _isComplete
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            buttonColor: _isComplete
                ? const Color(0xFF16A34A)
                : const Color(0xFF4B5563),
            isEnabled: _canCloseOrder,
            isLoading: _isEndLoading,
            onTap: _canCloseOrder ? _handleEndOrder : null,
          ),
          const SizedBox(height: 8),

          _ActionButton(
            title: 'printLabel'.tr(),
            icon: Icons.print_outlined,
            buttonColor: const Color(0xFF16A34A),
            isEnabled: _canPrintLabel,
            onTap: _canPrintLabel
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PrintLabelPage(operationData: widget.operationData),
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

// ── Reusable action button ────────────────────────────────────────────────────

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
        ? (_hovered ? widget.buttonColor.withOpacity(0.85) : widget.buttonColor)
        : const Color(0xFFCBD5E1);

    final Color contentColor = widget.isEnabled
        ? Colors.white
        : const Color(0xFF64748B);

    return MouseRegion(
      cursor: widget.isEnabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onEnter: (_) {
        if (widget.isEnabled) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (widget.isEnabled) setState(() => _hovered = false);
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
                      color: contentColor,
                    ),
                  )
                else
                  Icon(widget.icon, color: contentColor, size: 22),
                const SizedBox(width: 10),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: contentColor,
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
