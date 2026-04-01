import '../../../data/machine/models/mes_machine_model.dart';
import '../../../data/machine/services/mes_MachineList.dart';

class MesMachinesProvider {
  final MESMachineListService _service = MESMachineListService();

  Stream<Map<String, List<MachineModel>>> streamOrderedMachinePerDepartments(
    List<String> workCenterList,
  ) {
    return _service.streamFetchOrderedMachinePerDepartments(workCenterList);
  }
}
