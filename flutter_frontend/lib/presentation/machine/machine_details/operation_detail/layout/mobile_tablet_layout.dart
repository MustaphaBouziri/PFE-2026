import 'package:flutter/material.dart';
import 'package:pfe_mes/presentation/tutorials/operation_detail_tutorial.dart';
import '../../../../../data/machine/models/mes_componentConsumption_model.dart';

import '../../../../../data/machine/models/mes_operation_model.dart';
import '../../../../../data/machine/models/mes_production_cycle.dart';

import '../widgets/Current_order_info_container.dart';
import '../widgets/action_Buttons_Container.dart';
import '../widgets/appBar.dart';
import '../widgets/no_info_available.dart';
import '../widgets/production_chart.dart';
import '../widgets/production_cycle.dart';
import '../widgets/required_componment.dart';

class MobileTabletLayout extends StatefulWidget {
  final OperationStatusAndProgressModel operationData;
  final List<ProductionCycleModel> cycles;
  final List<ComponentConsumptionModel> components;

  const MobileTabletLayout({
    super.key,
    required this.operationData,
    required this.cycles,
    required this.components
  });

  @override
  State<MobileTabletLayout> createState() => _MobileTabletLayoutState();
}

class _MobileTabletLayoutState extends State<MobileTabletLayout> {
  bool get hasProductionData {
    return widget.cycles.any((cycle) => cycle.cycleQuantity > 0);
  }

  // Keys for tutorial
  final GlobalKey _currentOrderKey = GlobalKey();
  final GlobalKey _actionButtonsKey = GlobalKey();

  bool _tutorialShown = false;


  @override
  Widget build(BuildContext context) {
    // Show tutorial if data loaded and not shown yet
    if (!_tutorialShown) {
      _tutorialShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async => 
        await OperationDetailTutorial.show(context, [_currentOrderKey, _actionButtonsKey])
      );
    }

    return Scaffold(
      appBar: OperationAppbar(
        operationData: widget.operationData,
        isPhone: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              key: _currentOrderKey,
              child: CurrentOrderInfoContainer(operationData: widget.operationData),
            ),
            const SizedBox(height: 16),
            Container(
              key: _actionButtonsKey,
              child: ActionButtonsContainer(operationData: widget.operationData,components: widget.components,),
            ),
            const SizedBox(height: 16),

            if (hasProductionData) ...[
              ProductionChart(
                cycles: widget.cycles,
                horizontalScrollable: true,
                perScreenDataPoints: 5,
              ),
              const SizedBox(height: 16),
              ProductionCycle(
                cycles: widget.cycles,
                perPage: 5,
                horizontalScrollable: true,
              ),
            ] else
              NoInfoAvailable(),

            const SizedBox(height: 16),
            RequiredComponent(
              components: widget.components,
              totalProduced: widget.operationData.totalProducedQuantity,
              executionId: widget.operationData.executionId,
              
            )
          ],
        ),
      ),
    );
  }
}