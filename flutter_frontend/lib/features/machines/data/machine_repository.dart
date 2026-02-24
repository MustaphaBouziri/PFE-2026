// =============================================================================
// IMachinesRepository + MachinesRepository
// Path   : lib/features/machines/data/machines_repository.dart
// =============================================================================

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/machine_models.dart';

abstract interface class IMachinesRepository {
  /// Returns all machines for [workCenterNo] with their latest real-time status.
  Future<List<MesMachine>> getMachines(String workCenterNo);
}

class MachinesRepository implements IMachinesRepository {
  MachinesRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  @override
  Future<List<MesMachine>> getMachines(String workCenterNo) async {
    // FetchMachines is published under the separate MESMachineActions service.
    final data = await _client.postODataAction(
      AppConfig.bc.machineServiceName,
      AppConstants.api.actionFetchMachines,
      {'workCenterNo': workCenterNo},
    );

    final value = data[AppConstants.api.fieldValue];
    if (value is List) {
      return value.cast<Map<String, dynamic>>().map(MesMachine.fromJson).toList();
    }
    return [];
  }
}
