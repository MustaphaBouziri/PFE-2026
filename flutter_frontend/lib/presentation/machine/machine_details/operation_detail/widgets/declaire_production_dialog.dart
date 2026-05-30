import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pfe_mes/core/storage/session_storage.dart';
import 'package:provider/provider.dart';

import '../../../../../data/machine/models/mes_operation_model.dart';
import '../../../../../data/machine/models/mes_componentConsumption_model.dart';
import '../../../../../domain/auth/providers/auth_provider.dart';
import '../../../../../domain/machines/providers/machineOrders_provider.dart';
import 'operator_selector.dart';

class DeclareProductionDialog extends StatefulWidget {
  final OperationStatusAndProgressModel operationData;
  final List<ComponentConsumptionModel> components;

  const DeclareProductionDialog({
    super.key,
    required this.operationData,
    required this.components,
  });

  @override
  State<DeclareProductionDialog> createState() =>
      _DeclareProductionDialogState();
}

class _DeclareProductionDialogState extends State<DeclareProductionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final SessionStorage _sessionStorage = SessionStorage();

  bool _isLoading = false;
  String? _errorMessage;

  // Populated by OperatorSelector when the logged-in user is a Supervisor.
  // Empty string means "declare on my own behalf".
  String _onBehalfOfUserId = '';

  double get _remaining =>
      widget.operationData.orderQuantity -
      widget.operationData.totalProducedQuantity;

  bool get _isSupervisor {
    final role =
        _sessionStorage.getRole().toString().trim().toLowerCase() ?? '';
    return role == 'supervisor';
  }

  List<String> get _supervisorWorkCenters {
    final wcs = _sessionStorage.getWorkCenters();
    return wcs.map((e) => e.toString()).toList();
  }

  //  check if components are available for a given quantity
  String? _validateComponentAvailability(double declaredQty) {
    for (final component in widget.components) {
      // consumed is how many items have been used based on the total produced and the quantity per unit
      final consumed =
          widget.operationData.totalProducedQuantity *
          component.quantityPerUnit;
      final scanned = component.totalQuantityScanned;
      final scrap = component.scrapQuantity+component.quantityPerUnit*widget.operationData.scrapQuantity;
      final remaining = scanned - consumed - scrap;

      // calculate how many of this component will be needed for the declared quantity
      final neededForDeclaredQty = declaredQty * component.quantityPerUnit;
      // If remaining is less than what's needed, return error message
      if (remaining < neededForDeclaredQty) {
       return 'insufficientComponentQuantity'.tr();
      }
    }
    return null;
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final declaredQty = double.parse(_qtyController.text);

    // check item availablity before api call
    final componentError = _validateComponentAvailability(declaredQty);
    // if there is an error stop
    if (componentError != null) {
      //save the error in the _eroorMessage and update the io to show the message 
      setState(() => _errorMessage = componentError);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await context.read<MachineordersProvider>().declareProduction(
        widget.operationData.prodOrderNo,
        widget.operationData.operationNo,
        widget.operationData.machineNo,
        declaredQty,
        _onBehalfOfUserId,
      );

      if (mounted) Navigator.of(context).pop(declaredQty);
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'declareProduction'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 2, 24, 0),
              child: Text(
                '${_remaining.toStringAsFixed(0)} ${'unitsRemaining'.tr()}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ),

            const Divider(height: 20),

            // ── Scrollable body ────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Operator selector (supervisors only) ───────────────
                    if (_isSupervisor) ...[
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: OperatorSelector(
                          key: ValueKey(_supervisorWorkCenters.join(',')),
                          workCenterIds: _supervisorWorkCenters,
                          onOperatorSelected: (userId) =>
                              setState(() => _onBehalfOfUserId = userId ?? ''),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Quantity input ─────────────────────────────────────
                    Form(
                      key: _formKey,
                      child: TextFormField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'quantityCreated'.tr(),
                          hintText: 'exampleQty'.tr(),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        validator: (value) {
                          final parsed = double.tryParse(value ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'enterValidQuantity'.tr();
                          }
                          if (parsed > _remaining) {
                            return 'maxAllowedQuantity'.tr(
                              args: [_remaining.toStringAsFixed(0)],
                            );
                          }
                          return null;
                        },
                      ),
                    ),
                    // if not null add a sied box and displau the message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Action buttons ─────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submit,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check, color: Colors.white),
                        label: Text(
                          _isLoading ? 'submitting'.tr() : 'submit'.tr(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
