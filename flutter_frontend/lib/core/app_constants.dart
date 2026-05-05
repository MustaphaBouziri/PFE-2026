import 'package:shared_preferences/shared_preferences.dart';

class AppConstants {
  static String host = '';

  static Future<void> changeHost(String newHost) async {
  newHost = newHost.trim();

  if (newHost.isEmpty) return;

  if (!newHost.endsWith('/')) {
    newHost = '$newHost/';
  }

  host = newHost;

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('host', host);
}

  static bool hasHost() {
    return host.isNotEmpty;
  }

  static Future<void> loadHost() async {
  final prefs = await SharedPreferences.getInstance();
  host = prefs.getString('host') ?? '';
}

  static const Map<String, String> jsonHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // AI agent endpoint (routed through Node middleware)
  static String get aiChatUrl => '${host}ai/chat';

  // ── Dev token ──────────────────────────────────────────────────────────────
  // Set to one of the fixed GUIDs from the MES API Debug page to bypass login.
  //{
  //  "operatorToken":"DE000000-0000-0000-0000-000000000001",
  //  "supervisorToken":"DE000000-0000-0000-0000-000000000002",
  //  "adminToken":"DE000000-0000-0000-0000-000000000003"
  // }
  // Set back to null before committing.
  static const String? devToken ="DE000000-0000-0000-0000-000000000001";

  // ── Auth ───────────────────────────────────────────────────────────────────
  static String get loginUrl => '${host}Login';
  static String get meUrl => '${host}Me';
  static String get changePasswordUrl => '${host}ChangePassword';
  static String get logoutUrl => '${host}Logout';
  static String get adminSetPasswordUrl => '${host}AdminSetPassword';

  // ── Read ───────────────────────────────────────────────────────────────────
  static String get fetchMachinesUrl => '${host}FetchMachines';
  static String get getMachineOrdersUrl => '${host}getMachineOrders';
  static String get fetchOngoingOperationsState =>
      '${host}fetchOngoingOperationsState';
  static String get fetchOperationsHistory => '${host}fetchOperationsHistory';
  static String get fetchOperationLiveData => '${host}fetchOperationLiveData';
  static String get fetchProductionCycles => '${host}fetchProductionCycles';
  static String get fetchBom => '${host}fetchBom';
  static String get fetchAllItemBarcodes => '${host}fetchAllItemBarcodes';
  static String get fetchResolveBarcode => '${host}resolveBarcode';

  // ── Write (all require token + onBehalfOfUserId in the request body) ───────
  static String get startOperation => '${host}startOperation';
  static String get declareProduction => '${host}declareProduction';
  static String get finishOperationUrl => '${host}finishOperation';
  static String get cancelOperationUrl => '${host}cancelOperation';
  static String get pauseOperationUrl => '${host}pauseOperation';
  static String get resumeOperationUrl => '${host}resumeOperation';
  static String get declareScrapUrl => '${host}declareScrap';
  static String get insertScans => '${host}insertScans';

  // ── Admin ──────────────────────────────────────────────────────────────────
  static String get scrapCodesUrl => '${host}scrapCodes';
  static String get employeesUrl => '${host}employees';
  static String get workCentersUrl => '${host}workCenters';
  static String get adminCreateUser => '${host}AdminCreateUser';
  static String get fetchAllMESUsers => '${host}fetchAllMESUsers';
  static String get fetchMESUsersByWC => '${host}fetchMESUsersByWC';
  static String get fetchAllEmployees => '${host}fetchAllEmployees';

  // toggle active status of a user
  static String get toggleUserActiveStatus => '${host}AdminSetActive';
  static String get fetchActivityLog => '${host}fetchActivityLog';
  static String get fetchMachineDashboard => '${host}fetchMachineDashboard';
  static String get adminChangeUserRole => '${host}AdminChangeUserRole';
}
