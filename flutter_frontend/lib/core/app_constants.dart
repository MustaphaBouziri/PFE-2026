class AppConstants {
  static const String host = 'http://localhost:7048';
  static const String instance = 'BC210';
  static const String companyId = '9e31f41c-e73a-ed11-bbab-000d3a21ffa5';

  static const String _odataBase = '$host/$instance/ODataV4';
  static const String _apiBase = '$host/$instance/api/yourcompany/v1/v1.0';
  static const String _company = 'company=$companyId';

  static const String _authBase = '$_odataBase/MESAuthEndpoints_';

  static const String loginUrl = '${_authBase}Login?$_company';
  static const String meUrl = '${_authBase}Me?$_company';
  static const String changePasswordUrl =
      '${_authBase}ChangePassword?$_company';
  static const String logoutUrl = '${_authBase}Logout?$_company';
  static const String adminSetPasswordUrl =
      '${_authBase}AdminSetPassword?$_company';

  static const String _machinesBase =
      '$_odataBase/MESMachinesActionsEndpoints_';

  static const String fetchMachinesUrl =
      '${_machinesBase}FetchMachines?$_company';

  static const String getMachineOrdersUrl =
      '${_machinesBase}getMachineOrders?$_company';

  static const String getStartOrderValidation =
      '${_machinesBase}startOperation?$_company';

  static const String fetchMachineOperationStatus =
      '${_machinesBase}fetchOperationsStatus?$_company';

  static const String fetchMachineOperationStatusAndProgress =
      '${_machinesBase}fetchOperationsStatusAndProgress?$_company';

  static const String fetchOperationLiveData =
      '${_machinesBase}fetchOperationLiveData?$_company';

  static const String declareProduction =
      '${_machinesBase}declareProduction?$_company';

  static const String fetchProductionCycles =
      '${_machinesBase}fetchProductionCycles?$_company';

  static const String fetchMachineHistory =
      '${_machinesBase}fetchMachineHistory?$_company';

  // ── finish / cancel / Pause ────────────────────────────────────────────────────────
  // finishOperation  → progress = 100 %  (order fully completed)
  // cancelOperation  → progress < 100 %  (order cut short)
  // PauseOperation
  static const String finishOperationUrl =
      '${_machinesBase}finishOperation?$_company';

  static const String cancelOperationUrl =
      '${_machinesBase}cancelOperation?$_company';

  static const String pauseOperationUrl =
      '${_machinesBase}pauseOperation?$_company';
  static const String resumeOperationUrl =
      '${_machinesBase}resumeOperation?$_company';


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
