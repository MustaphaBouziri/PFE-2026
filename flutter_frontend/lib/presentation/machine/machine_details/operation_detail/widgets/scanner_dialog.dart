import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pfe_mes/data/machine/barCode/models/mes_barCode_model.dart';
import 'package:pfe_mes/data/machine/models/mes_componentConsumption_model.dart';
import 'package:pfe_mes/domain/machines/barCode/provider/mes_barCode_provider.dart';
import 'package:pfe_mes/domain/machines/providers/mes_componentConsumption_provider.dart';
import 'package:pfe_mes/presentation/widgets/expandableText.dart';
import 'package:provider/provider.dart';

class ScannerWidget extends StatefulWidget {
  final String executionId;
  final List<ComponentConsumptionModel> components;
  final double orderRemainingQte;
  final Map<String, double> outOf;
  const ScannerWidget({
    super.key,
    required this.executionId,
    required this.components,
    required this.orderRemainingQte,
    required this.outOf,
  });

  @override
  State<ScannerWidget> createState() => _ScannerWidgetState();
}

class _ScannerWidgetState extends State<ScannerWidget> {
  List<ItemBarcodeModel> items = [];
  // Keep one TextEditingController per item row so the field stays in sync
  final List<TextEditingController> _qtyControllers = [];
  final MobileScannerController controller = MobileScannerController();
  bool isScanning = true;
  bool isSubmitting = false;
  String? errorMessage;

  @override
  void dispose() {
    for (final c in _qtyControllers) {
      c.dispose();
    }
    super.dispose();
  }

  //check if item is in components list
  bool isItemInComponents(String itemNo) {
    return widget.components.any((c) => c.itemNo == itemNo);
  }

  bool canAddMoreItem(ItemBarcodeModel item) {
    // find the component for this item
    ComponentConsumptionModel? component;
    try {
      component = widget.components.firstWhere((c) => c.itemNo == item.itemNo);
    } catch (e) {
      // item not found in components list
      return false;
    }

    // VALIDATION: barcode UOM must not be smaller than item base UOM
    // check: barcode quantityPerUnit >= base quantityPerUnit
    // If barcode qty per unit < base qty per unit  barcode is smaller → invalid
    if (item.quantityPerUnit < component.baseUOMQuantityPerUnit) {
      return false; // Block: barcode UOM is smaller than base UOM
    }

    // find if this item is already in the scanned list
    ItemBarcodeModel? existingItem;
    try {
      existingItem = items.firstWhere((e) => e.itemNo == item.itemNo);
    } catch (e) {
      // Item not in list yet, that's fine
    }

    final totalIfAdded = existingItem != null
        ? (existingItem.quantity + 1) * item.quantityPerUnit
        : item.quantityPerUnit;

    // check if total scanned would exceed available inventory
    return totalIfAdded <= component.inventory;
  }

  // we add new item or we increment qty
  void addItem(ItemBarcodeModel newItem) {
    if (!isItemInComponents(newItem.itemNo)) {
      setState(() {
        errorMessage = 'itemNotInBOMForThisOperation'.tr();
      });
      return;
    }

    final component = widget.components.firstWhere(
      (c) => c.itemNo == newItem.itemNo,
    );

    // VALIDATION: check if barcode UOM is smaller than base UOM
    // If barcode quantityPerUnit < base quantityPerUnit, barcode is smaller (invalid)
    if (newItem.quantityPerUnit < component.baseUOMQuantityPerUnit) {
      setState(() {
        errorMessage = 'invalidBarcodeUOM'.tr(
          args: [newItem.unitOfMeasure, component.baseUOM],
        );
      });
      return;
    }

    if (!canAddMoreItem(newItem)) {
      setState(() {
        errorMessage = 'insufficientInventoryAdd'.tr(args: [newItem.itemNo]);
      });
      return;
    }

    // clear error when adding successfully
    setState(() {
      errorMessage = null;
    });

    int index = items.indexWhere(
      (e) =>
          e.itemNo == newItem.itemNo &&
          e.unitOfMeasure == newItem.unitOfMeasure,
    );

    if (index != -1) {
      // same item already in list we increment quantity  keep all other fields the same
      final newQty = items[index].quantity + 1;
      items[index] = ItemBarcodeModel(
        itemNo: items[index].itemNo,
        description: items[index].description,
        baseUOM: items[index].baseUOM,
        lotSize: items[index].lotSize,
        flushingMethod: items[index].flushingMethod,
        barcodeText: items[index].barcodeText,
        quantity: newQty,
        quantityPerUnit: items[index].quantityPerUnit,
        unitOfMeasure: items[index].unitOfMeasure,
      );
      // Keep the text field in sync when a re-scan increments the qty
      _qtyControllers[index].text = newQty.toStringAsFixed(0);
    } else {
      items.add(newItem);
      // Add a controller initialised to "1" for the new row
      _qtyControllers.add(TextEditingController(text: '1'));
    }
  }

  void setQty(int index, String value) {
    // when field is cleared reset to 1
    if (value.isEmpty) {
  setState(() {
    errorMessage = null;
    items[index] = ItemBarcodeModel(
      itemNo: items[index].itemNo,
      description: items[index].description,
      baseUOM: items[index].baseUOM,
      lotSize: items[index].lotSize,
      flushingMethod: items[index].flushingMethod,
      barcodeText: items[index].barcodeText,
      quantity: 1,
      quantityPerUnit: items[index].quantityPerUnit,
      unitOfMeasure: items[index].unitOfMeasure,
    );
    // when the user clears the field the value will be 1 if he press delete again it will select 1 so that it can be replaced by the new value , why ? so that the first number wont be forced 1 
    _qtyControllers[index].value = const TextEditingValue(
      text: '1',
      selection: TextSelection(baseOffset: 0, extentOffset: 1),
    );
  });
  return;
}

    // regect starting by 1 but alloow 0 if its the only value
    if (value.length > 1 && value.startsWith('0')) {
      final stripped = value.replaceFirst(RegExp(r'^0+'), '');
      _qtyControllers[index].value = TextEditingValue(
        text: stripped,
        selection: TextSelection.collapsed(offset: stripped.length),
      );
      return;
    }

    final qty = int.tryParse(value);
    if (qty == null || qty <= 0) return;

    final component = widget.components.firstWhere(
      (c) => c.itemNo == items[index].itemNo,
    );

    final totalRequired = qty * items[index].quantityPerUnit;

    if (totalRequired > component.inventory) {
      setState(() {
        errorMessage = 'insufficientInventoryFor'.tr() + items[index].itemNo;
      });
      return;
    }

    setState(() {
      errorMessage = null;
      items[index] = ItemBarcodeModel(
        itemNo: items[index].itemNo,
        description: items[index].description,
        baseUOM: items[index].baseUOM,
        lotSize: items[index].lotSize,
        flushingMethod: items[index].flushingMethod,
        barcodeText: items[index].barcodeText,
        quantity: qty.toDouble(),
        quantityPerUnit: items[index].quantityPerUnit,
        unitOfMeasure: items[index].unitOfMeasure,
      );
    });
  }

  //delete item from list
  void removeItem(int index) {
    setState(() {
      errorMessage = null;
      items.removeAt(index);
      // Dispose and remove the matching controller
      _qtyControllers[index].dispose();
      _qtyControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isphone = MediaQuery.of(context).size.width <= 600;
    return Dialog(
      backgroundColor: const Color(0xFFF8FAFC),
      child: SizedBox(
        width: isphone ? 400 : 500,
        height: 600,
        child: Column(
          children: [
            const SizedBox(height: 16),

            //scanner box
            Expanded(
              flex: 3,
              child: Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: isScanning
                        ? MobileScanner(
                            controller: controller,
                            onDetect: (barcodeCapture) async {
                              if (!isScanning) return;

                              final barcode = barcodeCapture.barcodes.first;
                              final value = barcode.rawValue;

                              if (value == null) return;

                              // Immediately disable scanning to prevent multiple detections
                              setState(() => isScanning = false);

                              // all barcodes go through resolveBarcode now
                              // our datamatrix: bc looks up the code MES-1100 in item identifier
                              // external barcode: bc looks up the external code in identifier identifier
                              final result = await context
                                  .read<MesBarcodeProvider>()
                                  .resolveBarcode(value);

                              if (!mounted) return;

                              if (result == null ||
                                  result['resolved'] != true) {
                                setState(() {
                                  errorMessage =
                                      result?['message']?.toString() ??
                                      'barcodeNotRecognized'.tr();
                                  // kkeep isScanning = falseso that user must click scan again
                                });
                                // DON'T restart camera automatically
                                return;
                              }

                              // build model from BC response same structure for both our and external barcodes
                              final item = ItemBarcodeModel(
                                itemNo: result['itemNo']?.toString() ?? '',
                                description:
                                    result['itemDescription']?.toString() ?? '',
                                baseUOM: result['baseUOM']?.toString() ?? '',
                                lotSize: 0,
                                flushingMethod: '',
                                barcodeText: value,
                                quantity: 1,
                                quantityPerUnit:
                                    (result['quantityPerUnitOfMeasure']
                                                as num? ??
                                            1)
                                        .toDouble(),
                                unitOfMeasure:
                                    result['unitOfMeasure']?.toString() ?? '',
                              );

                              setState(() => addItem(item));
                              // camera stopped user must click "scan again" to continue
                            },
                          )
                        : Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.pause_circle_outline,
                                  size: 70,
                                  color: Colors.orange,
                                ),
                                Text('cameraIsPaused'.tr()),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            //resume camera button
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isScanning = true;
                  errorMessage = null;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'scanAgain'.tr(),
                style: const TextStyle(color: Colors.white),
              ),
            ),

            // error message display
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDC2626)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFDC2626),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // list of items you scanned
            Expanded(
              flex: 4,
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  // check if item is in components list
                  final exists = isItemInComponents(item.itemNo);

                  //////////////////////////////////////////////
                  // i need to get the component quanitye per so
                  final totalScanned = (item.quantity * item.quantityPerUnit)
                      .toStringAsFixed(0);

                  // get the outOf for this item from the map widget.outOf["NAIL-001"]
                  final outOf = widget.outOf[item.itemNo] ?? 0;

                  ///////////////////////////////////////////
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: ExpandableText(
                                text: '${item.itemNo} - ${item.description}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: exists
                                      ? const Color(0xFF0F172A)
                                      : Colors
                                            .red, // red if item not in components list
                                ),
                              ),
                              subtitle: Text(
                                '${item.quantity} ${item.unitOfMeasure} = $totalScanned pcs out of $outOf',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),

                          // quantity input
                          SizedBox(
                            width: 50,
                            child: TextFormField(
                              controller: _qtyControllers[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              // only allow numbers 
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                             
                              onChanged: (value) => setQty(index, value),
                            ),
                          ),

                          const SizedBox(width: 4),

                          IconButton(
                            onPressed: () => removeItem(index),
                            icon: const Icon(
                              Icons.delete_outline_sharp,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // confirm scans button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // if list is empty or wrong qr code (does not exist in the component list )
                  onPressed:
                      (items.isEmpty ||
                          items.any(
                            (item) => !isItemInComponents(item.itemNo),
                          ) ||
                          isSubmitting ||errorMessage != null)
                      ? null
                      : () async {
                          setState(() => isSubmitting = true);

                          final provider = context.read<MesBarcodeProvider>();
                          //call the toJson method in the barcode model
                          //item.map iterates over each ItemBarcodeModel in items and for each item return a new map {} "return value of ToJson is a map"
                          //then convert toList = [{},{}]
                          final scans = items.map((e) => e.toJson()).toList();

                          final success = await provider.insertScans(
                            widget.executionId,
                            scans,
                          );

                          if (!mounted) return;

                          if (success) {
                            setState(() {
                              errorMessage = null;
                              isSubmitting = false;
                            });
                            // trigger bom stream refresh so quantities update immediately
                            context
                                .read<MesComponentconsumptionProvider>()
                                .triggerRefresh();
                            Navigator.pop(context);
                          } else {
                            setState(() {
                              errorMessage =
                                  provider.errorMessage ??
                                  'errorSubmittingScans'.tr();
                              isSubmitting = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'confirmScans'.tr(),
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
