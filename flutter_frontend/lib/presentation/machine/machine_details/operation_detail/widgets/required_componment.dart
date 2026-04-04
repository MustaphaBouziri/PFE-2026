import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/mes_componentConsumption_model.dart';
import 'package:pfe_mes/presentation/machine/machine_details/operation_detail/widgets/scanner_dialog.dart';

class RequiredComponent extends StatelessWidget {
  final List<ComponentConsumptionModel> components;
  final double totalProduced;
  final String executionId;
  final GlobalKey? scanButtonKey;

  const RequiredComponent({
    super.key,
    required this.components,
    required this.totalProduced,
    required this.executionId,
    this.scanButtonKey,
  });

  static const statusMissing = 'missing';
  static const statusLowStock = 'lowStock';
  static const statusAvailable = 'available';

  String getStatus(double planned, double scanned) {
    if (scanned == 0) return statusMissing;
    if (scanned < planned) return statusLowStock;
    return statusAvailable;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "requiredComponents".tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Container(
                key: scanButtonKey,
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ScannerWidget(executionId:executionId),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'scanItem'.tr(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: components.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final component = components[index];

              final planned = component.plannedQuantity;
              final isSpecific = component.belongsToThisOperation;

              // how much u consumed of this material
              final consumed = totalProduced * component.quantityPer;
              // how qte u scanned of this item
              final scanned = component.quantityScanned;

              // remaining =  the qte u scanned - what was consumed
              final remaining = scanned - consumed;

              final status = isSpecific ? getStatus(planned, scanned) : '';

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: !isSpecific
                      ? const Color(0xFFF1F5F9)
                      : status == statusAvailable
                      ? const Color(0xFFF0FDF4)
                      : status == statusLowStock
                      ? const Color(0xFFFEFCE8)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: !isSpecific
                        ? const Color(0xFFCBD5F5).withOpacity(0.2)
                        : status == statusAvailable
                        ? const Color(0xFF1AA44D).withOpacity(0.2)
                        : status == statusLowStock
                        ? const Color(0xFFD39D2B).withOpacity(0.2)
                        : const Color(0xFFE03B3B).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      !isSpecific
                          ? Icons.remove_circle_outline
                          : status == 'Available'
                          ? Icons.check_circle_outline
                          : status == 'Low Stock'
                          ? Icons.warning_amber_outlined
                          : Icons.cancel_outlined,
                      color: !isSpecific
                          ? const Color(0xFF64748B)
                          : status == 'Available'
                          ? const Color(0xFF1AA44D)
                          : status == 'Low Stock'
                          ? const Color(0xFFD39D2B)
                          : const Color(0xFFE03B3B),
                      size: 22,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            component.itemDescription,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${scanned.toString()} ${'scanned'.tr()} | ${consumed.toString()} ${'used'.tr()} | ${remaining.toString()} ${'left'.tr()}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (isSpecific)
                      Text(
                        status.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: status == statusAvailable
                              ? const Color(0xFF1AA44D)
                              : status == statusLowStock
                              ? const Color(0xFFD39D2B)
                              : const Color(0xFFE03B3B),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}