class AppConstants {
  static const String host = 'http://localhost:3000/api/';

  static const Map<String, String> jsonHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // AI agent endpoint (routed through Node middleware)
  static const String aiChatUrl = '${host}ai/chat';

  // ── Dev token ──────────────────────────────────────────────────────────────
  // Set to one of the fixed GUIDs from the MES API Debug page to bypass login.
  //{
  //  "operatorToken":"DE000000-0000-0000-0000-000000000001",
  //  "supervisorToken":"DE000000-0000-0000-0000-000000000002",
  //  "adminToken":"DE000000-0000-0000-0000-000000000003"
  // }
  // Set back to null before committing.
  static const String? devToken = null;

  // ── Auth ───────────────────────────────────────────────────────────────────
  static const String loginUrl            = '${host}Login';
  static const String meUrl               = '${host}Me';
  static const String changePasswordUrl   = '${host}ChangePassword';
  static const String logoutUrl           = '${host}Logout';
  static const String adminSetPasswordUrl = '${host}AdminSetPassword';

  // ── Read ───────────────────────────────────────────────────────────────────
  static const String fetchMachinesUrl            = '${host}FetchMachines';
  static const String getMachineOrdersUrl         = '${host}getMachineOrders';
  static const String fetchOngoingOperationsState = '${host}fetchOngoingOperationsState';
  static const String fetchOperationsHistory      = '${host}fetchOperationsHistory';
  static const String fetchOperationLiveData      = '${host}fetchOperationLiveData';
  static const String fetchProductionCycles       = '${host}fetchProductionCycles';
  static const String fetchBom                    = '${host}fetchBom';
  static const String fetchAllItemBarcodes        = '${host}fetchAllItemBarcodes';
  static const String fetchResolveBarcode         = '${host}resolveBarcode';

  // ── Write (all require token + onBehalfOfUserId in the request body) ───────
  static const String startOperation     = '${host}startOperation';
  static const String declareProduction  = '${host}declareProduction';
  static const String finishOperationUrl = '${host}finishOperation';
  static const String cancelOperationUrl = '${host}cancelOperation';
  static const String pauseOperationUrl  = '${host}pauseOperation';
  static const String resumeOperationUrl = '${host}resumeOperation';
  static const String declareScrapUrl    = '${host}declareScrap';
  static const String insertScans        = '${host}insertScans';

  // ── Admin ──────────────────────────────────────────────────────────────────
  static const String scrapCodesUrl     = '${host}scrapCodes';
  static const String employeesUrl      = '${host}employees';
  static const String workCentersUrl    = '${host}workCenters';
  static const String adminCreateUser   = '${host}AdminCreateUser';
  static const String fetchAllMESUsers  = '${host}fetchAllMESUsers';
  static const String fetchMESUsersByWC = '${host}fetchMESUsersByWC';

  // toggle active status of a user
  static const String toggleUserActiveStatus = '${host}AdminSetActive';
  static const String fetchActivityLog       = '${host}fetchActivityLog';
  static const String fetchMachineDashboard  = '${host}fetchMachineDashboard';
  static const String adminChangeUserRole    = '${host}AdminChangeUserRole';
}
