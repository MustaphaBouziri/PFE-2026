// =============================================================================
// Machines Domain Model
// Path   : lib/features/machines/domain/machine_models.dart
// =============================================================================

class MesMachine {
  const MesMachine({
    required this.machineNo,
    required this.machineName,
    required this.status,
    required this.currentOrder,
  });

  final String machineNo;
  final String machineName;
  final String status;       // 'Idle' | 'Starting' | 'OutOfOrder'
  final String currentOrder;

  bool get isIdle       => status == 'Idle';
  bool get isStarting   => status == 'Starting';
  bool get isOutOfOrder => status == 'OutOfOrder';

  factory MesMachine.fromJson(Map<String, dynamic> j) => MesMachine(
    machineNo:    j['machineNo']    as String? ?? '',
    machineName:  j['machineName']  as String? ?? '',
    status:       j['status']       as String? ?? 'Idle',
    currentOrder: j['currentOrder'] as String? ?? '',
  );
}
