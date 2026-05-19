import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/mes_operation_model.dart';
import 'package:provider/provider.dart';

import '../../../../domain/machines/providers/machineOrders_provider.dart';
import 'widgets/operation_card.dart';

class OrdersProgressionPage extends StatefulWidget {
  final String machineNo;

  const OrdersProgressionPage({super.key, required this.machineNo});

  @override
  State<OrdersProgressionPage> createState() => _OrdersProgressionPageState();
}

class _OrdersProgressionPageState extends State<OrdersProgressionPage> {
  Future<void> _handleToggle(
    BuildContext context,
    OperationStatusAndProgressModel op,
  ) async {
    final provider = Provider.of<MachineordersProvider>(context, listen: false);
    final isRunning = op.operationStatus.trim().toLowerCase() == 'running';

    try {
      if (isRunning) {
        await provider.pauseOperation(
          machineNo: widget.machineNo,
          prodOrderNo: op.prodOrderNo,
          operationNo: op.operationNo,
        );
      } else {
        await provider.resumeOperation(
          machineNo: widget.machineNo,
          prodOrderNo: op.prodOrderNo,
          operationNo: op.operationNo,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${'failed'.tr()}: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MachineordersProvider>(context, listen: false);
    final isVisible = ModalRoute.of(context)?.isCurrent ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
    

    

      body: !isVisible ?
      const SizedBox() :
      StreamBuilder<List<OperationStatusAndProgressModel>>(
        stream: provider.getMachineOngoingOperationsStateStream(
          widget.machineNo,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

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

          final operations = snapshot.data!;

          if (operations.isEmpty) {
            return const _EmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: operations.length,
            itemBuilder: (context, index) {
              final op = operations[index];
              return OperationCard(
                operationData: op,
                onTogglePauseResume: () => _handleToggle(context, op),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
           Text(
            'noOperationsCurrentlyActiveForThisMachine'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF94A3B8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}



