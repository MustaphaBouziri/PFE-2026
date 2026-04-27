class AppConstants {
  static const String host = 'http://localhost:3000/api';

  static const Map<String, String> jsonHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  static const String _base = '$host/';

  // ── Dev token ──────────────────────────────────────────────────────────────
  // Set to one of the fixed GUIDs from the MES API Debug page to bypass login.
  //{
  //  "operatorToken":"DE000000-0000-0000-0000-000000000001",
  //  "supervisorToken":"DE000000-0000-0000-0000-000000000002",
  //  "adminToken":"DE000000-0000-0000-0000-000000000003"
  // }
  // Set back to null before committing.
  static const String? devToken = 'DE000000-0000-0000-0000-000000000001';
  //static const String? devToken = null;

  // ── Auth ───────────────────────────────────────────────────────────────────
  static const String loginUrl            = '${_base}Login';
  static const String meUrl               = '${_base}Me';
  static const String changePasswordUrl   = '${_base}ChangePassword';
  static const String logoutUrl           = '${_base}Logout';
  static const String adminSetPasswordUrl = '${_base}AdminSetPassword';

  // ── Read ───────────────────────────────────────────────────────────────────
  static const String fetchMachinesUrl            = '${_base}FetchMachines';
  static const String getMachineOrdersUrl         = '${_base}getMachineOrders';
  static const String fetchOngoingOperationsState = '${_base}fetchOngoingOperationsState';
  static const String fetchOperationsHistory      = '${_base}fetchOperationsHistory';
  static const String fetchOperationLiveData      = '${_base}fetchOperationLiveData';
  static const String fetchProductionCycles       = '${_base}fetchProductionCycles';
  static const String fetchBom                    = '${_base}fetchBom';
  static const String fetchAllItemBarcodes        = '${_base}fetchAllItemBarcodes';
  static const String fetchResolveBarcode         = '${_base}resolveBarcode';

  // ── Write (all require token + onBehalfOfUserId in the request body) ───────
  static const String startOperation     = '${_base}startOperation';
  static const String declareProduction  = '${_base}declareProduction';
  static const String finishOperationUrl = '${_base}finishOperation';
  static const String cancelOperationUrl = '${_base}cancelOperation';
  static const String pauseOperationUrl  = '${_base}pauseOperation';
  static const String resumeOperationUrl = '${_base}resumeOperation';
  static const String declareScrapUrl    = '${_base}declareScrap';
  static const String insertScans        = '${_base}insertScans';

  // ── Admin ──────────────────────────────────────────────────────────────────
  static const String scrapCodesUrl     = '${_base}scrapCodes';
  static const String employeesUrl      = '${_base}employees';
  static const String workCentersUrl    = '${_base}workCenters';
  static const String adminCreateUser   = '${_base}AdminCreateUser';
  static const String fetchAllMESUsers  = '${_base}fetchAllMESUsers';
  static const String fetchMESUsersByWC = '${_base}fetchMESUsersByWC';

  // toggle active status of a user
  static const String toggleUserActiveStatus = '${_base}AdminSetActive';
  static const String fetchActivityLog       = '${_base}fetchActivityLog';
  static const String fetchMachineDashboard  = '${_base}fetchMachineDashboard';
  static const String adminChangeUserRole    = '${_base}AdminChangeUserRole';
}
