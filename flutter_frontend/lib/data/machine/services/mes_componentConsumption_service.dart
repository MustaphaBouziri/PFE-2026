

import '../../../core/app_constants.dart';
import '../../shared/http_client.dart';
import '../../shared/http_response_parser.dart';
import '../models/mes_componentConsumption_model.dart';

class MesComponentconsumptionService {
  Future<List<ComponentConsumptionModel>> fetchBom(
    String prodOrderNo,
    String operationNo,
  ) async {
    final response = await HttpClient.post(AppConstants.fetchBom, {
      'prodOrderNo': prodOrderNo,
      'operationNo': operationNo,
    });

    final list = HttpResponseParser.parseList(
      response,
      label: 'fetch Bill of materials',
    );

    return list.map((e) => ComponentConsumptionModel.fromJson(e)).toList();
  }

  Stream<List<ComponentConsumptionModel>> streamBom(
    String prodOrderNo,
    String operationNo,
    Stream<void> trigger,
  ) async* {
    yield await fetchBom(prodOrderNo, operationNo);
    await for (final _ in trigger) {
      yield await fetchBom(prodOrderNo, operationNo);
    }
  }
}
