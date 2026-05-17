import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/data/admin/models/mes_log_model.dart';
import 'package:pfe_mes/presentation/widgets/expandableText.dart';

class MachineDashBoardCard extends StatelessWidget {
  final MachineDashboardModel machine;
  final bool isSmallPhone;

  const MachineDashBoardCard({
    super.key,
    required this.machine,
    required this.isSmallPhone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          // machine name + workcenter no
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ExpandableText(
                text: machine.machineName,
                style: TextStyle(
                  fontSize: isSmallPhone ? 16 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  machine.workCenterNo,
                  style: TextStyle(
                    fontSize: isSmallPhone ? 9 : 11,
                    color: const Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Text(
            '${'machineNumber'.tr()}: ${machine.machineNo}',
            style: TextStyle(
              fontSize: isSmallPhone ? 12 : 14,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              // uptime circle
              SizedBox(
                width: isSmallPhone ? 85 : 100,
                height: isSmallPhone ? 85 : 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: machine.uptimePercent / 100,
                        strokeWidth: isSmallPhone ? 10 : 12,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF16A34A),
                        ),
                      ),
                    ),
                    Text(
                      '${machine.uptimePercent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: isSmallPhone ? 13 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isSmallPhone ? 20 : 36),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    infoRow(
                      'operationFinished'.tr(),
                      machine.operationFinished.toString(),
                      isSmallPhone,
                    ),
                    infoRow(
                      'operationCancelled'.tr(),
                      machine.operationCancelled.toString(),
                      isSmallPhone,
                    ),
                    infoRow(
                      'quantityProduced'.tr(),
                      machine.totalProduced.toStringAsFixed(0),
                      isSmallPhone,
                    ),
                    infoRow(
                      'scrapDeclared'.tr(),
                      machine.totalScrap.toStringAsFixed(0),
                      isSmallPhone,
                    ),
                    infoRow(
                      'uptime'.tr(),
                      machine.formattedUptime,
                      isSmallPhone,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget infoRow(String label, String value, bool isSmall) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmall ? 6 : 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isSmall ? 13 : 16,
                color: const Color(0xFF64748B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmall ? 13 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
