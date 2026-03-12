import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/mes_operation_model.dart';
import 'package:pfe_mes/presentation/machine/machine_details/operation_detail/widgets/Current_order_info_container.dart';
import 'package:pfe_mes/presentation/machine/machine_details/operation_detail/widgets/action_Buttons_Container.dart';
import 'package:pfe_mes/presentation/machine/machine_details/operation_detail/widgets/appBar.dart';
import 'package:pfe_mes/presentation/machine/machine_details/operation_detail/widgets/production_chart.dart';
import 'package:pfe_mes/presentation/machine/machine_details/operation_detail/widgets/required_componment.dart';

class PcLayout extends StatefulWidget {
  final OperationStatusAndProgressModel operationData;
  const PcLayout({super.key, required this.operationData});

  @override
  State<PcLayout> createState() => _PcLayoutState();
}

class _PcLayoutState extends State<PcLayout> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: OperationAppbar(
        operationData: widget.operationData,
        isPhone: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // left side
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    CurrentOrderInfoContainer(
                      operationData: widget.operationData,
                    ),
                    const SizedBox(height: 16),
                    ProductionChart(),
                  ],
                ),
              ),

              const SizedBox(width: 30),
              // right side
              Expanded(
                child: Column(
                  children: [
                    ActionButtonsContainer(),
                    const SizedBox(height: 16),
                    RequiredComponent(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
