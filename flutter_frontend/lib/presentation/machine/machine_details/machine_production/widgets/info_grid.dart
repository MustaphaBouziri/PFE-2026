import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../shared/utils.dart';
import 'info_cell.dart';

class OperationInfoGrid extends StatelessWidget {
  final String? lastUpdatedAt;
  final String? operationDiscription;

  const OperationInfoGrid({
    super.key,
    this.lastUpdatedAt,
    this.operationDiscription,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (lastUpdatedAt != null)
          OperationInfoCell(
            label: 'lastUpdated'.tr(),
            value: Utils.formatTimestamp(lastUpdatedAt),
          ),

        if (operationDiscription != null)
          OperationInfoCell(
            label: 'operationDescription'.tr(),
            value: operationDiscription!,
          ),
      ],
    );
  }
}