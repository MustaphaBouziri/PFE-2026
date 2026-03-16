class OperationStatusAndProgressModel {
  final String prodOrderNo;
  final String machineNo;
  final String operationNo;
  final String operationStatus;
  final String lastUpdatedAt;
  final double producedQty;
  final double scrapQty;
  final double orderQty;
  final double progressPercent;
  final String itemDescription;

  OperationStatusAndProgressModel({
    required this.prodOrderNo,
    required this.machineNo,
    required this.operationNo,
    required this.operationStatus,
    required this.lastUpdatedAt,
    required this.producedQty,
    required this.scrapQty,
    required this.orderQty,
    required this.progressPercent,
    required this.itemDescription,
  });

  factory OperationStatusAndProgressModel.fromJson(Map<String, dynamic> json) {
    return OperationStatusAndProgressModel(
      prodOrderNo:     json['prodOrderNo']     ?? '',
      machineNo:     json['machineNo']     ?? '',
      operationNo:     json['operationNo']     ?? '',
      operationStatus: json['operationStatus'] ?? '',
      lastUpdatedAt:   json['lastUpdatedAt']   ?? '',
      producedQty:     (json['producedQty']     as num? ?? 0).toDouble(),
      scrapQty:        (json['scrapQty']        as num? ?? 0).toDouble(),
      orderQty:        (json['orderQty']        as num? ?? 0).toDouble(),
      progressPercent: (json['progressPercent'] as num? ?? 0).toDouble(),
      itemDescription: json['itemDescription'] ?? '',
    );
  }
}