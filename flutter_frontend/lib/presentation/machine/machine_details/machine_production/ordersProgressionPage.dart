import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/mes_operation_model.dart';
import 'package:provider/provider.dart';

import '../../../../domain/machines/providers/machineOrders_provider.dart';
import 'widgets/operation_card.dart';

/// Displays a live-updating list of machine operation statuses for [machineNo].
///
/// Architecture mirrors [Machineorderpage]:
///   - page holds the [StreamBuilder] + empty/error states
///   - visual logic is delegated to [OperationCard] and its sub-widgets
///   - styling data is resolved through [operationStatusStyleFromStatus]
class OrdersProgressionPage extends StatelessWidget {
  final String machineNo;

  const OrdersProgressionPage({super.key, required this.machineNo});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MachineordersProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: StreamBuilder<List<OperationStatusAndProgressModel>>(
        stream: provider.getMachineOperationStatusAndProgressStream(machineNo,false),
        builder: (context, snapshot) {
          
          // ── Loading ──────────────────────────────────────────────────────
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // ── Error ────────────────────────────────────────────────────────
          if (snapshot.hasError) {
            return _ErrorState(error: snapshot.error.toString());
          }

          final operations = snapshot.data!;

          // ── Empty state ──────────────────────────────────────────────────
          if (operations.isEmpty) {
            return const _EmptyState();
          }

          // ── List ─────────────────────────────────────────────────────────
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: operations.length,
            itemBuilder: (context, index) {
              return OperationCard(operationData: operations[index]);
            },
          );
        },
      ),
    );
  }
}

// ── Private: empty state ─────────────────────────────────────────────────────

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
          const Text(
            'No operations currently active\nfor this machine',
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

// ── Private: error state ──────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 48,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load operations',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
