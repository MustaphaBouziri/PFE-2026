import 'dart:convert';

import '../../../core/app_constants.dart';
import '../../shared/http_client.dart';
import '../../shared/http_response_parser.dart';
import '../models/mes_user_model.dart';

class MesUserService {
  Future<List<MesUser>> fetchAllMESUsers() async {
    final response = await HttpClient.post(AppConstants.fetchAllMESUsers, {});

    final usersList = HttpResponseParser.parseList(
      response,
      label: 'Fetch all users',
    );
    return usersList.map((json) => MesUser.fromJson(json)).toList();
  }

  Future<List<MesUser>> fetchMESUsersByWC({required String wcId}) async {
    final response = await HttpClient.post(AppConstants.fetchMESUsersByWC, {
      'wcId': wcId,
    });

    final usersList = HttpResponseParser.parseList(
      response,
      label: 'Fetch users by departement',
    );
    return usersList.map((json) => MesUser.fromJson(json)).toList();
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
    required String token,
    required String employeeId,
    required int roleInt,
    required List<String> workCenterList,
  }) async {
    final response = await HttpClient.post(AppConstants.adminCreateUser, {
      'token': token,
      'userId': employeeId,
      'employeeId': employeeId,
      'roleInt': roleInt,
      'workCenterListJson': jsonEncode(workCenterList),
    });

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
        'Failed to create MES user: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Changes the role of [targetUserId] to [newRoleInt] and replaces their
  /// work-center assignments with [workCenterList].
  ///
  /// newRoleInt: 0 = Operator, 1 = Supervisor, 2 = Admin
  Future<bool> changeUserRole({
    required String token,
    required String targetUserId,
    required int newRoleInt,
    required List<String> workCenterList,
  }) async {
    final response = await HttpClient.post(AppConstants.adminChangeUserRole, {
      'token': token,
      'targetUserId': targetUserId,
      'newRoleInt': newRoleInt,
      'workCenterListJson': jsonEncode(workCenterList),
    });

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
        'Failed to create MES user: ${response.statusCode} ${response.body}',
      );
    }
  }
}
