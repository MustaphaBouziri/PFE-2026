class OperationStatusAndProgressModel {
  final String prodOrderNo;
  final String machineNo;
  final String operationNo;
  final String operationStatus;
  final String startDateTime;
  final String endDateTime;
  final String declaredAt;
  final double totalProducedQuantity;
  final double scrapQuantity;
  final double orderQuantity;
  final double progressPercent;
  final String itemDescription;
  final String executionId;
  final String itemNo;

  OperationStatusAndProgressModel({
    required this.prodOrderNo,
    required this.machineNo,
    required this.operationNo,
    required this.operationStatus,
    required this.startDateTime,
    required this.endDateTime,
    required this.declaredAt,
    required this.totalProducedQuantity,
    required this.scrapQuantity,
    required this.orderQuantity,
    required this.progressPercent,
    required this.itemDescription,
    required this.executionId,
    required this.itemNo,
  });

  factory OperationStatusAndProgressModel.fromJson(Map<String, dynamic> json) {
    return OperationStatusAndProgressModel(
      prodOrderNo: json['prodOrderNo'] ?? '',
      machineNo: json['machineNo'] ?? '',
      operationNo: json['operationNo'] ?? '',
      operationStatus: json['operationStatus'] ?? '',
      startDateTime: json['startDateTime'] ?? '',
      endDateTime: json['endDateTime'] ?? '',
      declaredAt: json['declaredAt'] ?? '',
      totalProducedQuantity: (json['totalProducedQuantity'] as num? ?? 0)
          .toDouble(),
      scrapQuantity: (json['scrapQuantity'] as num? ?? 0).toDouble(),
      orderQuantity: (json['orderQuantity'] as num? ?? 0).toDouble(),
      progressPercent: (json['progressPercent'] as num? ?? 0).toDouble(),
      itemDescription: json['itemDescription'] ?? '',
      executionId: json['executionId'] ?? '',
      itemNo: json['itemNo'] ?? '',
    );
  }

  @override
  String toString() {
    return 'OperationStatusAndProgressModel('
        'prodOrderNo: $prodOrderNo, '
        'machineNo: $machineNo, '
        'operationNo: $operationNo, '
        'operationStatus: $operationStatus, '
        'startDateTime: $startDateTime, '
        'endDateTime: $endDateTime, '
        'lastUpdatedAt: $declaredAt, '
        'totalProducedQuantity: $totalProducedQuantity, '
        'scrapQuantity: $scrapQuantity, '
        'orderQuantity: $orderQuantity, '
        'progressPercent: $progressPercent, '
        'itemDescription: $itemDescription,'
        'itemNo: $itemNo,'
        'executionId:$executionId'
        ')';
  }
}
