import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
  const ScannerWidget({super.key, required this.executionId, required this.components});

  @override
  State<ScannerWidget> createState() => _ScannerWidgetState();
}

class _ScannerWidgetState extends State<ScannerWidget> {
  List<ItemBarcodeModel> items = [];
  final MobileScannerController controller = MobileScannerController();
  bool isScanning = true;
  //check if item is in components list
  bool isItemInComponents(String itemNo) {
  return widget.components.any((c) => c.itemNo == itemNo);
}

  // we add new item or we increment qty
  void addItem(ItemBarcodeModel newItem) {
    int index = items.indexWhere((e) => e.itemNo == newItem.itemNo);


    if (index != -1) {
      // same item already in list — increment quantity, keep all other fields
      items[index] = ItemBarcodeModel(
        itemNo: items[index].itemNo,
        description: items[index].description,
        baseUOM: items[index].baseUOM,
        inventory: items[index].inventory,
        shelfNo: items[index].shelfNo,
        lotSize: items[index].lotSize,
        flushingMethod: items[index].flushingMethod,
        barcodeText: items[index].barcodeText,
        quantity: items[index].quantity + 1,
        quantityPerUnit: items[index].quantityPerUnit,
        unitOfMeasure: items[index].unitOfMeasure,
      );
    } else {
      items.add(newItem);
    }
  }

  //increase quantity
  void increaseQty(int index) {
    setState(() {
      items[index] = ItemBarcodeModel(
        itemNo: items[index].itemNo,
        description: items[index].description,
        baseUOM: items[index].baseUOM,
        inventory: items[index].inventory,
        shelfNo: items[index].shelfNo,
        lotSize: items[index].lotSize,
        flushingMethod: items[index].flushingMethod,
        barcodeText: items[index].barcodeText,
        quantity: items[index].quantity + 1,
        quantityPerUnit: items[index].quantityPerUnit,
        unitOfMeasure: items[index].unitOfMeasure,
      );
    });
  }

  // decrease quantity
  void decreaseQty(int index) {
    setState(() {
      if (items[index].quantity > 1) {
        items[index] = ItemBarcodeModel(
          itemNo: items[index].itemNo,
          description: items[index].description,
          baseUOM: items[index].baseUOM,
          inventory: items[index].inventory,
          shelfNo: items[index].shelfNo,
          lotSize: items[index].lotSize,
          flushingMethod: items[index].flushingMethod,
          barcodeText: items[index].barcodeText,
          quantity: items[index].quantity - 1,
          quantityPerUnit: items[index].quantityPerUnit,
          unitOfMeasure: items[index].unitOfMeasure,
        );
      }
    });
  }

  //delete item from list
  void removeItem(int index) {
    setState(() => items.removeAt(index));
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
                    child: MobileScanner(
                      controller: controller,
                      onDetect: (barcodeCapture) async {
                        if (!isScanning) return;

                        final barcode = barcodeCapture.barcodes.first;
                        final value = barcode.rawValue;

                        if (value == null) return;

                        setState(() => isScanning = false);
                        controller.stop();

                        // all barcodes go through resolveBarcode now
                        // our datamatrix: bc looks up the code MES-1100 in item identifier
                        // external barcode: bc looks up the external code in identifier identifier
                        final result = await context
                            .read<MesBarcodeProvider>()
                            .resolveBarcode(value);

                        if (!mounted) return;

                        if (result == null || result['resolved'] != true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result?['message']?.toString() ??
                                    'Barcode not recognized',
                              ),
                            ),
                          );
                          return;
                        }

                        // build model from BC response — same structure for both our and external barcodes
                        final item = ItemBarcodeModel(
                          itemNo: result['itemNo']?.toString() ?? '',
                          description:
                              result['itemDescription']?.toString() ?? '',
                          baseUOM: result['baseUOM']?.toString() ?? '',
                          inventory: 0,
                          shelfNo: '',
                          lotSize: 0,
                          flushingMethod: '',
                          barcodeText: value,
                          quantity: 1,
                          quantityPerUnit:
                              (result['quantityPerUnitOfMeasure'] as num? ?? 1)
                                  .toDouble(),
                          unitOfMeasure:
                              result['unitOfMeasure']?.toString() ?? '',
                        );

                        setState(() => addItem(item));
                      },
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            //resume camera button
            ElevatedButton(
              onPressed: () {
                setState(() => isScanning = true);
                controller.start();
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

            // list of items you scanned
            Expanded(
              flex: 4,
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  // check if item is in components list
                  final exists =isItemInComponents(item.itemNo);
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
                                  color: exists? const Color(0xFF0F172A) : Colors.red, // red if item not in components list
                                ),
                              ),
                              subtitle: Text(
                                // shows: "Qty: 2 × BOX (100 PCS each) = 200 PCS total"
                                '${'qty'.tr()}${item.quantity} × ${item.unitOfMeasure} (${item.quantityPerUnit.toStringAsFixed(0)} PCS each) = ${(item.quantity * item.quantityPerUnit).toStringAsFixed(0)} PCS total',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => increaseQty(index),
                            icon: const Icon(Icons.add, color: Colors.black),
                          ),
                          IconButton(
                            onPressed: () => decreaseQty(index),
                            icon: const Icon(Icons.remove, color: Colors.black),
                          ),
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
                  onPressed: items.isEmpty
                      ? null
                      : () async {
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('insertedSuccessfully'.tr()),
                              ),
                            );
                            // trigger bom stream refresh so quantities update immediately
                            context
                                .read<MesComponentconsumptionProvider>()
                                .triggerRefresh();
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  provider.errorMessage ?? 'error'.tr(),
                                ),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
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
