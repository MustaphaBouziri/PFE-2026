import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/mes_operation_model.dart';
import 'package:pfe_mes/presentation/machine/machine_details/operation_detail/layout/mobile_tablet_layout.dart';
import 'package:pfe_mes/presentation/machine/machine_details/operation_detail/layout/pc_layout.dart';
import 'package:provider/provider.dart';
import '../../../../domain/machines/providers/machineOrders_provider.dart';

class OperationDetailPage extends StatefulWidget {
  final OperationStatusAndProgressModel operationData;
  const OperationDetailPage({super.key, required this.operationData});

  @override
  State<OperationDetailPage> createState() => _OperationDetailPageState();
}

class _OperationDetailPageState extends State<OperationDetailPage> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MachineordersProvider>(context, listen: false);

    return StreamBuilder<OperationStatusAndProgressModel?>(
      stream: provider.fetchOperationLiveDataStream(
        widget.operationData.machineNo,
        widget.operationData.prodOrderNo,
        widget.operationData.operationNo,
      ),
      builder: (context, snapshot) {
        final liveData = snapshot.data;
        //merged cuz i have static values from the operationData and the actual live data from livedata (steam ya3ni)
        final merged = OperationStatusAndProgressModel(

          prodOrderNo: widget.operationData.prodOrderNo,

          machineNo: widget.operationData.machineNo,

          operationNo: widget.operationData.operationNo,

          itemDescription: widget.operationData.itemDescription,

          orderQty: widget.operationData.orderQty,

          lastUpdatedAt:
              liveData?.lastUpdatedAt ?? widget.operationData.lastUpdatedAt,

          operationStatus:
              liveData?.operationStatus ?? widget.operationData.operationStatus,

          producedQty:
              liveData?.producedQty ?? widget.operationData.producedQty,

          scrapQty: liveData?.scrapQty ?? widget.operationData.scrapQty,

          progressPercent:
              liveData?.progressPercent ?? widget.operationData.progressPercent,
        );
        
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            if (width < 1024) {
              return MobileTabletLayout(operationData: merged);
            } else {
              return PcLayout(operationData: merged);
            }
          },
        );
      },
    );
  }
}
