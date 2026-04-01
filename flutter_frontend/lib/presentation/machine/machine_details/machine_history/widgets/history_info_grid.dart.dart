import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/mes_operation_model.dart';
import 'package:pfe_mes/presentation/machine/machine_details/machines_orders/widgets/info_cell.dart';
import 'package:pfe_mes/presentation/machine/machine_details/shared/utils.dart';

class HistoryInfoGrid extends StatelessWidget {
  final OperationStatusAndProgressModel order;

  const HistoryInfoGrid({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InfoCell(label: 'product'.tr(), value: order.itemDescription.isEmpty ? '—' : order.itemDescription),
        const SizedBox(width: 16),
        InfoCell(label: 'producedQuantity'.tr(), value: '${order.totalProducedQuantity.toInt()} ${'unit'.tr()}'),
        const SizedBox(width: 16),
        InfoCell(
          label: 'startedAt'.tr(),
          value: Utils.formatTimestamp(order.startDateTime),
        ),
        const SizedBox(width: 16),
        InfoCell(
          label: 'endedAt'.tr(),
          value: order.endDateTime.isEmpty ? 'inProgress'.tr() : Utils.formatTimestamp(order.endDateTime),
        ),
      ],
    );
  }
}