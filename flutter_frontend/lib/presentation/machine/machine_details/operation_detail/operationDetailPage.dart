import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/mes_operation_model.dart';
import 'package:pfe_mes/data/machine/models/mes_production_cycle.dart';
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
      builder: (context, liveSnapshot) {
        final liveData = liveSnapshot.data;
        //merged cuz i have static values from the operationData and the actual live data from livedata (steam ya3ni)
        final merged = OperationStatusAndProgressModel(
          prodOrderNo: widget.operationData.prodOrderNo,
          machineNo: widget.operationData.machineNo,
          operationNo: widget.operationData.operationNo,
          itemDescription: widget.operationData.itemDescription,
          orderQuantity: widget.operationData.orderQuantity,
          lastUpdatedAt: liveData?.lastUpdatedAt ?? widget.operationData.lastUpdatedAt,
          operationStatus: liveData?.operationStatus ?? widget.operationData.operationStatus,
          totalProducedQuantity: liveData?.totalProducedQuantity ?? widget.operationData.totalProducedQuantity,
          scrapQuantity: liveData?.scrapQuantity ?? widget.operationData.scrapQuantity,
          progressPercent: liveData?.progressPercent ?? widget.operationData.progressPercent,
        );

        return StreamBuilder<List<ProductionCycleModel>>(
          stream: provider.fetchProductionCyclesStream(
            widget.operationData.machineNo,
            widget.operationData.prodOrderNo,
            widget.operationData.operationNo,
          ),
          builder: (context, cyclesSnapshot) {
            final cycles = cyclesSnapshot.data ?? [];

            return LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 1024) {
                  return MobileTabletLayout(operationData: merged, cycles: cycles);
                } else {
                  return PcLayout(operationData: merged, cycles: cycles);
                }
              },
            );
          },
        );
      },
    );
  }
}