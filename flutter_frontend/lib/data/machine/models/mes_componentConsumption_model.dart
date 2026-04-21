class ComponentConsumptionModel {
  final String id;
  final String executionId;
  final String prodOrderNo;
  final String itemNo;
  final String itemDescription;
  final String barcode;

  final double plannedQuantity;
  final double quantityScanned;

  final String operatorId;
  final String scannedAt;
  final bool belongsToThisOperation;
  final double quantityPerUnit;
  final double totalQuantityScanned;

  ComponentConsumptionModel({
    required this.id,
    required this.executionId,
    required this.prodOrderNo,
    required this.itemNo,
    required this.itemDescription,

    required this.barcode,

    required this.plannedQuantity,
    required this.quantityScanned,
    required this.totalQuantityScanned,

    required this.operatorId,
    required this.scannedAt,
    required this.belongsToThisOperation,
    required this.quantityPerUnit,
  });

  factory ComponentConsumptionModel.fromJson(Map<String, dynamic> json) {
    return ComponentConsumptionModel(
      id: json['id'] ?? '',
      executionId: json['executionId'] ?? '',
      prodOrderNo: json['prodOrderNo'] ?? '',
      itemNo: json['itemNo'] ?? '',
      itemDescription: json['itemDescription'] ?? '',
      barcode: json['barcode'] ?? '',

      plannedQuantity: (json['plannedQuantity'] as num? ?? 0).toDouble(),
      quantityScanned: (json['quantityScanned'] as num? ?? 0).toDouble(),
      totalQuantityScanned: (json['totalQuantityScanned'] as num? ?? 0).toDouble(),
    
      operatorId: json['operatorId'] ?? '',
      scannedAt: json['scannedAt'] ?? '',
      belongsToThisOperation: json['belongsToThisOperation'] ?? false,
      quantityPerUnit: (json['QuantityPerUnit'] as num? ?? 0).toDouble(),
    );
  }
}
