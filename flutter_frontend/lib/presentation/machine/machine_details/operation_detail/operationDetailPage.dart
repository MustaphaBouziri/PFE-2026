import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/mes_operation_model.dart';
import 'package:pfe_mes/presentation/machine/machine_details/operation_detail/layout/mobile_tablet_layout.dart';
import 'package:pfe_mes/presentation/machine/machine_details/operation_detail/layout/pc_layout.dart';

class OperationDetailPage extends StatefulWidget {
  final OperationStatusAndProgressModel operationData;
  const OperationDetailPage({super.key, required this.operationData});

  @override
  State<OperationDetailPage> createState() => _OperationDetailPageState();
}

class _OperationDetailPageState extends State<OperationDetailPage> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 1024) {
          return MobileTabletLayout(operationData: widget.operationData);
        } else {
          return PcLayout(operationData: widget.operationData);
        }
      },
    );
  }
}