import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/mes_operation_model.dart';

import '../../machine_production/models/status_style.dart';

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
    final style = operationStatusStyleFromStatus(operationData.operationStatus);

    return AppBar(
      title: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${'orderLabel'.tr()}${operationData.prodOrderNo}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                '${'operationLabel'.tr()}${operationData.operationNo}',
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
              color: style.badgeBg,
              border: Border.all(color: style.badgeBorder),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              style.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: style.badgeText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
