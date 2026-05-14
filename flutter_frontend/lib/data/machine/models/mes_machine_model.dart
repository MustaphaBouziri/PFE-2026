class MachineModel {
  final String machineNo;
  final String machineName;
  final String status;
  final String currentOrder;
  final String workCenterNo;
  final String workCenterName;
  final String itemNo;
  final String itemDescription;
  final String operationNo;
  final String operationDescription;

  MachineModel({
    required this.machineNo,
    required this.machineName,
    required this.status,
    required this.currentOrder,
    required this.workCenterNo,
    required this.workCenterName,
    required this.itemNo,
    required this.itemDescription,
    required this.operationNo,
    required this.operationDescription

  });

  factory MachineModel.fromJson(Map<String, dynamic> json) {
    return MachineModel(
      machineNo: json['machineNo'] ?? '',
      machineName: json['machineName'] ?? '',
      status: json['status'] ?? 'Idle',
      currentOrder: json['currentOrder'] ?? '',
      workCenterNo: json['workCenterNo'] ?? '',
      workCenterName: json['workCenterName'] ?? '',
      itemNo: json['itemNo'] ?? '',
      itemDescription: json['itemDescription'] ?? '',
      operationNo: json['operationNo'] ?? '',
      operationDescription: json['operationDescription'] ?? '',
    );
  }
}
