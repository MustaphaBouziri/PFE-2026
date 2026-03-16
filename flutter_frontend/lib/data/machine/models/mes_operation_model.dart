class OperationStatusAndProgressModel {
  final String prodOrderNo;
  final String machineNo;
  final String operationNo;
  final String operationStatus;
  final String lastUpdatedAt;
  final double totalProducedQuantity;
  final double scrapQuantity;
  final double orderQuantity;
  final double progressPercent;
  final String itemDescription;

  OperationStatusAndProgressModel({
    required this.prodOrderNo,
    required this.machineNo,
    required this.operationNo,
    required this.operationStatus,
    required this.lastUpdatedAt,
    required this.totalProducedQuantity,
    required this.scrapQuantity,
    required this.orderQuantity,
    required this.progressPercent,
    required this.itemDescription,
  });

  factory OperationStatusAndProgressModel.fromJson(Map<String, dynamic> json) {
    return OperationStatusAndProgressModel(
      prodOrderNo:          json['prodOrderNo']          ?? '',
      machineNo:            json['machineNo']            ?? '',
      operationNo:          json['operationNo']          ?? '',
      operationStatus:      json['operationStatus']      ?? '',
      lastUpdatedAt:        json['lastUpdatedAt']        ?? '',
      totalProducedQuantity:(json['totalProducedQuantity'] as num? ?? 0).toDouble(),
      scrapQuantity:        (json['scrapQuantity']        as num? ?? 0).toDouble(),
      orderQuantity:        (json['orderQuantity']        as num? ?? 0).toDouble(),
      progressPercent:      (json['progressPercent']      as num? ?? 0).toDouble(),
      itemDescription:      json['itemDescription']      ?? '',
    );
  }
}