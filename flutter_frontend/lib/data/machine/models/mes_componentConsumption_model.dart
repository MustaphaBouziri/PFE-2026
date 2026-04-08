class ComponentConsumptionModel {
  final String id;
  final String executionId;
  final String prodOrderNo;
  final String itemNo;
  final String itemDescription;
  final String barcode;
  //final String unitOfMeasure;

  final double plannedQuantity;
  final double quantityScanned;
  //final double quantityConsumed;
  //final double remainingQuantity;
  final String operatorId;
  final String scannedAt;
  final bool belongsToThisOperation;
  final double quantityPerUnit;

  ComponentConsumptionModel({
    required this.id,
    required this.executionId,
    required this.prodOrderNo,
    required this.itemNo,
    required this.itemDescription,

    required this.barcode,
   // required this.unitOfMeasure,
    required this.plannedQuantity,
    required this.quantityScanned,
    //required this.quantityConsumed,
    //required this.remainingQuantity,
    required this.operatorId,
    required this.scannedAt,
    required this.belongsToThisOperation,
    required this.quantityPerUnit
  });

  factory ComponentConsumptionModel.fromJson(Map<String, dynamic> json) {
    return ComponentConsumptionModel(
      id: json['id'] ?? '',
      executionId: json['executionId'] ?? '',
      prodOrderNo: json['prodOrderNo'] ?? '',
      itemNo: json['itemNo'] ?? '',
      itemDescription: json['itemDescription'] ?? '',
      barcode: json['barcode'] ?? '',
      //unitOfMeasure: json['unitOfMeasure'] ?? '',
      

      plannedQuantity: (json['plannedQuantity'] as num? ?? 0).toDouble(),
      quantityScanned: (json['quantityScanned'] as num? ?? 0).toDouble(),
      //quantityConsumed: (json['quantityConsumed'] as num? ?? 0).toDouble(),
      //remainingQuantity: (json['remainingQuantity'] as num? ?? 0).toDouble(),
      operatorId: json['operatorId'] ?? '',
      scannedAt: json['scannedAt'] ?? '',
      belongsToThisOperation : json['belongsToThisOperation'] ?? false,
      quantityPerUnit: (json['QuantityPerUnit'] as num? ?? 0).toDouble(),
    );
  }
}
