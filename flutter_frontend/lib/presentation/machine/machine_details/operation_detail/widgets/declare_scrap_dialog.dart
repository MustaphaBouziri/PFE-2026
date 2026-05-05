import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pfe_mes/core/storage/session_storage.dart';
import 'package:pfe_mes/data/machine/models/mes_componentConsumption_model.dart';
import 'package:pfe_mes/domain/auth/providers/auth_provider.dart';
import 'package:pfe_mes/domain/machines/providers/machineOrders_provider.dart';
import 'package:pfe_mes/domain/machines/providers/mes_componentConsumption_provider.dart';
import 'package:pfe_mes/presentation/machine/machine_details/operation_detail/widgets/operator_selector.dart';
import 'package:pfe_mes/presentation/widgets/expandableText.dart';
import 'package:provider/provider.dart';

import '../../../../../data/machine/models/mes_scrapCode_model.dart';
import '../../../../../domain/machines/providers/mes_scrap_provider.dart';

class DeclareScrapDialog extends StatefulWidget {
  final String executionId;
  final List<ComponentConsumptionModel> components;

  const DeclareScrapDialog({
    super.key,
    required this.executionId,
    required this.components,
  });

  @override
  State<DeclareScrapDialog> createState() => _DeclareScrapDialogState();
}

class _DeclareScrapDialogState extends State<DeclareScrapDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _noteController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final SessionStorage _sessionStorage = SessionStorage();
  ComponentConsumptionModel? selectedComponent;
  String _onBehalfOfUserId = '';

  MesScrapCode? _selectedCode;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<String> scrapTypes = ['Material', 'FinishedProduct'];
  String currentOption = 'Material';

  bool get _isSupervisor {
    final role =
        _sessionStorage.getRole().toString().trim().toLowerCase() ?? '';
    return role == 'supervisor';
  }

  List<String> get _supervisorWorkCenters {
    final wcs = _sessionStorage.getWorkCenters() as List<String>;
    if (wcs is List) return wcs.map((e) => e.toString()).toList();
    return [];
  }

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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    //validation
    if (_selectedCode == null) {
      setState(() => _errorMessage = 'Please select a scrap code');
      return;
    }

    if (currentOption == scrapTypes[0] && selectedComponent == null) {
      setState(() => _errorMessage = 'Please select a component');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final success = await context.read<MesScrapProvider>().declareScrap(
      executionId: widget.executionId,
      scrapCode: _selectedCode!.code,
      quantity: double.parse(_qtyController.text),
      // pass the selected component item id when scrap type is Material
      materialId: currentOption == scrapTypes[0]
          ? (selectedComponent?.itemNo ?? '')
          : '',
      description: _noteController.text.trim(),
      onBehalfOfUserId: _onBehalfOfUserId,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      context.read<MesComponentconsumptionProvider>().triggerRefresh();
      context.read<MachineordersProvider>().triggerRefresh();
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
    final isWide = MediaQuery.of(context).size.width > 600;

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
            child: SingleChildScrollView(
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

                  // ── Scrap Code Dropdown ──
                  provider.isLoading && provider.scrapCodes.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownMenu<MesScrapCode>(
                          width: double.infinity,
                          hintText: 'selectScrapCode'.tr(),
                          initialSelection: _selectedCode,
                          onSelected: (val) =>
                              setState(() => _selectedCode = val),
                          // menuHeight forces the list to stay below and be scrollable
                          // instead of expanding upward and covering the field
                          menuHeight: 200,
                          menuStyle: MenuStyle(
                            backgroundColor: const WidgetStatePropertyAll(
                              Colors.white,
                            ),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          dropdownMenuEntries: provider.scrapCodes.map((sc) {
                            return DropdownMenuEntry(
                              value: sc,
                              label: sc.displayLabel,
                            );
                          }).toList(),
                        ),

                  const SizedBox(height: 12),

                  //___Radio Buttons___
                  isWide
                      ? Row(
                          children: [
                            Expanded(
                              child: ScrapTypeRadioTile(
                                title: 'material'.tr(),
                                value: scrapTypes[0],
                                groupValue: currentOption,
                                onChanged: (value) {
                                  setState(() {
                                    currentOption = value!;
                                    selectedComponent = null;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: ScrapTypeRadioTile(
                                title: 'finishedProduct'.tr(),
                                value: scrapTypes[1],
                                groupValue: currentOption,
                                onChanged: (value) {
                                  setState(() {
                                    currentOption = value!;
                                    selectedComponent = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            ScrapTypeRadioTile(
                              title: 'Material',
                              value: scrapTypes[0],
                              groupValue: currentOption,
                              onChanged: (value) {
                                setState(() {
                                  currentOption = value!;
                                  selectedComponent = null;
                                });
                              },
                            ),
                            ScrapTypeRadioTile(
                              title: 'Finished Product',
                              value: scrapTypes[1],
                              groupValue: currentOption,
                              onChanged: (value) {
                                setState(() {
                                  currentOption = value!;
                                  selectedComponent = null;
                                });
                              },
                            ),
                          ],
                        ),

                  // ── Component Dropdown  only shown for Material
                  if (currentOption == scrapTypes[0]) ...[
                    const SizedBox(height: 4),
                    DropdownMenu<ComponentConsumptionModel>(
                      width: 300,
                      controller: _searchController,
                      hintText: 'selectComponent'.tr(),
                      enableFilter: true,

                      menuHeight: 180,

                      onSelected: (val) =>
                          setState(() => selectedComponent = val),
                      menuStyle: MenuStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.white),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      inputDecorationTheme: InputDecorationTheme(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      dropdownMenuEntries: widget.components.map((comp) {
                        return DropdownMenuEntry(
                          value: comp,
                          label: comp.itemDescription,
                        );
                      }).toList(),
                    ),
                  ],

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
      ),
    );
  }
}

class ScrapTypeRadioTile extends StatelessWidget {
  final String title;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const ScrapTypeRadioTile({
    super.key,
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: ExpandableText(text: title),
      leading: Radio<String>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
      ),
    );
  }
}
