import 'package:flutter/material.dart';
import 'package:pfe_mes/models/mes_machine_model.dart';
import 'package:pfe_mes/services/mes_MachineList.dart';

class MesMachinesProvider{
  final MESMachineListService _service = MESMachineListService();

  Stream <List<MachineModel>> getMachinesStream(String workCenterNo){
    return _service.streamMachines(workCenterNo);
  }

}
