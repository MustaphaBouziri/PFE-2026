import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/mes_operation_model.dart';
import 'package:pfe_mes/data/machine/models/mes_production_cycle.dart';
import 'package:pfe_mes/data/machine/models/mes_componentConsumption_model.dart';
import 'package:pfe_mes/domain/machines/providers/machineOrders_provider.dart';
import 'package:pfe_mes/domain/machines/providers/mes_componentConsumption_provider.dart';
import 'package:pfe_mes/presentation/machine/machine_details/operation_detail/layout/mobile_tablet_layout.dart';
import 'package:pfe_mes/presentation/machine/machine_details/operation_detail/layout/pc_layout.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

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
    final componentProvider = Provider.of<MesComponentconsumptionProvider>(
      context,
      listen: false,
    );

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
          itemNo: widget.operationData.itemNo,
          itemDescription: widget.operationData.itemDescription,
          operationDescription: widget.operationData.operationDescription,

          orderQuantity: widget.operationData.orderQuantity,
          startDateTime: widget.operationData.startDateTime,
          endDateTime:
              liveData?.endDateTime ?? widget.operationData.endDateTime,
          declaredAt: liveData?.declaredAt ?? widget.operationData.declaredAt,
          operationStatus:
              liveData?.operationStatus ?? widget.operationData.operationStatus,
          totalProducedQuantity:
              liveData?.totalProducedQuantity ??
              widget.operationData.totalProducedQuantity,
          scrapQuantity:
              liveData?.scrapQuantity ?? widget.operationData.scrapQuantity,
          progressPercent:
              liveData?.progressPercent ?? widget.operationData.progressPercent,
          executionId: liveData?.executionId ?? "",
        );

        return StreamBuilder<List<ProductionCycleModel>>(
          stream: provider.fetchProductionCyclesStream(
            widget.operationData.machineNo,
            widget.operationData.prodOrderNo,
            widget.operationData.operationNo,
          ),
          builder: (context, snapshot) {
            final cycles = snapshot.data ?? [];

            return StreamBuilder<List<ComponentConsumptionModel>>(
              stream: componentProvider.getBomStream(
                widget.operationData.prodOrderNo,
                widget.operationData.operationNo,
              ),
              builder: (context, bomSnapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_off_outlined,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'FailedToFetchData'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: const Color(0xFF94A3B8),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final components = bomSnapshot.data ?? [];

                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 1210) {
                      return MobileTabletLayout(
                        operationData: merged,
                        cycles: cycles,
                        components: components,
                      );
                    } else {
                      return PcLayout(
                        operationData: merged,
                        cycles: cycles,
                        components: components,
                      );
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
