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

  static const String? devToken = null;

  //  Auth
  static String get login             => '${host}Login';
  static String get me                => '${host}Me';
  static String get changePassword    => '${host}ChangePassword';
  static String get logout            => '${host}Logout';
  static String get adminSetPassword  => '${host}AdminSetPassword';

  //  Read
  static String get fetchMachines             => '${host}FetchMachines';
  static String get getMachineOrders          => '${host}getMachineOrders';
  static String get fetchOngoingOperationsState  => '${host}fetchOngoingOperationsState';
  static String get fetchOperationsHistory       => '${host}fetchOperationsHistory';
  static String get fetchOperationLiveData       => '${host}fetchOperationLiveData';
  static String get fetchProductionCycles        => '${host}fetchProductionCycles';
  static String get fetchBom                     => '${host}fetchBom';
  static String get fetchAllItemBarcodes         => '${host}fetchAllItemBarcodes';
  static String get fetchResolveBarcode          => '${host}resolveBarcode';

  //  Write
  static String get startOperation      => '${host}startOperation';
  static String get declareProduction   => '${host}declareProduction';
  static String get finishOperation  => '${host}finishOperation';
  static String get cancelOperation  => '${host}cancelOperation';
  static String get pauseOperation   => '${host}pauseOperation';
  static String get resumeOperation  => '${host}resumeOperation';
  static String get declareScrap     => '${host}declareScrap';
  static String get insertScans         => '${host}insertScans';

  //  Admin
  static String get scrapCodesUrl           => '${host}scrapCodes';
  static String get workCentersUrl          => '${host}workCenters';
  static String get adminCreateUser         => '${host}AdminCreateUser';
  static String get fetchAllMESUsers        => '${host}fetchAllMESUsers';
  static String get fetchMESUsersByWC       => '${host}fetchMESUsersByWC';
  static String get fetchAllEmployees       => '${host}fetchAllEmployees';
  static String get toggleUserActiveStatus  => '${host}AdminSetActive';
  static String get fetchActivityLog        => '${host}fetchActivityLog';
  static String get fetchMachineDashboard   => '${host}fetchMachineDashboard';
  static String get adminChangeUserRole     => '${host}AdminChangeUserRole';
  static String get fetchSettings           => '${host}fetchSettings';
  static String get updateSettings          => '${host}updateSettings';

  // ── Badge 2FA ─────────────────────────────────────────────────────────────
  static String get verifyBadgeUrl      => '${host}VerifyBadge';
  static String get getBadgeSecretUrl   => '${host}GetBadgeSecret';
  static String get regenerateBadgeUrl  => '${host}RegenerateBadgeSecret';

}
