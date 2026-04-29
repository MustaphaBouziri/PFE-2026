import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/auth/providers/auth_provider.dart';
import '../app_constants.dart';

class SessionStorage {

  Future<String?> getToken() async {
    if (AppConstants.devToken != null && AppConstants.devToken!.isNotEmpty) {
      return AppConstants.devToken;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('userData');

    if (raw == null || raw.isEmpty) {
      return {};
    }
    print("======================================================");
    print(jsonDecode(raw));
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<String> getUserId() async {
    final userData = await getUserData();
    print(userData);
    return userData['authId']?.toString() ?? '';
  }

  Future<String> getRole() async {
    final userData = await getUserData();
    return userData['role']?.toString() ?? 'Operator';
  }

  Future<List<String>> getWorkCenters() async {
    final userData = await getUserData();
    final rawWc = userData['workCenters'];

    return rawWc is List ? rawWc.map((e) => e.toString()).toList() : <String>[];
  }
}
