class MachineOrderModel {
  final String orderNo;
  final String status;
  final String operationNo;
  final DateTime? plannedStart;
  final DateTime? plannedEnd;
  final String itemNo;
  final String itemDescription;
  final double orderQuantity;
  final String operationDescription;

  MachineOrderModel({
    required this.orderNo,
    required this.status,
    required this.operationNo,
    required this.plannedStart,
    required this.plannedEnd,
    required this.itemNo,
    required this.itemDescription,
    required this.orderQuantity,
    required this.operationDescription,
  });

  factory MachineOrderModel.fromJson(Map<String, dynamic> json) {
    return MachineOrderModel(
      orderNo: json['orderNo'] ?? '',
      status: json['status'] ?? '',
      operationNo: json['operationNo'] ?? '',
      plannedStart: json['plannedStart'] != null
          ? DateTime.tryParse(json['plannedStart'].toString())
          : null,
      plannedEnd: json['plannedEnd'] != null
          ? DateTime.tryParse(json['plannedEnd'].toString())
          : null,
      itemNo: json['itemNo'] ?? '',
      itemDescription: json['ItemDescription'] ?? '',
      orderQuantity: (json['OrderQuantity'] ?? 0).toDouble(),
      operationDescription: json['operationDescription'] ?? '',
    );
  }
}