import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pfe_mes/data/machine/models/mes_operation_model.dart';
import 'package:pfe_mes/presentation/machine/machine_details/operation_detail/widgets/declaireProductionDialog.dart';

import '../../../../../domain/auth/providers/auth_provider.dart';

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
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final userRole =
        authProvider.userData?['role']?.toString().trim().toLowerCase() ?? '';

    final operationStatus =
    widget.operationData.operationStatus.trim().toLowerCase();

    final bool isOperator = userRole == 'operator';
    final bool isSupervisor = userRole == 'supervisor';
    final bool isFinished = operationStatus == 'finished';

    final bool canDeclareProduction = !isFinished;
    final bool canReportReject = !isFinished;
    final bool canEndProductionOrder = !isFinished && isSupervisor;

    // Print label stays enabled if finished, otherwise only at 100%+
    final bool canPrintLabel =
        isFinished || widget.operationData.progressPercent >= 100;

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
            "Quick Actions",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 24),
          _ActionButton(
            title: "Declare Production",
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
            title: "Report Reject",
            icon: Icons.warning_amber_outlined,
            buttonColor: const Color(0xFFDC2626),
            isEnabled: canReportReject,
            onTap: canReportReject ? () {} : null,
          ),
          const SizedBox(height: 8),
          _ActionButton(
            title: "End Production Order",
            icon: Icons.check,
            buttonColor: const Color(0xFF4B5563),
            isEnabled: canEndProductionOrder,
            onTap: canEndProductionOrder ? () {} : null,
          ),
          const SizedBox(height: 8),
          _ActionButton(
            title: "Print Label",
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

  const _ActionButton({
    required this.title,
    required this.icon,
    required this.buttonColor,
    this.onTap,
    this.isEnabled = true,
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

    final Color textAndIconColor = widget.isEnabled
        ? Colors.white
        : const Color(0xFF64748B);

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
          onTap: widget.isEnabled ? widget.onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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