import 'package:easy_localization/easy_localization.dart';
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
        InfoCell(label: 'product'.tr(), value: order.itemDescription ?? '—'),
        const SizedBox(width: 16),
        InfoCell(label: 'plannedQty'.tr(), value: '${order.orderQuantity} ${'unit'.tr()}'),
        const SizedBox(width: 16),
        InfoCell(
          label: 'start'.tr(),
          value: Utils.formatTimestamp(order.plannedStart.toString()),
        ),
        const SizedBox(width: 16),
        InfoCell(
          label: 'end'.tr(),
          value: Utils.formatTimestamp(order.plannedEnd.toString()),
        ),
      ],
    );
  }
}
