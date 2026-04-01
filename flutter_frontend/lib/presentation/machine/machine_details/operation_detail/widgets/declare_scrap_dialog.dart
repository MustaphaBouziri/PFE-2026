import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../../data/machine/models/mes_scrapCode_model.dart';
import '../../../../../domain/machines/providers/mes_scrap_provider.dart';

class DeclareScrapDialog extends StatefulWidget {
  final String executionId;

  const DeclareScrapDialog({super.key, required this.executionId});

  @override
  State<DeclareScrapDialog> createState() => _DeclareScrapDialogState();
}

class _DeclareScrapDialogState extends State<DeclareScrapDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _noteController = TextEditingController();

  MesScrapCode? _selectedCode;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // fetch after first frame so context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MesScrapProvider>().fetchScrapCodes();
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSubmitting = true; _errorMessage = null; });

    final success = await context.read<MesScrapProvider>().declareScrap(
      executionId: widget.executionId,
      scrapCode: _selectedCode!.code,
      quantity: double.parse(_qtyController.text),
      description: _noteController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scrap declared successfully')),
      );
    } else {
      setState(() {
        _errorMessage = context.read<MesScrapProvider>().errorMessage
            ?? 'Failed to declare scrap';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MesScrapProvider>();

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Declare Scrap',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Scrap Code Dropdown ──
                provider.isLoading && provider.scrapCodes.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<MesScrapCode>(
                  value: _selectedCode,
                  decoration: InputDecoration(
                    labelText: 'Scrap Code',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFDC2626)),
                    ),
                  ),
                  dropdownColor: Colors.white,
                  items: provider.scrapCodes
                      .map((sc) => DropdownMenuItem(
                    value: sc,
                    child: Text(sc.displayLabel,
                        overflow: TextOverflow.ellipsis),
                  ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCode = val),
                  validator: (val) =>
                  val == null ? 'Please select a scrap code' : null,
                ),

                const SizedBox(height: 12),

                // ── Quantity ──
                TextFormField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    hintText: 'e.g. 3',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFDC2626)),
                    ),
                  ),
                  validator: (val) {
                    final parsed = double.tryParse(val ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid quantity';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // ── Note (optional) ──
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Note (optional)',
                    hintText: 'Describe the defect...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFDC2626)),
                    ),
                  ),
                ),

                // ── Inline error ──
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(_errorMessage!,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFFDC2626))),
                ],

                const SizedBox(height: 20),

                // ── Submit ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check, color: Colors.white),
                    label: Text(
                      _isSubmitting ? 'Submitting...' : 'Submit',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}