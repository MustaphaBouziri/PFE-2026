import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pfe_mes/data/machine/models/mes_operation_model.dart';
import 'package:provider/provider.dart';
import '../../../../../domain/machines/providers/machineOrders_provider.dart';

class DeclareProductionDialog extends StatefulWidget {
  final OperationStatusAndProgressModel operationData;

  const DeclareProductionDialog({
    super.key,
    required this.operationData,
  });

  @override
  State<DeclareProductionDialog> createState() => _DeclaireproductiondialogState();
}

class _DeclaireproductiondialogState extends State<DeclareProductionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  double get _remaining =>
      widget.operationData.orderQuantity - widget.operationData.totalProducedQuantity;

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MachineordersProvider>(context, listen: false);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Declare Production',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Text(
                '${_remaining.toStringAsFixed(0)} units remaining',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),

              const SizedBox(height: 16),

              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Quantity Created',
                    hintText: 'e.g. 10',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF2563EB)),
                    ),
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value ?? '');
                    if (parsed == null || parsed <= 0) return 'Enter a valid quantity.';
                    if (parsed > _remaining) return 'Max allowed is ${_remaining.toStringAsFixed(0)} units.';
                    return null;
                  },
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
              ],

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Generate QR'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() { _isLoading = true; _errorMessage = null; });
                        try {
                          await provider.declareProduction(
                            widget.operationData.prodOrderNo,
                            widget.operationData.operationNo,
                            widget.operationData.machineNo,
                            double.parse(_qtyController.text),
                          );
                          if (mounted) Navigator.of(context).pop(true);
                        } catch (e) {
                          setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
                        } finally {
                          setState(() => _isLoading = false);
                        }
                      },
                      icon: _isLoading
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check, color: Colors.white),
                      label: Text(
                        _isLoading ? 'Submitting...' : 'Submit',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}