class ComponentConsumptionModel {
  final String id;
  final String executionId;
  final String prodOrderNo;
  final String itemNo;
  final String itemDescription;
  final String barcode;


  //final double plannedQuantity;
  final double numberScanned;

  final String operatorId;
  final String scannedAt;
  
  final double quantityPerUnit;
  final double totalQuantityScanned;
  // new 
  final double scrapQuantity;
  final double inventory;

  ComponentConsumptionModel({
    required this.id,
    required this.executionId,
    required this.prodOrderNo,
    required this.itemNo,
    required this.itemDescription,

    required this.barcode,

    //required this.plannedQuantity,
    required this.numberScanned,
    required this.totalQuantityScanned,

    required this.operatorId,
    required this.scannedAt,
  
    required this.quantityPerUnit,

    // new
    required this.scrapQuantity,
    required this.inventory

  });

  factory ComponentConsumptionModel.fromJson(Map<String, dynamic> json) {
    return ComponentConsumptionModel(
      id: json['id'] ?? '',
      executionId: json['executionId'] ?? '',
      prodOrderNo: json['prodOrderNo'] ?? '',
      itemNo: json['itemNo'] ?? '',
      itemDescription: json['itemDescription'] ?? '',
      barcode: json['barcode'] ?? '',

      //plannedQuantity: (json['plannedQuantity'] as num? ?? 0).toDouble(),
      numberScanned: (json['numberScanned'] as num? ?? 0).toDouble(),
      totalQuantityScanned: (json['totalQuantityScanned'] as num? ?? 0).toDouble(),
    
      operatorId: json['operatorId'] ?? '',
      scannedAt: json['scannedAt'] ?? '',
  
      quantityPerUnit: (json['quantityPerUnit'] as num? ?? 0).toDouble(),

      scrapQuantity: (json['scrapQuantity'] as num? ?? 0).toDouble(),
      inventory: (json['inventory'] as num? ?? 0).toDouble(),
    );
  }
}
