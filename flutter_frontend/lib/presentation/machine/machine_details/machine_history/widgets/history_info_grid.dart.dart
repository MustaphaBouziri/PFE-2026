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
        InfoCell(label: 'Product', value: order.itemDescription.isEmpty ? '—' : order.itemDescription),
        const SizedBox(width: 16),
        InfoCell(label: 'Produced Quantity', value: '${order.totalProducedQuantity.toInt()} Units'),
        const SizedBox(width: 16),
        InfoCell(
          label: 'Started At',
          value: Utils.formatTimestamp(order.startDateTime),
        ),
        const SizedBox(width: 16),
        InfoCell(
          label: 'Ended At',
          value: order.endDateTime.isEmpty ? 'In progress' : Utils.formatTimestamp(order.endDateTime),
        ),
      ],
    );
  }
}