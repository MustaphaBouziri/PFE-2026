// =============================================================================
// AppConstants
// Path   : lib/core/constants/app_constants.dart
// Purpose: All hard-coded, code-level constants for the MES Flutter app.
//          These are NOT user-configurable — they are design decisions baked
//          into the application that must match the AL backend's own definitions.
//
//          User-configurable values belong in app_config.yaml / AppConfig.
//
// SYNC REQUIREMENT
//   Constants in the Api, auth, and ErrorCodes groups must stay in sync with
//   their counterparts in the AL backend.  When you change a field name, enum
//   value, or error code in AL, update the corresponding constant here too.
// =============================================================================

class AppConstants {
  AppConstants._(); // static-only — no instantiation

  static const api        = _Api();
  static const auth       = _Auth();
  static const routes     = _Routes();
  static const ui         = _Ui();
  static const storage    = _Storage();
  static const errorCodes = _ErrorCodes();
}


// =============================================================================
// API — OData action names, entity set names, JSON field names
// Keep in sync with: AL-backend/src/auth/3-CodeUnits/MESUnboundActions.al
//                    AL-backend/src/Admin/4-API/AdminAPIs.al
// =============================================================================
class _Api {
  const _Api();

  // OData action separator: <ServiceName>_<ProcedureName>
  static const String actionSeparator = '_';

  // auth action names — must match AL procedure names exactly
  static const String actionLogin          = 'Login';
  static const String actionLogout         = 'Logout';
  static const String actionMe             = 'Me';
  static const String actionChangePassword = 'ChangePassword';

  // Admin action names
  static const String actionAdminCreateUser  = 'AdminCreateUser';
  static const String actionAdminSetPassword = 'AdminSetPassword';
  static const String actionAdminSetActive   = 'AdminSetActive';

  // Machine action names
  static const String actionFetchMachines = 'FetchMachines';

  // Custom API entity set names — must match AL page EntitySetName
  static const String entitySetMesUsers       = 'mesUsers';
  static const String entitySetCreateMesUsers = 'createMesUsers';
  static const String entitySetEmployees      = 'employees';
  static const String entitySetWorkCenters    = 'workCenters';

  // OData company scoping
  static const String companyQueryParam = 'company';
  static const String companyIdHeader   = 'Company-Id';

  // Standard JSON response field names — must match AL JSON key literals
  static const String fieldSuccess       = 'success';
  static const String fieldError         = 'error';
  static const String fieldMessage       = 'message';
  static const String fieldToken         = 'token';
  static const String fieldExpiresAt     = 'expiresAt';
  static const String fieldUserId        = 'userId';
  static const String fieldName          = 'name';
  static const String fieldRole          = 'role';
  static const String fieldWorkCenterNo  = 'workCenterNo';
  static const String fieldNeedToChangePw = 'needToChangePw';
  static const String fieldIsActive      = 'isActive';
  static const String fieldValue         = 'value';  // OData collection wrapper
}


// =============================================================================
// auth — role values, field constraints, password rules
// Keep in sync with: AL-backend/src/auth/2-Enums/MES_UserRole.al
//                    AL-backend/src/auth/1-Tables/MES_USER.al
//                    AL-backend/src/auth/3-CodeUnits/MESAuthMgt.al (IsPasswordStrong)
// =============================================================================
class _Auth {
  const _Auth();

  // Role string values as returned by the BC API (match AL enum Caption values)
  static const String roleOperator   = 'Operator';
  static const String roleSupervisor = 'Supervisor';
  static const String roleAdmin      = 'Admin';

  // Role integer values (match AL enum ordinal — used in AdminCreateUser)
  static const int roleIntOperator   = 0;
  static const int roleIntSupervisor = 1;
  static const int roleIntAdmin      = 2;

  // Field length constraints — must stay in sync with AL table field lengths
  static const int maxUserIdLength     = 50;   // Code[50]  in MES User."User Id"
  static const int maxDeviceIdLength   = 100;  // Text[100] in MES auth Token."Device Id"
  static const int maxWorkCenterLength = 20;   // Code[20]  in MES User."Work Center No."
  static const int maxEmployeeIdLength = 50;   // Code[50]  in MES User."employee ID"

  // Password complexity rules — mirrors IsPasswordStrong() in MESAuthMgt.al
  static const int    minPasswordLength = 8;
  static const String passwordRuleHint  =
      'At least 8 characters with uppercase, lowercase, a number, and a special character.';

  // auth ID format — must match GenerateUniqueAuthId() in MES_USER.al
  static const String authIdPrefix      = 'AUTH-';
  static const int    authIdSuffixLength = 8;   // 'AUTH-' + 8 chars = 13 total

  // How many seconds before the server-side expiry to start the UI warning timer
  static const int tokenExpiryBufferSeconds = 60;
}


// =============================================================================
// Routes — named navigation route strings
// =============================================================================
class _Routes {
  const _Routes();

  static const String login          = '/login';
  static const String changePassword = '/change-password';
  static const String userDashboard  = '/dashboard';
  static const String machineList    = '/machines';
  static const String adminUsers     = '/admin/users';
  static const String adminAddUser   = '/admin/users/add';
}


// =============================================================================
// UI — responsive breakpoints, animation durations, spacing scale
// =============================================================================
class _Ui {
  const _Ui();

  // Responsive breakpoints (logical pixels)
  static const double breakpointMobile  = 600.0;
  static const double breakpointTablet  = 900.0;
  static const double breakpointDesktop = 1200.0;

  // Animation durations
  static const Duration animationFast   = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow   = Duration(milliseconds: 500);

  // Snackbar display duration
  static const Duration snackbarDuration = Duration(seconds: 3);

  // 8-point spacing scale
  static const double spacingXs  = 4.0;
  static const double spacingSm  = 8.0;
  static const double spacingMd  = 16.0;
  static const double spacingLg  = 24.0;
  static const double spacingXl  = 32.0;
  static const double spacingXxl = 48.0;

  // Border radii
  static const double borderRadiusSm = 4.0;
  static const double borderRadiusMd = 8.0;
  static const double borderRadiusLg = 12.0;

  // Avatar sizes
  static const double avatarSizeSm = 32.0;
  static const double avatarSizeMd = 48.0;
  static const double avatarSizeLg = 64.0;
}


// =============================================================================
// Storage — SharedPreferences / Flutter Secure Storage keys
// =============================================================================
class _Storage {
  const _Storage();

  // Secure storage — token and expiry must be encrypted
  static const String keyAuthToken   = 'auth_token';
  static const String keyTokenExpiry = 'auth_token_expiry';

  // SharedPreferences — non-sensitive session metadata
  static const String keyUserId      = 'session_user_id';
  static const String keyUserRole    = 'session_user_role';
  static const String keyWorkCenter  = 'session_work_center';
  static const String keyUserName    = 'session_user_name';
  static const String keyNeedChangePw = 'session_need_change_pw';
}


// =============================================================================
// ErrorCodes — canonical "error" field values returned by the BC API
// Keep in sync with: AL-backend/src/auth/3-CodeUnits/MESUnboundActions.al
// =============================================================================
class _ErrorCodes {
  const _ErrorCodes();

  static const String invalidRequest       = 'Invalid request';
  static const String authenticationFailed = 'Authentication failed';
  static const String unauthorized         = 'Unauthorized';
  static const String forbidden            = 'Forbidden';
  static const String passwordChangeFailed = 'Password change failed';
  static const String passwordUpdateFailed = 'Password update failed';
  static const String userCreationFailed   = 'User creation failed';
  static const String statusUpdateFailed   = 'Status update failed';
  static const String logoutFailed         = 'Logout failed';
  static const String internalError        = 'Internal error';
}
