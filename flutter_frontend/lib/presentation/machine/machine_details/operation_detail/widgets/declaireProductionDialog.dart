import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../../data/machine/models/mes_operation_model.dart';
import '../../../../../domain/auth/providers/auth_provider.dart';
import '../../../../../domain/machines/providers/machineOrders_provider.dart';
import 'operator_selector.dart';

class DeclareProductionDialog extends StatefulWidget {
  final OperationStatusAndProgressModel operationData;

  const DeclareProductionDialog({super.key, required this.operationData});

  @override
  State<DeclareProductionDialog> createState() =>
      _DeclareProductionDialogState();
}

class _DeclareProductionDialogState extends State<DeclareProductionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();

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
        context
            .read<AuthProvider>()
            .userData?['role']
            ?.toString()
            .trim()
            .toLowerCase() ??
        '';
    return role == 'supervisor';
  }

  List<String> get _supervisorWorkCenters {
    final wcs = context.read<AuthProvider>().userData?['workCenters'];
    if (wcs is List) return wcs.map((e) => e.toString()).toList();
    return [];
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await context.read<MachineordersProvider>().declareProduction(
        widget.operationData.prodOrderNo,
        widget.operationData.operationNo,
        widget.operationData.machineNo,
        double.parse(_qtyController.text),
        _onBehalfOfUserId,
      );

      if (mounted) Navigator.of(context).pop(double.parse(_qtyController.text));
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
        // FIX: added maxHeight so the dialog never overflows the screen,
        // and the inner scrollable can expand to fill available space.
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 360),
        child: Column(
          // FIX: mainAxisSize.min removed from the outer Column so the
          // Column fills the ConstrainedBox height, giving the Expanded
          // child a finite height to work with.
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header (fixed, never scrolls) ─────────────────────────────
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
            // FIX: Expanded + SingleChildScrollView gives the content area a
            // bounded height and lets it scroll if the keyboard or the
            // OperatorSelector pushes content beyond the dialog's maxHeight.
            // This prevents the TextFormField from disappearing and stops
            // text from being painted on top of other widgets.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                child: Column(
                  // FIX: mainAxisSize.min here is correct — the Column
                  // should only be as tall as its children inside the scroll
                  // view, not try to fill the scroll viewport.
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Operator selector (supervisors only) ───────────────
                    // FIX: wrapped in AnimatedSwitcher so the transition from
                    // the loading state to the dropdown is smooth and does not
                    // cause a layout jump that overlaps the form field below.
                    if (_isSupervisor) ...[
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: OperatorSelector(
                          // FIX: key forces a clean rebuild when workCenters
                          // change, preventing stale loading-indicator frames
                          // from being painted over the dropdown.
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
