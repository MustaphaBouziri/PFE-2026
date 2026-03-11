import 'package:flutter/material.dart';

import '../../shared/utils.dart';
import 'info_cell.dart';

class InfoGrid extends StatelessWidget {
  final dynamic order;

  const InfoGrid({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InfoCell(label: 'Product', value: order.itemDescription ?? '—'),
        const SizedBox(width: 16),
        InfoCell(label: 'Planned Qty', value: '${order.orderQuantity} Units'),
        const SizedBox(width: 16),
        InfoCell(
          label: 'Start',
          value: Utils.formatTimestamp(order.plannedStart.toString()),
        ),
        const SizedBox(width: 16),
        InfoCell(
          label: 'End',
          value: 
              Utils.formatTimestamp(order.plannedEnd.toString()),
            
        ),
      ],
    );
  }
}
