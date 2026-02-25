class MachineModel {
  final String machineNo;
  final String machineName;
  final String status;
  final String currentOrder;

  MachineModel({
    required this.machineNo,
    required this.machineName,
    required this.status,
    required this.currentOrder,
  });

  factory MachineModel.fromJson(Map<String, dynamic> json) {
    return MachineModel(
      machineNo: json['machineNo'] ?? '',
      machineName: json['machineName'] ?? '',
      status: json['status'] ?? 'Idle',
      currentOrder: json['currentOrder'] ?? '',
    );
  }
}
