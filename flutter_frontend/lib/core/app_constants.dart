class AppConstants {
  static const String host = 'http://localhost:7048';
  static const String instance = 'BC210';
  static const String companyId = '9e31f41c-e73a-ed11-bbab-000d3a21ffa5';

  static const Map<String, String> jsonHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  static const String _odataBase = '$host/$instance/ODataV4';
  static const String _apiBase = '$host/$instance/api/yourcompany/v1/v1.0';
  static const String _company = 'company=$companyId';
  static const String _webServiceBase = '$_odataBase/MESWebService_';

  // ── Dev token ──────────────────────────────────────────────────────────────
  // Set to one of the fixed GUIDs from the MES API Debug page to bypass login.
  //{
  //  "operatorToken":"DE000000-0000-0000-0000-000000000001",
  //  "supervisorToken":"DE000000-0000-0000-0000-000000000002",
  //  "adminToken":"DE000000-0000-0000-0000-000000000003"
  // }
  // Set back to null before committing.
  static const String? devToken = 'DE000000-0000-0000-0000-000000000003';

  // ── Auth ───────────────────────────────────────────────────────────────────
  static const String loginUrl = '${_webServiceBase}Login?$_company';
  static const String meUrl = '${_webServiceBase}Me?$_company';
  static const String changePasswordUrl =
      '${_webServiceBase}ChangePassword?$_company';
  static const String logoutUrl = '${_webServiceBase}Logout?$_company';
  static const String adminSetPasswordUrl =
      '${_webServiceBase}AdminSetPassword?$_company';

  // ── Read ───────────────────────────────────────────────────────────────────
  static const String fetchMachinesUrl =
      '${_webServiceBase}FetchMachines?$_company';
  static const String getMachineOrdersUrl =
      '${_webServiceBase}getMachineOrders?$_company';
  static const String fetchMachineOperationStatusAndProgress =
      '${_webServiceBase}fetchOperationsStatusAndProgress?$_company';
  static const String fetchOperationLiveData =
      '${_webServiceBase}fetchOperationLiveData?$_company';
  static const String fetchProductionCycles =
      '${_webServiceBase}fetchProductionCycles?$_company';
  static const String fetchBom = '${_webServiceBase}fetchBom?$_company';
  static const String fetchAllItemBarcodes =
      '${_webServiceBase}fetchAllItemBarcodes?$_company';

  // ── Write (all require token + onBehalfOfUserId in the request body) ───────
  static const String getStartOrderValidation =
      '${_webServiceBase}startOperation?$_company';
  static const String declareProduction =
      '${_webServiceBase}declareProduction?$_company';
  static const String finishOperationUrl =
      '${_webServiceBase}finishOperation?$_company';
  static const String cancelOperationUrl =
      '${_webServiceBase}cancelOperation?$_company';
  static const String pauseOperationUrl =
      '${_webServiceBase}pauseOperation?$_company';
  static const String resumeOperationUrl =
      '${_webServiceBase}resumeOperation?$_company';
  static const String declareScrapUrl =
      '${_webServiceBase}declareScrap?$_company';
  static const String insertScans = '${_webServiceBase}insertScans?$_company';

  // ── Admin ──────────────────────────────────────────────────────────────────
  static String get scrapCodesUrl =>
      '$_apiBase/companies($companyId)/scrapCodes';

  static String get employeesUrl => '$_apiBase/companies($companyId)/employees';

  static String get workCentersUrl =>
      '$_apiBase/companies($companyId)/workCenters';

  static String get AdminCreateUser =>
      '${_webServiceBase}AdminCreateUser?$_company';

  static String get fetchAllMESUsers =>
      '${_webServiceBase}fetchAllMESUsers?$_company';

  static String get fetchMESUsersByWC =>
      '${_webServiceBase}fetchMESUsersByWC?$_company';

  // toggle active status of a user
  static String get toggleUserActiveStatus =>
      '${_webServiceBase}AdminSetActive?$_company';

  static String get fetchActivityLog =>
      '${_webServiceBase}fetchActivityLog?$_company';

  static String get fetchMachineDashboard =>
      '${_webServiceBase}fetchMachineDashboard?$_company';
  static String get AdminChangeUserRole =>
      '${_webServiceBase}AdminChangeUserRole?$_company';

}
