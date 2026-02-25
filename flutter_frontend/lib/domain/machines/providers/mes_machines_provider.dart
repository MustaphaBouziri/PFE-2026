import '../../../data/machine/models/mes_machine_model.dart';
import '../../../data/machine/services/mes_MachineList.dart';

class MesMachinesProvider {
  final MESMachineListService _service = MESMachineListService();

  Stream<List<MachineModel>> getMachinesStream(String workCenterNo) {
    return _service.streamMachines(workCenterNo);
  }
}
