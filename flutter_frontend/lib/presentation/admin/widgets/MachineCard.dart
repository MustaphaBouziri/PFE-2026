import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/data/admin/models/mes_log_model.dart';
import 'package:pfe_mes/presentation/widgets/expandableText.dart';

class AdminMachineCard extends StatelessWidget {
  final MachineDashboardModel machine;
  const AdminMachineCard({required this.machine});

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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Text(
                  'Machine Number: ${machine.machineNo}',
                  style: const TextStyle(
                    
                    color: Color(0xFF64748B),
                    
                  ),
                ),
                const SizedBox(height: 30),

          Row(
            children: [
              // uptime circle
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: machine.uptimePercent / 100,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF16A34A),
                        ),
                      ),
                    ),
                    Text(
                      '${machine.uptimePercent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 36),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    infoRow(
                      'operationsPerformed'.tr(),
                      machine.operationCount.toString(),
                    ),
                    infoRow(
                      'quantityProduced'.tr(),
                      machine.totalProduced.toStringAsFixed(0),
                    ),
                    infoRow(
                      'scrapDeclared'.tr(),
                      machine.totalScrap.toStringAsFixed(0),
                    ),
                    infoRow('uptime'.tr(), machine.formattedUptime),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
