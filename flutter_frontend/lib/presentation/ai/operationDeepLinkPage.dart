import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/presentation/machine/machine_details/operation_detail/operationDetailPage.dart';
import 'package:provider/provider.dart';

import '../../../../data/machine/models/mes_operation_model.dart';
import '../../../../domain/machines/providers/machineOrders_provider.dart';


/// Intermediate page that simulates the full navigation breadcrumb:
///
///   MachineListPage → MachineMainPage (tab 1) → OperationDetailPage
///
/// It is pushed on top of MachineMainPage immediately after MachineMainPage
/// is pushed.  On first frame it fetches the first emission of the ongoing-
/// operations stream for [machineNo], finds the operation matching
/// [prodOrderNo] + [operationNo], then replaces itself with
/// [OperationDetailPage].
///
/// If the operation is not found (it may have finished since the AI answered)
/// the page dismisses itself, leaving MachineMainPage (tab 1) visible — a
/// graceful fallback with full context.
class OperationDeepLinkPage extends StatefulWidget {
  final String machineNo;
  final String machineName;
  final String prodOrderNo;
  final String operationNo;

  const OperationDeepLinkPage({
    super.key,
    required this.machineNo,
    required this.machineName,
    required this.prodOrderNo,
    required this.operationNo,
  });

  @override
  State<OperationDeepLinkPage> createState() => _OperationDeepLinkPageState();
}

class _OperationDeepLinkPageState extends State<OperationDeepLinkPage> {
  /// One of: 'loading' | 'not_found' | 'error'
  String _status = 'loading';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Kick off the fetch after the first frame so the provider tree is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAndNavigate());
  }

  Future<void> _fetchAndNavigate() async {
    final provider = context.read<MachineordersProvider>();

    try {
      // Take the first emission from the stream — gives us the live list
      // without keeping a long-lived subscription.
      final operations = await provider
          .getMachineOngoingOperationsStateStream(widget.machineNo)
          .first
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () => [],
      );

      if (!mounted) return;

      // Find the operation that matches both prodOrderNo and operationNo.
      OperationStatusAndProgressModel? target;
      for (final op in operations) {
        if (op.prodOrderNo == widget.prodOrderNo &&
            op.operationNo == widget.operationNo) {
          target = op;
          break;
        }
      }

      if (target == null) {
        // Operation not found — could be finished or the AI was slightly off.
        // Show a short "not found" message then pop back to MachineMainPage.
        if (!mounted) return;
        setState(() => _status = 'not_found');
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.of(context).pop();
        return;
      }

      // Replace this loading page with OperationDetailPage so the back-stack
      // becomes: MachineListPage → MachineMainPage → OperationDetailPage
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OperationDetailPage(operationData: target!),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'error';
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.precision_manufacturing_outlined,
              size: 20,
              color: Colors.grey,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.machineName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'ID: ${widget.machineNo}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case 'loading':
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'loadingOperation'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'ORD-${widget.prodOrderNo}  ·  OP-${widget.operationNo}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        );

      case 'not_found':
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 48,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(height: 16),
                Text(
                  'operationNoLongerActive'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ORD-${widget.prodOrderNo}  ·  OP-${widget.operationNo}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'redirectingToMachine'.tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        );

      case 'error':
      default:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'failedToLoadOperation'.tr(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _status = 'loading';
                      _errorMessage = '';
                    });
                    _fetchAndNavigate();
                  },
                  child: Text('retry'.tr()),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('goBackToMachine'.tr()),
                ),
              ],
            ),
          ),
        );
    }
  }
}