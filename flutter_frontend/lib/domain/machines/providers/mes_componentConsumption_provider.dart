import 'dart:async';
import 'package:pfe_mes/data/machine/models/mes_componentConsumption_model.dart';
import 'package:pfe_mes/data/machine/services/mes_componentConsumption_service.dart';

class MesComponentconsumptionProvider {
  final MesComponentconsumptionService _service = MesComponentconsumptionService();
  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  void triggerRefresh() {
    _refreshController.add(());
  }

  @override
  void dispose() {
    _refreshController.close();
    //super.dispose(); useless cuz the class is not extending anything + and not extending anthing cuz stream useless to do notifier
  }

  Stream<List<ComponentConsumptionModel>> getBomStream(String prodOrderNo,
    String operationNo) {
    return _service.streamBom(prodOrderNo, operationNo, _refreshController.stream,);
  }
}