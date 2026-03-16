import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/mes_operation_model.dart';

class OperationAppbar extends StatelessWidget implements PreferredSizeWidget {
  final OperationStatusAndProgressModel operationData;
  final bool isPhone;

  const OperationAppbar({
    super.key,
    required this.operationData,
    required this.isPhone,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Order: " + operationData.prodOrderNo,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                "Operation: " + operationData.operationNo,
                style: TextStyle(
                  fontSize: isPhone ? 13 : 11,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isPhone ? 11 : 14,
              vertical: isPhone ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: operationData.operationStatus == 'Running'
                  ? const Color(0xFFECFDF5)
                  : operationData.operationStatus == 'Paused'
                      ? const Color(0xFFFFFBEB)
                      : const Color(0xFFEFF6FF),
              border: Border.all(
                color: operationData.operationStatus == 'Running'
                    ? const Color(0xFFA7F3D0)
                    : operationData.operationStatus == 'Paused'
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFFBFDBFE),
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              operationData.operationStatus,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: operationData.operationStatus == 'Running'
                    ? const Color(0xFF065F46)
                    : operationData.operationStatus == 'Paused'
                        ? const Color(0xFF92400E)
                        : const Color(0xFF1E40AF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}