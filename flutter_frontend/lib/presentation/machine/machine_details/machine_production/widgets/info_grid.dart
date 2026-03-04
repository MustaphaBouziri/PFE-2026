import 'package:flutter/material.dart';

import '../../shared/utils.dart';
import 'info_cell.dart';

/// Horizontal row of metadata cells shown on each operation card.
/// Mirrors the role of [InfoGrid] in the machineOrderPage layer.
///
/// Displays: Status label, and a human-readable Last Updated timestamp.
class OperationInfoGrid extends StatelessWidget {
  final String? lastUpdatedAt;

  const OperationInfoGrid({super.key, this.lastUpdatedAt});


  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OperationInfoCell(
          label: 'Last Updated',
          value: Utils.formatTimestamp(lastUpdatedAt),
        ),
      ],
    );
  }
}
