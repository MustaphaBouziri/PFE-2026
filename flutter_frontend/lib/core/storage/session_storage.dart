import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../app_constants.dart';

/// Single source of truth for session persistence.
class SessionStorage {
  static const _kToken = 'session_token';
  static const _kUserData = 'session_user_data';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    final instance = _prefs;

    if (instance == null) {
      throw StateError(
        'SessionStorage is not initialized. Call await SessionStorage.init() before using it.',
      );
    }

    return instance;
  }

  // ── Token ────────────────────────────────────────────────────────────────

  String? getToken() {
    if (AppConstants.devToken != null && AppConstants.devToken!.isNotEmpty) {
      return AppConstants.devToken;
    }

    return prefs.getString(_kToken);
  }

  Future<void> saveToken(String token) async {
    await prefs.setString(_kToken, token);
  }

  // ── User data ────────────────────────────────────────────────────────────

  Map<String, dynamic> getUserData() {
    final raw = prefs.getString(_kUserData);

    if (raw == null || raw.isEmpty) return {};

    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> saveUserData(Map<String, dynamic> data) async {
    await prefs.setString(_kUserData, jsonEncode(data));
  }

  // ── Convenience accessors ────────────────────────────────────────────────

  String getUserId() {
    final data = getUserData();
    return data['authId']?.toString() ?? '';
  }

  String getRole() {
    final data = getUserData();
    return data['role']?.toString() ?? 'Operator';
  }

  List<String> getWorkCenters() {
    final data = getUserData();
    final raw = data['workCenters'];

    return raw is List ? raw.map((e) => e.toString()).toList() : <String>[];
  }

  String getFullName() {
    final data = getUserData();
    final raw = data['fullName'];

    return raw?.toString() ?? 'User';
  }

  // ── Clear ────────────────────────────────────────────────────────────────

  Future<void> clear() async {
    await prefs.remove(_kToken);
    await prefs.remove(_kUserData);
  }
}