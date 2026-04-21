import 'package:easy_localization/easy_localization.dart';
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
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final success = await context.read<MesScrapProvider>().declareScrap(
      executionId: widget.executionId,
      scrapCode: _selectedCode!.code,
      quantity: double.parse(_qtyController.text),
      description: _noteController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('scrapDeclaredSuccessfully'.tr())));
    } else {
      setState(() {
        _errorMessage =
            context.read<MesScrapProvider>().errorMessage ??
            'failedToDeclareScrap'.tr();
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
        constraints: const BoxConstraints(maxWidth: 520),
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
                    Text(
                      'scrapDialogTitle'.tr(),
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

                const SizedBox(height: 16),

                // ── Scrap Code Dropdown ──
                provider.isLoading && provider.scrapCodes.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownMenu<MesScrapCode>(
                      hintText: 'selectScrapCode'.tr(),
                        initialSelection: _selectedCode,
                        onSelected: (val) =>
                            setState(() => _selectedCode = val),

                        dropdownMenuEntries: provider.scrapCodes.map((sc) {
                          return DropdownMenuEntry(
                            value: sc,
                            label: sc.displayLabel,
                            
                          );
                        }).toList(),

                        menuStyle: MenuStyle(
                          backgroundColor: WidgetStatePropertyAll(Colors.white),
                          maximumSize: WidgetStatePropertyAll(
                            const Size(400, 250),
                          ),
                          
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                const SizedBox(height: 12),

                // ── Quantity ──
                TextFormField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'quantityLabel'.tr(),
                    labelStyle: const TextStyle(color: Color(0xFF0F172A)),
                    hintText: 'exampleQuantity'.tr(),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF0F172A),
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (val) {
                    final parsed = double.tryParse(val ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'enterValidQuantity'.tr();
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
                    labelText: 'noteOptional'.tr(),
                    labelStyle: const TextStyle(color: Color(0xFF0F172A)),
                    hintText: 'describeTheDefect'.tr(),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF0F172A),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                // ── Inline error ──
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

                // ── Submit ──
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
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
                      _isSubmitting ? 'submitting'.tr() : 'submit'.tr(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
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
      ),
    );
  }
}
