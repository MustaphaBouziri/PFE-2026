import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pfe_mes/core/constants/app_constants.dart';

Future<Map<String, dynamic>> login(String userId, String password) async {
  final response = await http.post(
    Uri.parse(AppConstants.loginUrl),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "userId": userId,
      "password": password,
      "deviceId": "test-device"
    }),
  );

  print("LOGIN STATUS: ${response.statusCode}");
  print("LOGIN BODY: ${response.body}");

  if (response.statusCode != 200 || response.body.isEmpty) {
    return {"success": false};
  }

  final decoded = jsonDecode(response.body);

  if (decoded["value"] == null) {
    return {"success": false};
  }

  return jsonDecode(decoded["value"]);
}

Future<bool> generatePassword(
  String token,
  String userId,
  String newPassword,
) async {
  final response = await http.post(
    Uri.parse(AppConstants.adminSetPasswordUrl),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "token": token,
      "userId": userId,
      "newPassword": newPassword
    }),
  );

  print("GENERATE STATUS: ${response.statusCode}");
  print("GENERATE BODY: ${response.body}");

  return response.statusCode == 200 || response.statusCode == 201;
}

void main() {

  const adminUser = "AUTH-8B15A685";
  const adminPassword = "jqiUH898@6";

  const testUser = "AUTH-E2F36612";

  test("Generate password 5 times then login with last password", () async {

    final adminLogin = await login(adminUser, adminPassword);

    expect(adminLogin["success"], true);

    final token = adminLogin["token"];

    expect(token, isNotNull);

    for (int run = 0; run < 5; run++) {

      print("\n=========== TEST RUN $run ===========");

      String lastPassword = "";

      // simulate clicking "generate password" 5 times
      for (int i = 0; i < 5; i++) {

        final password = "MesTest$run${i}A1!";

        print("Generated password: $password");

        final generated = await generatePassword(
          token,
          testUser,
          password,
        );

        expect(generated, true);

        lastPassword = password;
      }

      print("Trying login with LAST password: $lastPassword");

      final userLogin = await login(testUser, lastPassword);

      print("LOGIN RESULT: $userLogin");

      expect(userLogin["success"], true);
    }
  });
}