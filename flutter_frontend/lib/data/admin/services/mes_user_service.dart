import 'dart:convert';

import 'package:pfe_mes/core/storage/session_storage.dart';

import '../../../core/app_constants.dart';
import '../../shared/http_client.dart';
import '../../shared/http_response_parser.dart';
import '../models/mes_user_model.dart';

class MesUserService {
  final SessionStorage _sessionStorage = SessionStorage();

  Future<List<MesUser>> fetchAllMESUsers() async {
    final response =
    await HttpClient.post(AppConstants.fetchAllMESUsers, {});
    return HttpResponseParser.parseList(response, label: 'Fetch all users')
        .map((json) => MesUser.fromJson(json))
        .toList();
  }

  Future<List<MesUser>> fetchMESUsersByWC({required String wcId}) async {
    final response = await HttpClient.post(
      AppConstants.fetchMESUsersByWC,
      {'wcId': wcId},
    );
    return HttpResponseParser.parseList(
      response,
      label: 'Fetch users by department',
    )
        .map((json) => MesUser.fromJson(json))
        .toList();
  }

  Stream<List<MesUser>> streamFetchAllMESUsers({
    required Stream<void> trigger,
  }) async* {
    yield await fetchAllMESUsers();
    await for (final _ in trigger) {
      yield await fetchAllMESUsers();
    }
  }

  Future<bool> createMesUser({
    required String employeeId,
    required int roleInt,
    required List<String> workCenterList,
  }) async {
    final token = _sessionStorage.getToken();
    final response = await HttpClient.post(AppConstants.adminCreateUser, {
      'token': token,
      'userId': employeeId,
      'employeeId': employeeId,
      'roleInt': roleInt,
      'workCenterListJson': jsonEncode(workCenterList),
    });
    return HttpResponseParser.parseSuccess(
      response,
      label: 'createMesUser',
    );
  }

  Future<bool> changeUserRole({
    required String targetUserId,
    required int newRoleInt,
    required List<String> workCenterList,
  }) async {
    final token = _sessionStorage.getToken();
    final response = await HttpClient.post(AppConstants.adminChangeUserRole, {
      'token': token,
      'targetUserId': targetUserId,
      'newRoleInt': newRoleInt,
      'workCenterListJson': jsonEncode(workCenterList),
    });
    return HttpResponseParser.parseSuccess(
      response,
      label: 'changeUserRole',
    );
  }
}