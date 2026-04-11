import 'package:flutter/foundation.dart';

import '../../../data/admin/models/erp_workCenter_model.dart';
import '../../../data/admin/services/erp_workCenter_service.dart';
import '../../shared/async_state_mixin.dart';

class ErpWorkcenterProvider with ChangeNotifier, AsyncStateMixin {
  final ErpWorkcenterService _service = ErpWorkcenterService();

  List<ErpWorkCenter> workCenters = [];

  Future<void> fetchWorkCenters() async {
    await runAsync(() async {
      workCenters = await _service.fetchWorkCenters();
    });
  }
}