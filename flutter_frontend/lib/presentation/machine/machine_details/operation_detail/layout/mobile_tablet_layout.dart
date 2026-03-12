import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/mes_operation_model.dart';
import 'package:pfe_mes/presentation/machine/machine_details/operation_detail/widgets/Current_order_info_container.dart';
import 'package:pfe_mes/presentation/machine/machine_details/operation_detail/widgets/action_Buttons_Container.dart';
import 'package:pfe_mes/presentation/machine/machine_details/operation_detail/widgets/appBar.dart';
import 'package:pfe_mes/presentation/machine/machine_details/operation_detail/widgets/production_chart.dart';
import 'package:pfe_mes/presentation/machine/machine_details/operation_detail/widgets/required_componment.dart';

class MobileTabletLayout extends StatefulWidget {
  final OperationStatusAndProgressModel operationData;
  const MobileTabletLayout({super.key, required this.operationData});

  @override
  State<MobileTabletLayout> createState() => _MobileTabletLayoutState();
}

class _MobileTabletLayoutState extends State<MobileTabletLayout> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: OperationAppbar(
        operationData: widget.operationData,
        isPhone: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CurrentOrderInfoContainer(operationData: widget.operationData),
            const SizedBox(height: 16),
            ActionButtonsContainer(),
            const SizedBox(height: 16),
            ProductionChart(),
            const SizedBox(height: 16),
            RequiredComponent(),
          ],
        ),
      ),
    );
  }
}
