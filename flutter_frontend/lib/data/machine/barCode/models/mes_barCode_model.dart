class ItemBarcodeModel {
  final String itemNo;
  final String description;
  final String baseUOM;
  final double inventory;
  final String shelfNo;
  final double lotSize;
  final String flushingMethod;
  final String barcodeText;
  final double quantity;
  // how many base units 1 scan of this barcode gives
  final double quantityPerUnit;
  final String unitOfMeasure;

  ItemBarcodeModel({
    required this.itemNo,
    required this.description,
    required this.baseUOM,
    required this.inventory,
    required this.shelfNo,
    required this.lotSize,
    required this.flushingMethod,
    required this.barcodeText,
    this.quantity = 1,
    required this.quantityPerUnit,
    required this.unitOfMeasure, 
  });

  factory ItemBarcodeModel.fromJson(Map<String, dynamic> json) =>
      ItemBarcodeModel(
        itemNo:          json['itemNo']          ?? '',
        description:     json['description']     ?? '',
        baseUOM:         json['baseUOM']          ?? '',
        inventory:       (json['inventory']       ?? 0).toDouble(),
        shelfNo:         json['shelfNo']          ?? '',
        lotSize:         (json['lotSize']         ?? 0).toDouble(),
        flushingMethod:  json['flushingMethod']   ?? '',
        barcodeText:     json['barcodeText']      ?? '',
        quantityPerUnit: (json['quantityPerUnit'] ?? 0).toDouble(),
        unitOfMeasure:   json['unitOfMeasure']    ?? '',
      );

  Map<String, dynamic> toJson() {
    return {
      'itemNo':                   itemNo,
      'barcode':                  barcodeText,
      // quantity = how many times operator scanned or manually set
      'quantityScanned':          quantity,
      'unitOfMeasure':            unitOfMeasure,
      // quantityPerUnitOfMeasure = how many base units 1 scan gives
      'quantityPerUnitOfMeasure': quantityPerUnit,
    };
  }
}