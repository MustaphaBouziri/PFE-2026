class AppConstants {
  static const String host = 'http://localhost:7048';
  static const String instance = 'BC210';
  static const String companyId = '9e31f41c-e73a-ed11-bbab-000d3a21ffa5';

  static const String _odataBase = '$host/$instance/ODataV4';
  static const String _apiBase = '$host/$instance/api/yourcompany/v1/v1.0';
  static const String _company = 'company=$companyId';

  static const String _webServiceBase = '$_odataBase/MESWebService_';

  static const String loginUrl = '${_webServiceBase}Login?$_company';
  static const String meUrl = '${_webServiceBase}Me?$_company';
  static const String changePasswordUrl =
      '${_webServiceBase}ChangePassword?$_company';
  static const String logoutUrl = '${_webServiceBase}Logout?$_company';
  static const String adminSetPasswordUrl =
      '${_webServiceBase}AdminSetPassword?$_company';

  static const String fetchMachinesUrl =
      '${_webServiceBase}FetchMachines?$_company';

  static const String getMachineOrdersUrl =
      '${_webServiceBase}getMachineOrders?$_company';

  static const String getStartOrderValidation =
      '${_webServiceBase}startOperation?$_company';

  static const String fetchMachineOperationStatus =
      '${_webServiceBase}fetchOperationsStatus?$_company';

  static const String fetchMachineOperationStatusAndProgress =
      '${_webServiceBase}fetchOperationsStatusAndProgress?$_company';

  static const String fetchOperationLiveData =
      '${_webServiceBase}fetchOperationLiveData?$_company';

  static const String declareProduction =
      '${_webServiceBase}declareProduction?$_company';

  static const String fetchProductionCycles =
      '${_webServiceBase}fetchProductionCycles?$_company';

  static const String fetchMachineHistory =
      '${_webServiceBase}fetchMachineHistory?$_company';
  
      static const String fetchBom =
      '${_webServiceBase}fetchBom?$_company';


      




  // ── finish / cancel / Pause ────────────────────────────────────────────────────────
  // finishOperation  → progress = 100 %  (order fully completed)
  // cancelOperation  → progress < 100 %  (order cut short)
  // PauseOperation
  static const String finishOperationUrl =
      '${_webServiceBase}finishOperation?$_company';

  static const String cancelOperationUrl =
      '${_webServiceBase}cancelOperation?$_company';

  static const String pauseOperationUrl =
      '${_webServiceBase}pauseOperation?$_company';
  static const String resumeOperationUrl =
      '${_webServiceBase}resumeOperation?$_company';

  static String get employeesUrl => '$_apiBase/companies($companyId)/employees';

  static String get workCentersUrl =>
      '$_apiBase/companies($companyId)/workCenters';

  static String get mesUsersUrl => '$_apiBase/companies($companyId)/mesUsers';

  static String get createMesUserUrl =>
      '$_apiBase/companies($companyId)/createMesUsers';

  static const Map<String, String> jsonHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
}