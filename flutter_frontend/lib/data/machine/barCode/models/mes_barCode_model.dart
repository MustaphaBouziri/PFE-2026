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

  ItemBarcodeModel({
    required this.itemNo,
    required this.description,
    required this.baseUOM,
    required this.inventory,
    required this.shelfNo,
    required this.lotSize,
    required this.flushingMethod,
    required this.barcodeText,
    this.quantity=1
  });

  factory ItemBarcodeModel.fromJson(Map<String, dynamic> json) =>
      ItemBarcodeModel(
        itemNo: json['itemNo'] ?? '',
        description: json['description'] ?? '',
        baseUOM: json['baseUOM'] ?? '',
        inventory: (json['inventory'] ?? 0).toDouble(),
        shelfNo: json['shelfNo'] ?? '',
        lotSize: (json['lotSize'] ?? 0).toDouble(),
        flushingMethod: json['flushingMethod'] ?? '',
        barcodeText: json['barcodeText'] ?? '',
        
      );
}