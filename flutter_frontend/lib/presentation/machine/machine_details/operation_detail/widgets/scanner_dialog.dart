import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pfe_mes/data/machine/barCode/models/mes_barCode_model.dart';
import 'package:pfe_mes/domain/machines/barCode/provider/mes_barCode_provider.dart';
import 'package:pfe_mes/presentation/widgets/expandableText.dart';
import 'package:provider/provider.dart';

class ScannerWidget extends StatefulWidget {
  final String executionId;
  const ScannerWidget({super.key,required this.executionId});

  @override
  State<ScannerWidget> createState() => _ScannerWidgetState();
}

class _ScannerWidgetState extends State<ScannerWidget> {
  String scannedValue = "scanSomething".tr();

  List<ItemBarcodeModel> items = []; // list to hold the scanned item

  final MobileScannerController controller = MobileScannerController();

  bool isScanning = true; // used for scan again ?

  // this function takes row barcode string and make it into an itemBarcodeModel
  ItemBarcodeModel parse(String raw) {
    // split the string into an array List using the | as separator
    /**
      from : Item Number:123|Item Description:Apple|Base UOM:kg
      to : ["Item Number:123", "Item Description:Apple", "Base UOM:kg"]
    */
    final barCodeTextList = raw.split('|');

    // we create an empty map, store key and  value  pairs
    Map<String, String> map = {};

    for (var b in barCodeTextList) {
      //for each element of the carCodeTextList we seperate each element like we did earlier " | "
      // with a sperator ":"

      /**
      from: ["Item Number:123", "Item Description:Apple", "Base UOM:kg"]
      to : keyvalue = ["Item Number", "123"]
      */
      var keyValue = b.split(':');
      if (keyValue.length == 2) {
        // two part item number + 123
        //trim keyValue(0) "Item Number"
        //we set the map its key to its value so it becomes :
        //{"Item Number": "123", "Item Description": "Apple", "Base UOM": "kg"}
        map[keyValue[0].trim()] = keyValue[1].trim();
      }
    }
    //we use the map to build the model
    //After the loop, we have a map where each key is a field name and each value is the corresponding value as a string
    return ItemBarcodeModel(
      itemNo: map['Item Number'] ?? '',
      description: map['Item Description'] ?? '',
      baseUOM: map['Base UOM'] ?? '',
      inventory: double.tryParse(map['Inventory'] ?? '0') ?? 0,
      shelfNo: map['Shelf No'] ?? '',
      lotSize: double.tryParse(map['Lot Size'] ?? '0') ?? 0,
      flushingMethod: map['Flushing Method'] ?? '',
      barcodeText: raw,
      quantity: 1,
    );
  }

  //______________________add item

  // we add new item or we increment qte
  void addItem(ItemBarcodeModel newItem) {
    int index = items.indexWhere((e) => e.itemNo == newItem.itemNo);

    if (index != -1) {
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
        );
      }
    });
  }

  //delete item from list
  void removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  // convert the list items into json to pass to the al
  /*
  [
   {...},
   {...}
 ]
 */

  @override
  Widget build(BuildContext context) {
    final isphone = MediaQuery.of(context).size.width <= 600;
    return Dialog(
      backgroundColor: Color(0xFFF8FAFC),
      child: SizedBox(
        width: isphone ? 400 : 500,
        height: 600,
        child: Column(
          children: [
            SizedBox(height: 16),
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
                      onDetect: (barcodeCapture) {
                        if (!isScanning) return;

                        final barcode =
                            barcodeCapture.barcodes.first; // dependacy made
                        final value = barcode
                            .rawValue; // the value of the barcode text scanned

                        if (value != null) {
                          //final item = parse... its like saying : /**
                          //so ItemBarcodeModel item = ItemBarcodeModel( itemNo: "ABC123", description: "White Glue", baseUOM: "EA", inventory: 100.0, shelfNo: "B4", lotSize: 25.0, flushingMethod: "Manual", barcodeText: rawString, quantity: 1, ); */
                          final item = parse(
                            value,
                          ); // convert the raw string into ItemBarcodeModel object with ==> ItemBarcodeModel parse(String raw)

                          setState(() {
                            addItem(item);
                            isScanning = false; // stop scanning after detection
                          });

                          controller.stop(); //freeze the camera
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 8),

            //resume camera button
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isScanning = true;
                });

                controller.start(); // unfreeze camera
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
                "scanAgain".tr(),
                style: TextStyle(color: Colors.white),
              ),
            ),

            // list
            Expanded(
              flex: 4,
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];

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
                                text: "${item.itemNo} - ${item.description}",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                "qty".tr() + "${item.quantity}",
                                style: TextStyle(color: Color(0xFF64748B)),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => increaseQty(index),
                            icon: Icon(Icons.add, color: Colors.black),
                          ),
                          IconButton(
                            onPressed: () => decreaseQty(index),
                            icon: Icon(Icons.remove, color: Colors.black),
                          ),
                          IconButton(
                            onPressed: () => removeItem(index),
                            icon: Icon(
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
            ElevatedButton(
              onPressed: () async {
                final provider = context.read<MesBarcodeProvider>();
                //call the toJson methode in the barcode mode
                //item.map iterates over each ItemBarcodeModel in items and for each item return a new map {} "return value of ToJson is a map"
                //then convert toList = [{},{}]

                final scans = items.map((e) => e.toJson()).toList();

                final success = await provider.insertScans(
                  widget.executionId,
                  scans,
                );

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text('insertedSuccessfully'.tr())),
                  );

                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(provider.errorMessage ?? 'error'.tr())),
                  );
                }
              },
              child:  Text('confirmScans'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
