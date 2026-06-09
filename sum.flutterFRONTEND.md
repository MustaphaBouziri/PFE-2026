# Flutter MES Frontend — Complete Module Reference

---

## Project Identity

- **Package name:** `pfe_mes`
- **Framework:** Flutter (multi-platform: Android, iOS, Web, Windows, Linux, macOS)
- **State management:** Provider (`ChangeNotifier` + `Consumer`)
- **Localization:** `easy_localization` — supports `en`, `fr`, `ar` (RTL auto-handled), translation files at `assets/translations/{en,fr,ar}.json`
- **HTTP:** `package:http` (raw), wrapped by internal `HttpClient` and `HttpResponseParser`
- **Persistence:** `shared_preferences` via `SessionStorage`
- **Navigation:** `MaterialApp` + `Navigator`, global `RouteObserver<ModalRoute<void>> routeObserver`

---

## Entry Point — `lib/main.dart`

### Initialization sequence (`main()`)
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `SessionStorage.init()` — loads SharedPreferences singleton
3. `AppConstants.loadHost()` — restores saved host URL from SharedPreferences
4. `EasyLocalization.ensureInitialized()`
5. `runApp()` wrapping order: `EasyLocalization` → `DevicePreview` (enabled=false) → `MultiProvider` → `MyApp`

### Providers registered at root
| Provider | Type | Class |
|---|---|---|
| AuthProvider | ChangeNotifier | `AuthProvider` |
| MesUserProvider | ChangeNotifier | `MesUserProvider` |
| ErpEmployeeProvider | ChangeNotifier | `ErpEmployeeProvider` |
| MesSettingsProvider | ChangeNotifier | `MesSettingsProvider` |
| ErpWorkcenterProvider | ChangeNotifier | `ErpWorkcenterProvider` |
| MachineordersProvider | ChangeNotifier | `MachineordersProvider` |
| MesBarcodeProvider | ChangeNotifier | `MesBarcodeProvider` |
| MesScrapProvider | ChangeNotifier | `MesScrapProvider` |
| LogProvider | ChangeNotifier | `LogProvider` |
| AiChatProvider | ChangeNotifier | `AiChatProvider` |
| MesMachinesProvider | Plain Provider | `MesMachinesProvider` |
| MesComponentconsumptionProvider | Plain Provider | `MesComponentconsumptionProvider` |

### `MyApp`
- `MaterialApp` with `debugShowCheckedModeBanner: false`
- Theme: `scaffoldBackgroundColor: 0xFFF8FAFC`, `AppBarTheme` white with bottom border `0xFFE2E8F0`, `progressIndicatorTheme` color `0xFF0F172A`, `GoogleFonts.inter` text theme, body/display color `0xFF0F172A`
- `navigatorObservers: [routeObserver]`
- `home: _AuthGate`

### `_AuthGate` (StatefulWidget)
- `initState` → `addPostFrameCallback` → calls `context.read<AuthProvider>().checkAuthStatus()`
- `build` reads `AuthProvider` via `Consumer`
- Routing logic:
  - `!AppConstants.hasHost()` → `ParingPage`
  - `auth.isCheckingAuth` → `Scaffold` with `CircularProgressIndicator`
  - `auth.isAuthenticated && auth.needsPasswordChange` → `ChangePasswordPage`
  - `auth.isAuthenticated && role == 'Admin'` → `AdminPage`
  - `auth.isAuthenticated && role != 'Admin'` → `Machinelistpage`
  - `!auth.isAuthenticated` → `LoginPage`

---

## Core Layer

### `lib/core/app_constants.dart` — `AppConstants`

**Static state:**
- `static String host = ''` — base URL for all API calls

**Methods:**
| Method | Behavior |
|---|---|
| `changeHost(String newHost)` | Trims, appends `/` if missing, sets `host`, persists to SharedPreferences key `'host'` |
| `hasHost()` | Returns `host.isNotEmpty` |
| `loadHost()` | Reads key `'host'` from SharedPreferences into `host` |

**URL getters** (all `'${host}<endpoint>'`):

| Getter | Endpoint |
|---|---|
| `login` | `Login` |
| `me` | `Me` |
| `changePassword` | `ChangePassword` |
| `logout` | `Logout` |
| `adminSetPassword` | `AdminSetPassword` |
| `fetchMachines` | `FetchMachines` |
| `getMachineOrders` | `getMachineOrders` |
| `fetchOngoingOperationsState` | `fetchOngoingOperationsState` |
| `fetchOperationsHistory` | `fetchOperationsHistory` |
| `fetchOperationLiveData` | `fetchOperationLiveData` |
| `fetchProductionCycles` | `fetchProductionCycles` |
| `fetchBom` | `fetchBom` |
| `fetchAllItemBarcodes` | `fetchAllItemBarcodes` |
| `fetchResolveBarcode` | `resolveBarcode` |
| `startOperation` | `startOperation` |
| `declareProduction` | `declareProduction` |
| `finishOperation` | `finishOperation` |
| `cancelOperation` | `cancelOperation` |
| `pauseOperation` | `pauseOperation` |
| `resumeOperation` | `resumeOperation` |
| `declareScrap` | `declareScrap` |
| `insertScans` | `insertScans` |
| `scrapCodesUrl` | `scrapCodes` |
| `workCentersUrl` | `workCenters` |
| `adminCreateUser` | `AdminCreateUser` |
| `fetchAllMESUsers` | `fetchAllMESUsers` |
| `fetchMESUsersByWC` | `fetchMESUsersByWC` |
| `fetchAllEmployees` | `fetchAllEmployees` |
| `toggleUserActiveStatus` | `AdminSetActive` |
| `fetchActivityLog` | `fetchActivityLog` |
| `fetchMachineDashboard` | `fetchMachineDashboard` |
| `adminChangeUserRole` | `AdminChangeUserRole` |
| `fetchSettings` | `fetchSettings` |
| `updateSettings` | `updateSettings` |
| `verifyBadgeUrl` | `VerifyBadge` |
| `getBadgeSecretUrl` | `GetBadgeSecret` |
| `regenerateBadgeUrl` | `RegenerateBadgeSecret` |
| `aiChatUrl` | `ai/chat` (composed as `'${host}ai/chat'`) |

**Other constants:**
- `static const Map<String, String> jsonHeaders` = `{'Accept':'application/json','Content-Type':'application/json'}`
- `static const String? devToken = null` — when non-null overrides session token in `SessionStorage.getToken()`
- `static const bool aiDebug = false` — enables debug panel in `AiChatPage` when true

---

### `lib/core/storage/session_storage.dart` — `SessionStorage`

**SharedPreferences keys:**
- `'session_token'` → auth token
- `'session_user_data'` → JSON-encoded user data map

**Static singleton:** `static SharedPreferences? _prefs` — initialized once via `init()`

**Methods:**
| Method | Behavior |
|---|---|
| `static init()` | Calls `SharedPreferences.getInstance()`, stores in `_prefs` |
| `getToken()` | Returns `AppConstants.devToken` if non-null/non-empty, else `prefs.getString('session_token')` |
| `saveToken(String)` | `prefs.setString('session_token', token)` |
| `getUserData()` | Reads `'session_user_data'`, JSON-decodes to `Map<String,dynamic>`, returns `{}` on null/empty |
| `saveUserData(Map)` | JSON-encodes map, stores under `'session_user_data'` |
| `getUserId()` | `getUserData()['authId']?.toString() ?? ''` |
| `getRole()` | `getUserData()['role']?.toString() ?? 'Operator'` |
| `getWorkCenters()` | `getUserData()['workCenters']` cast to `List<String>` |
| `getFullName()` | `getUserData()['fullName']?.toString() ?? 'User'` |
| `clear()` | Removes both keys from prefs |

---

## Data Layer

### Shared HTTP Infrastructure

#### `lib/data/shared/http_client.dart` — `HttpClient`
- `static Future<http.Response> post(String url, Map<String,dynamic> body)`
- Calls `http.post(Uri.parse(url), headers: AppConstants.jsonHeaders, body: jsonEncode(body))`

#### `lib/data/shared/http_response_parser.dart` — `HttpResponseParser`

| Method | Input | Behavior |
|---|---|---|
| `parseList(response, label)` | `http.Response` | Asserts 200/201, decodes outer JSON, extracts `value` string, JSON-decodes that as `List<dynamic>` |
| `parseObject(response, label)` | `http.Response` | Same but extracts `value` as `Map<String,dynamic>` |
| `parseWriteResult(response, label)` | `http.Response` | Extracts inner `value` field — if `true` returns `true`, else throws with `message` field |
| `parseSuccess(response, label)` | `http.Response` | Asserts 200/201, returns `true` |
| `_assertSuccess(response, label)` | private | Throws `Exception('$label failed: $statusCode $body')` if not 200 or 201 |

**BC OData response shape assumed:** `{ "value": "<JSON-string>" }`

---

### Admin Data

#### `lib/data/admin/models/erp_employees_model.dart` — `ErpEmployee`
Fields: `employeeId`, `firstName`, `middleName`, `lastName`, `email`, `imageBase64?`
- `fromJson`: maps `id`→`employeeId`, `firstName`, `middleName`, `lastName`, `email`, `imageBase64`
- `get fullName`: joins non-empty parts with space, returns `'No Name'` if all empty

#### `lib/data/admin/models/erp_workCenter_model.dart` — `ErpWorkCenter`
Fields: `id`, `workCenterName`
- `fromJson`: maps `id`, `workCenterName`

#### `lib/data/admin/models/mes_user_model.dart` — `MesUser`
Fields: `userId`, `employeeId`, `role`, `fullName`, `email`, `workCenterNames (List<String>)`, `authId`, `isActive`, `isOnline`, `isPendingSetup`, `lastSeenAt`, `imageBase64?`
- `fromJson`: maps all fields; `workCenters` JSON array → `List<String>`; `isOnline` and `isPendingSetup` require `== true` (strict boolean)
- `get workCenterNameTextFormat`: joins with `', '` or returns `'-'`

#### `lib/data/admin/models/mes_log_model.dart`

**`ActivityLogModel`**
Fields: `type`, `operatorId`, `operatorName`, `declaredById`, `declaredByName`, `machineNo`, `prodOrderNo`, `operationNo`, `action`, `timestamp`
- `get icon`: `status_change`→play_circle_outline, `production`→add_circle_outline, `scrap`→warning_amber_outlined, `scan`→qr_code_scanner, default→circle_outlined
- `get color`: status_change→`0xFF2563EB`, production→`0xFF16A34A`, scrap→`0xFFDC2626`, scan→`0xFF7C3AED`, default→`0xFF64748B`
- `mapType(uiType)`: maps UI labels (`'Status'`→`'status_change'`, `'Productions'`→`'production'`, `'Scraps'`→`'scrap'`, `'Scans'`→`'scan'`, default→`''`)

**`MachineDashboardModel`**
Fields: `machineNo`, `machineName`, `workCenterNo`, `operationFinished (int)`, `operationCancelled (int)`, `uptimePercent (double)`, `runningMinutes (double)`, `totalProduced (double)`, `totalScrap (double)`
- `get formattedUptime`: converts `runningMinutes` to human-readable string (`'0min'`, `'${mins}min'`, `'${h}h'`, or `'${h}h ${m}min'`)

#### `lib/data/admin/models/settings_model.dart` — `SettingModel`
Fields: `pwChangePeriod (String)`, `twoFAEnabled (bool, default false)`
- `fromJson`, `toJson`, `copyWith`

---

#### `lib/data/admin/services/erp_employee_service.dart` — `ErpEmployeeService`
- `fetchEmployees()` → POST `AppConstants.fetchAllEmployees` with `{}` → `parseList` → `List<ErpEmployee>`

#### `lib/data/admin/services/erp_workCenter_service.dart` — `ErpWorkcenterService`
- `fetchWorkCenters()` → raw `http.get` `AppConstants.workCentersUrl` (GET, not POST) → decodes JSON, reads `value` array → `List<ErpWorkCenter>`
- Note: uses raw `http.get` directly, not `HttpClient`

#### `lib/data/admin/services/mes_log_service.dart` — `LogService`
- `fetchActivityLog(int hoursBack)` → POST `fetchActivityLog` with `{hoursBack: hoursBack.toDouble()}` → `List<ActivityLogModel>`
- `fetchMachineDashboard(int hoursBack, List<String> workCenterList)` → POST `fetchMachineDashboard` with `{hoursBack: hoursBack.toDouble(), workCenterNoJson: jsonEncode(workCenterList)}` → `List<MachineDashboardModel>`

#### `lib/data/admin/services/mes_user_service.dart` — `MesUserService`
- `fetchAllMESUsers()` → POST `fetchAllMESUsers` `{}` → `List<MesUser>`
- `fetchMESUsersByWC(wcId)` → POST `fetchMESUsersByWC` `{wcId}` → `List<MesUser>`
- `streamFetchAllMESUsers(trigger)` → async* yields `fetchAllMESUsers()` then re-yields on each trigger event
- `createMesUser(employeeId, roleInt, workCenterList)` → POST `adminCreateUser` with `{token, userId: employeeId, employeeId, roleInt, workCenterListJson: jsonEncode(list)}` → `parseSuccess`
- `changeUserRole(targetUserId, newRoleInt, workCenterList)` → POST `adminChangeUserRole` with `{token, targetUserId, newRoleInt, workCenterListJson}` → `parseSuccess`

#### `lib/data/admin/services/setting_service.dart` — `SettingService`
- `fetchSettings()` → POST `fetchSettings` `{}` → `parseObject` → `SettingModel`
- `updateSettings(SettingModel)` → POST `updateSettings` with `{pwChangePeriodDays: int.tryParse(updated.pwChangePeriod.trim()), twoFAEnabled: bool, token}` → `parseSuccess`; note: `pwChangePeriodDays` is sent as `int?` via `int.tryParse`

#### `lib/data/admin/services/exportUserService/export_user_main.dart` — `ExportUserService`
- `exportUsersToExcel(List<MesUser> users)`: creates Excel document via the `excel` package
- Renames default sheet to `'Users'`
- Headers (row 0, bold): Full Name, Email, Role, Status
- Data rows: `user.fullName`, `user.email`, `user.role`, `user.isPendingSetup ? 'Pending' : 'Active'`
- Column widths: 25, 35, 20, 15; header row height 22, data rows height 20
- Delegates download to platform-specific implementation via conditional import: `export_user_mobile.dart` on native, `export_user_web.dart` on web
- File name: `'MES_Users_${DateTime.now().millisecondsSinceEpoch}.xlsx'`

#### `lib/data/admin/services/exportUserService/export_user_web.dart`
- `downloadFile(List<int> bytes, String fileName)`: creates a `Blob`, generates object URL, creates `<a>` element with `download` attribute, clicks it, then revokes URL via `dart:html`

#### `lib/data/admin/services/exportUserService/export_user_mobile.dart`
- `downloadFile(List<int> bytes, String fileName)`: writes bytes to `getApplicationDocumentsDirectory()`, then calls `Share.shareXFiles([XFile(filePath)])` via `share_plus`

---

### AI Data

#### `lib/data/ai/models/ai_chat_model.dart`

**`ConversationTurn`**: `role (String)`, `content (String)` — `toJson()` → `{role, content}`

**`AiRedirectAction`**: `actionType`, `label`, `payload (Map, default const {})` — `fromJson`

**`AiChatResponse`**: `text`, `actions (List<AiRedirectAction>, default const [])`, `error?` — `fromJson`

#### `lib/data/ai/services/ai_chat_service.dart` — `AiChatService`
- `sendMessage(message, history)` → POST `AppConstants.aiChatUrl` with body `{message, user_context: {user_id, role, work_centers, token}, conversation_history: history.map(toJson).toList()}` → decodes → `AiChatResponse`
- Uses raw `http.post`, not `HttpClient`
- Prints decoded body to console (`print(jsonDecode(body))`)

---

### Auth Data

#### `lib/data/auth/services/api_service.dart` — `ApiService`
Constructor: `ApiService({SessionStorage? storage})` — defaults to `SessionStorage()`

| Method | Endpoint | Body fields | Side effects | Returns |
|---|---|---|---|---|
| `login(authId, password, deviceId)` | `AppConstants.login` | `{userId, password, deviceId}` | none | `Map<String,dynamic>` with `success`, `token`, user fields |
| `getCurrentUser()` | `AppConstants.me` | `{token}` | On success: `saveUserData`, `saveToken(token?? '')` | `Map<String,dynamic>` |
| `changePassword(oldPw, newPw)` | `AppConstants.changePassword` | `{token, oldPassword, newPassword}` | none | `Map<String,dynamic>` |
| `logout()` | `AppConstants.logout` | `{token}` | `storage.clear()` always (even on exception) | `Map<String,dynamic>` (returns `{success:true}` on exception) |
| `adminSetPassword(userId, newPw)` | `AppConstants.adminSetPassword` | `{token, userId, newPassword}` | none | `bool` |
| `toggleUserActiveStatus(userId, isActive)` | `AppConstants.toggleUserActiveStatus` | `{token, userId, isActive}` | none | `bool` |
| `verifyBadge(scannedSecret, token)` | `AppConstants.verifyBadgeUrl` | `{scannedSecret, token}` | none | `Map<String,dynamic>` |
| `getBadgeSecret(targetUserId)` | `AppConstants.getBadgeSecretUrl` | `{adminToken: token, targetUserId}` | none | `Map<String,dynamic>` |
| `regenerateBadge(targetUserId)` | `AppConstants.regenerateBadgeUrl` | `{adminToken: token, targetUserId}` | none | `Map<String,dynamic>` |

---

### Machine Data

#### `lib/data/machine/models/mes_machine_model.dart` — `MachineModel`
Fields: `machineNo`, `machineName`, `status (default 'Idle')`, `currentOrder`, `workCenterNo`, `workCenterName`, `itemNo`, `itemDescription`, `operationNo`, `operationDescription`

#### `lib/data/machine/models/erp_order_model.dart` — `MachineOrderModel`
Fields: `orderNo`, `status`, `operationNo`, `plannedStart (DateTime?)`, `plannedEnd (DateTime?)`, `itemNo`, `itemDescription`, `orderQuantity (double)`, `operationDescription`, `description`
- `fromJson`: `plannedStart`/`plannedEnd` → `DateTime.tryParse`; JSON key `'ItemDescription'` (capital I) → `itemDescription`; JSON key `'OrderQuantity'` (capital O) → `orderQuantity`

#### `lib/data/machine/models/mes_operation_model.dart` — `OperationStatusAndProgressModel`
Fields: `prodOrderNo`, `machineNo`, `operationNo`, `operationStatus`, `startDateTime`, `endDateTime`, `declaredAt`, `totalProducedQuantity (double)`, `scrapQuantity (double)`, `orderQuantity (double)`, `progressPercent (double)`, `itemDescription`, `executionId`, `itemNo`, `operationDescription`

#### `lib/data/machine/models/mes_production_cycle.dart` — `ProductionCycleModel`
Fields: `orderQuantity`, `cycleQuantity`, `totalProducedQuantity`, `scrapQuantity`, `operatorId`, `firstName`, `lastName`, `declaredAt`
- `get fullName`: `'$firstName $lastName'.trim()`
- `get timeLabel`: parses `declaredAt` as `DateTime`, formats as `'HH:mm'`; returns raw `declaredAt` on parse error
- `get fullLabel`: formats as `'dd/MM HH:mm'`; returns raw `declaredAt` on parse error

#### `lib/data/machine/models/mes_componentConsumption_model.dart` — `ComponentConsumptionModel`
Fields: `id`, `executionId`, `prodOrderNo`, `itemNo`, `itemDescription`, `barcode`, `numberScanned (double)`, `totalQuantityScanned (double)`, `operatorId`, `scannedAt`, `quantityPerUnit (double)`, `scrapQuantity (double)`, `inventory (double)`, `baseUOM`, `baseUOMQuantityPerUnit (double, default 1)`

#### `lib/data/machine/models/mes_scrapCode_model.dart` — `MesScrapCode`
Fields: `code`, `description`
- `get displayLabel`: `'$code – $description'`

#### `lib/data/machine/barCode/models/mes_barCode_model.dart` — `ItemBarcodeModel`
Fields: `itemNo`, `description`, `baseUOM`, `lotSize (double)`, `flushingMethod`, `barcodeText`, `quantity (double, default 1)`, `quantityPerUnit (double)`, `unitOfMeasure`
- `toJson()`: `{itemNo, barcode: barcodeText, quantityScanned: quantity, unitOfMeasure, quantityPerUnitOfMeasure: quantityPerUnit}`

---

#### `lib/data/machine/services/mes_MachineList.dart` — `MESMachineListService`
- `fetchOrderedMachinePerDepartments(List<String> workCenterNos)` → POST `AppConstants.fetchMachines` with `{workCenterNoJson: jsonEncode({workCenterNos: workCenterNos})}` → parses list → groups `MachineModel` by `workCenterNo` → `Map<String,List<MachineModel>>`
- `streamFetchOrderedMachinePerDepartments(workCenterList)` → async* while(true): yields fetch result, awaits 20-second delay

#### `lib/data/machine/services/erp_order_service.dart` — `ErpMachineOrdersService`

| Method | Endpoint | Body | Returns |
|---|---|---|---|
| `getMachineOrders(machineNo)` | `getMachineOrders` | `{machineNo}` | `List<MachineOrderModel>` |
| `startOperation(prodOrderNo, operationNo, machineNo)` | `startOperation` | `{token, prodOrderNo, operationNo, machineNo}` | `bool` (parseWriteResult) |
| `finishOperation(...)` | `finishOperation` | via `_setOperationStatus` | `bool` |
| `cancelOperation(...)` | `cancelOperation` | via `_setOperationStatus` | `bool` |
| `pauseOperation(...)` | `pauseOperation` | via `_setOperationStatus` | `bool` |
| `resumeOperation(...)` | `resumeOperation` | via `_setOperationStatus` | `bool` |
| `fetchOngoingOperationsState(machineNo)` | `fetchOngoingOperationsState` | `{machineNo}` | `List<OperationStatusAndProgressModel>` |
| `fetchOperationsHistory(machineNo)` | `fetchOperationsHistory` | `{machineNo}` | `List<OperationStatusAndProgressModel>` |
| `fetchOperationLiveData(machineNo, prodOrderNo, operationNo)` | `fetchOperationLiveData` | `{machineNo, prodOrderNo, operationNo}` | `OperationStatusAndProgressModel?` (first element or null) |
| `declareProduction(prodOrderNo, operationNo, machineNo, input, onBehalfOfUserId)` | `declareProduction` | `{token, prodOrderNo, operationNo, machineNo, input, onBehalfOfUserId}` | `bool` |
| `fetchProductionCycles(machineNo, prodOrderNo, operationNo)` | `fetchProductionCycles` | all three | `List<ProductionCycleModel>` |

**Streams:**
- `streamMachinesOngoingOperationsState(machineNo, trigger?)` → async* while(true): yields fetch result (empty list on error), awaits 5s delay OR `trigger.first` (whichever comes first via `Future.any`)
- `streamFetchOperationLiveData(machineNo, prodOrderNo, operationNo, trigger)` → async*: yields initial fetch, then re-yields on each trigger event
- `streamProductionCycles(machineNo, prodOrderNo, operationNo, trigger)` → async*: same trigger-re-fetch pattern

**`_setOperationStatus`** — shared POST helper for finish/cancel/pause/resume: body `{token, machineNo, prodOrderNo, operationNo}`

#### `lib/data/machine/services/mes_componentConsumption_service.dart` — `MesComponentconsumptionService`
- `fetchBom(prodOrderNo, operationNo)` → POST `AppConstants.fetchBom` with `{prodOrderNo, operationNo}` → `List<ComponentConsumptionModel>`
- `streamBom(prodOrderNo, operationNo, trigger)` → async*: yields initial fetch, then re-yields on each trigger event

#### `lib/data/machine/services/mes_scrap_service.dart` — `MesScrapService`
- `fetchScrapCodes()` → raw `http.get` `AppConstants.scrapCodesUrl` → reads `value` array → `List<MesScrapCode>`; note: uses raw `http.get`, not `HttpClient`
- `declareScrap(executionId, scrapCode, quantity, description, materialId, onBehalfOfUserId)` → POST `AppConstants.declareScrap` with `{token, executionId, description, scrapCode, quantity, materialId, onBehalfOfUserId}` → `parseWriteResult`

#### `lib/data/machine/barCode/services/mes_barCode_service.dart` — `MesBarcodeService`
- `fetchAllBarcodes()` → POST `AppConstants.fetchAllItemBarcodes` `{}` → outer `value` string → inner JSON array → `List<ItemBarcodeModel>`
- `insertScans(executionId, scans)` → POST `AppConstants.insertScans` with `{token, executionId, scansJson: jsonEncode(scans)}` → parses inner `value` bool; extensive error extraction for BC 400 responses (tries `error.message`, then inner `value.message`, then falls back to raw body)
- `resolveBarcode(barcode)` → POST `AppConstants.fetchResolveBarcode` `{barcode}` → returns `Map<String,dynamic>?` (null on non-200)

---

## Domain Layer

### Shared Mixin

#### `lib/domain/shared/async_state_mixin.dart` — `AsyncStateMixin`
Mixin on `ChangeNotifier`:
- `bool isLoading = false`
- `String? errorMessage`
- `Future<T?> runAsync<T>(Future<T> Function() action)`: sets `isLoading=true`, `errorMessage=null`, notifies, runs action, catches exception to `errorMessage`, finally sets `isLoading=false`, notifies. Returns `T?` or null on error.

---

### Auth Domain

#### `lib/domain/auth/providers/auth_provider.dart` — `AuthProvider`

**State fields:**
- `_isAuthenticated`, `_isLoading`, `_errorMessage`, `_userData`
- `_pendingBadge (bool)` — true when 2FA badge scan is required
- `_pendingToken`, `_pendingUserData`, `_pendingUserId` — held in memory during 2FA flow; not persisted until badge passes
- `_isCheckingAuth (bool)` — true while `checkAuthStatus()` is running

**Constructor:** calls `_syncUserDataFromSession()` which loads `getUserData()` into `_userData`

| Method | Behavior |
|---|---|
| `checkAuthStatus()` | Sets `_isCheckingAuth=true`, calls `apiService.getCurrentUser()`. On success: sets `_isAuthenticated=true`, syncs userData from session. On fail: calls `logout()`. Finally: `_isCheckingAuth=false` |
| `login(userId, password)` | Generates `deviceId` as `'flutter-device-${millisecondsSinceEpoch}'`. Calls `apiService.login(userId, password, deviceId)`. On fail: sets error, returns false. If `twoFAEnabled==true`: sets `_pendingBadge=true`, stores token/userData/userId in memory, returns true without persisting. If no 2FA: persists token+data, sets `_isAuthenticated=true`, returns true |
| `changePassword(old, new)` | Calls `apiService.changePassword`. On success: updates `_userData['needToChangePw']=false`, re-saves userData |
| `adminSetPassword(userId, newPw)` | Delegates to `apiService.adminSetPassword` |
| `logout()` | Calls `apiService.logout()`, sets `_isAuthenticated=false` |
| `toggleUserActiveStatus(userId, isActive)` | Delegates to `apiService.toggleUserActiveStatus` |
| `verifyBadge(scannedSecret)` | Calls `apiService.verifyBadge(scannedSecret, token: _pendingToken.toString())`. On success: persists pending token+userData, sets `_isAuthenticated=true`, clears all pending state |
| `cancelBadgeScan()` | Clears `_pendingBadge`, `_pendingToken`, `_pendingUserData`, `_pendingUserId`, `_errorMessage` |
| `getBadgeSecret(targetUserId)` | Delegates to `apiService.getBadgeSecret` |
| `regenerateBadge(targetUserId)` | Delegates to `apiService.regenerateBadge`; manages `_isLoading` around the call |
| `get profileImageBytes` | Decodes `_userData?['imageBase64']` from base64 → `Uint8List?`; returns null on empty string or decode error |
| `get needsPasswordChange` | `_userData?['needToChangePw'] ?? false` |
| `get role` | `_userData?['role']?.toString() ?? 'Operator'` |
| `get isCheckingAuth` | exposes `_isCheckingAuth` |
| `get pendingBadge` | exposes `_pendingBadge` |

---

### Admin Domain

#### `lib/domain/admin/providers/erp_employee_provider.dart` — `ErpEmployeeProvider`
- `List<ErpEmployee> employees`
- `fetchEmployees()` → `runAsync` → `_service.fetchEmployees()`

#### `lib/domain/admin/providers/erp_workCenter_provider.dart` — `ErpWorkcenterProvider`
- `List<ErpWorkCenter> workCenters`
- `fetchWorkCenters()` → `runAsync` → `_service.fetchWorkCenters()`

#### `lib/domain/admin/providers/mes_log_provider.dart` — `LogProvider`
- `List<ActivityLogModel> activityLogs`, `List<MachineDashboardModel> machineDashboardList`
- `int selectedHours = 24`, `List<int> hourOptions = [1, 24, 48, 168, 720]`
- `fetchActivityLog()` → `runAsync` → `_service.fetchActivityLog(selectedHours)`
- `fetchMachineDashboard([List<String>? workCenterList])` → `runAsync` → `_service.fetchMachineDashboard(selectedHours, list ?? [])`
- `setHours(int)` → updates `selectedHours`, notifies
- `labelFor(h)` → human-readable string: 1→'Last 1 Hour', 24→'Last 24h', 48→'Last 48h', 168→'Last 7 Days', 720→'Last 30 Days'
- `setAuthProvider(AuthProvider auth)` → stores reference to `_authProvider` (currently unused in fetch calls)

#### `lib/domain/admin/providers/mes_settings_provider.dart` — `MesSettingsProvider`
- `SettingModel? settings`, `bool isSaving`, `String? saveError`, `bool saveSuccess`
- Internal `StreamController<void> _refreshController` (broadcast); `triggerRefresh()` adds event
- `fetchSettings()` → `runAsync` → `_service.fetchSettings()`, calls `notifyListeners()` after
- `updateSettings(newPeriod, {newTwoFAEnabled})` → manages `isSaving` flag; creates `SettingModel.copyWith(...)`, calls `_service.updateSettings`, updates local `settings` and sets `saveSuccess=true` on success; sets `saveError` on exception; returns `bool`

#### `lib/domain/admin/providers/mes_user_provider.dart` — `MesUserProvider`
- `List<MesUser> users`
- Internal `StreamController<void> _refreshController` (broadcast)
- `triggerRefresh()` → adds event to stream
- `fetchUsersByWc(wcId)` → `runAsync` → `_service.fetchMESUsersByWC(wcId: wcId)`; stores result in `users`
- `fetchMesUsers()` → returns `_service.streamFetchAllMESUsers(trigger: _refreshController.stream)` as `Stream<List<MesUser>>`
- `addUser(employeeId, roleInt, workCenterList)` → `runAsync` → `_service.createMesUser` → on `result == true` calls `triggerRefresh()`; returns `result ?? false`
- `changeUserRole(targetUserId, newRoleInt, workCenterList)` → `runAsync` → fetches token (unused in actual call), calls `_service.changeUserRole` → on success calls `triggerRefresh()`; returns `result ?? false`

---

### AI Domain

#### `lib/domain/ai/providers/ai_chat_provider.dart` — `AiChatProvider`
- `List<ConversationTurn> _history` (private), `bool isLoading`, `String? errorMessage`, `AiChatResponse? lastResponse`
- `get history` → `List.unmodifiable(_history)`
- `sendMessage(message)`:
  1. Sets `isLoading=true`, clears `errorMessage`, notifies
  2. Appends user turn to `_history`
  3. Calls `_service.sendMessage(message, history: _history.sublist(0, length-1))` (excludes the just-added user turn)
  4. On success: appends assistant turn, stores `lastResponse`, sets `isLoading=false`
  5. On error: removes last user turn (the failed message), sets `errorMessage`, sets `isLoading=false`
- `injectDebugResponse(userMessage, response)`: appends both user and assistant turns directly; used by debug panel
- `clearHistory()` → clears `_history`, `lastResponse`, `errorMessage`, notifies

---

### Machine Domain

#### `lib/domain/machines/providers/mes_machines_provider.dart` — `MesMachinesProvider`
- Plain Provider (no ChangeNotifier, not registered as ChangeNotifierProvider)
- `streamOrderedMachinePerDepartments(workCenterList)` → delegates to `_service.streamFetchOrderedMachinePerDepartments`

#### `lib/domain/machines/providers/mes_componentConsumption_provider.dart` — `MesComponentconsumptionProvider`
- Plain class (no ChangeNotifier, registered as plain `Provider`)
- Internal `StreamController<void> _refreshController` (broadcast)
- `triggerRefresh()` → adds event
- `dispose()` → closes `_refreshController`; note: does not call `super.dispose()` since not extending ChangeNotifier
- `getBomStream(prodOrderNo, operationNo)` → delegates to `_service.streamBom(..., _refreshController.stream)`

#### `lib/domain/machines/providers/machineOrders_provider.dart` — `MachineordersProvider`
- `List<MachineOrderModel> machineOrders`
- Internal `StreamController<void> _refreshController` (broadcast)
- `triggerRefresh()` → adds event

| Method | Delegates to | Post-action |
|---|---|---|
| `getMachineOrders(machineNo)` | `_service.getMachineOrders` | none |
| `startOrder(prodOrderNo, operationNo, machineNo)` | `_service.startOperation` | none |
| `finishOperation(...)` | `_service.finishOperation` | `triggerRefresh()` |
| `cancelOperation(...)` | `_service.cancelOperation` | `triggerRefresh()` |
| `pauseOperation(...)` | `_service.pauseOperation` | `triggerRefresh()` |
| `resumeOperation(...)` | `_service.resumeOperation` | `triggerRefresh()` |
| `declareProduction(prodOrderNo, operationNo, machineNo, input, onBehalfOfUserId)` | `_service.declareProduction` | `triggerRefresh()` |
| `getMachineOngoingOperationsStateStream(machineNo)` | `_service.streamMachinesOngoingOperationsState(machineNo, trigger: _refreshController.stream)` | — |
| `fetchMachineHistory(machineNo)` | `_service.fetchOperationsHistory(machineNo)` | — |
| `fetchOperationLiveDataStream(machineNo, prodOrderNo, operationNo)` | `_service.streamFetchOperationLiveData(..., _refreshController.stream)` | — |
| `fetchProductionCyclesStream(machineNo, prodOrderNo, operationNo)` | `_service.streamProductionCycles(..., _refreshController.stream)` | — |

#### `lib/domain/machines/providers/mes_scrap_provider.dart` — `MesScrapProvider`
- `List<MesScrapCode> scrapCodes`
- `fetchScrapCodes()` → early return guard: `if (scrapCodes.isNotEmpty) return` (cache); else `runAsync` → `_service.fetchScrapCodes()`
- `declareScrap(executionId, scrapCode, quantity, description, materialId, onBehalfOfUserId)` → `runAsync` → `_service.declareScrap`; returns `result ?? false`

#### `lib/domain/machines/barCode/provider/mes_barCode_provider.dart` — `MesBarcodeProvider`
- `List<ItemBarcodeModel> barcodes`, `bool isLoading`, `String? errorMessage`
- `fetchAllBarcodes()` → direct try/catch (not `runAsync`): sets `isLoading`, calls `_service.fetchAllBarcodes()`
- `insertScans(executionId, scans)` → resolves token from `_sessionStorage` (token passed to service internally via service's own `_sessionStorage`); calls `_service.insertScans(executionId, scans)`; uses try/catch with finally to manage `isLoading`; returns `bool`
- `resolveBarcode(barcode)` → calls `_service.resolveBarcode(barcode)`, sets `errorMessage` on exception, returns `Map?`

---

## Presentation Layer

### Auth Pages

#### `lib/presentation/auth/paring/paringPage.dart` — `ParingPage`
- Controller: `companyHostController`
- `onSubmit()`: validates form → `await AppConstants.changeHost(text)` → `Navigator.pushReplacement` to `LoginPage`
- Layout dispatch: width < 600 → `ParingMobileLayout`, < 1024 → `ParingTabletLayout`, else → `ParingWebLayout`
- Loading overlay rendered when `auth.isLoading` (reads from `AuthProvider`)

#### `lib/presentation/auth/paring/widgets/paring_form.dart` — `ParingForm`
- Validates host URL: not empty, no spaces, no backslash, no chars matching `[<>"\[\]{}|^`]`
- "Or Scan QR Code" button → `await showDialog` with `QrScannerDialog`; populates controller on non-null result
- Language selector (compact version, top-right)

#### `lib/presentation/auth/paring/widgets/scanner_dialog.dart` — `QrScannerDialog`
- `MobileScanner` inside 300×300 `Dialog`, `ClipRRect` with radius 20
- Targeting frame overlay: 180×180 white border
- On barcode detected: `Navigator.pop(context, value)`

#### `lib/presentation/auth/Login/loginPage.dart` — `LoginPage`
- Controllers: `authIdController`, `passwordController`
- `login()`:
  1. Validates form
  2. Generates `deviceId = 'flutter-device-${millisecondsSinceEpoch}'`
  3. Calls `authProvider.login(userId, password)`
  4. On fail: shows AlertDialog with errorMessage
  5. On success + `pendingBadge==true`: opens `BadgeScanDialog` (barrierDismissible=false)
  6. On success without 2FA: `_AuthGate` handles routing automatically
- Layout dispatch: same width breakpoints

#### `lib/presentation/auth/Login/widgets/login_shared_form.dart` — `LoginSharedForm`
- Fields: authId, password (obscurable toggle)
- "Change Host ID" button → `Navigator.pushReplacement` to `ParingPage`
- Language selector

#### `lib/presentation/auth/Login/widgets/badgeScanDialog.dart` — `BadgeScanDialog`
- State: `_verifying (bool)`, `_showManual (bool)`, `_scannerActive (bool, starts true)`
- `_verify(scannedValue)`: trims value, sets `_verifying=true`, `_scannerActive=false`; calls `auth.verifyBadge(trimmed)`; on success pops with `true`; on fail: sets `_verifying=false`, `_scannerActive=true` (re-enables scanner)
- `_cancel()`: calls `auth.cancelBadgeScan()`, pops with `false`
- Scanner viewport: 220h, overlaid targeting frame (160×160 white border), `CircularProgressIndicator` shown when `!_scannerActive`
- Error display: red container with `auth.errorMessage` (watches `AuthProvider` via `context.watch`)
- Manual entry toggle: shows TextField (`_manualCtrl`) + "Verify" submit button

#### `lib/presentation/auth/ChangePassword/changePassPage.dart` — `ChangePasswordPage`
- Controllers: `oldPasswordController`, `newPasswordController`, `confirmPasswordController`
- `onChangePassword()`:
  1. Validates form
  2. Checks `newPassword == confirmPassword` (shows AlertDialog with `'passwordsDoNotMatch'` if not)
  3. Calls `authProvider.changePassword(old, new)`
  4. Shows success or error AlertDialog; success dialog note: navigation handled by `_AuthGate` since `needsPasswordChange` becomes false

---

### Admin Pages

#### `lib/presentation/admin/adminPage.dart` — `AdminPage`
- Sidebar width 250, bg `0xFF0F172A`, box shadow
- `_selectedIndex` drives `IndexedStack` with 4 children:
  - 0: `AddUserPage` (receives 4 `GlobalKey`s)
  - 1: `ActivityLogPage`
  - 2: `BarcodeListPage`
  - 3: `MesSettingsPage`
- 4 `SidebarItem` widgets: usersRoles (0), activityLogs (1), barcodes (2), settings (3)
- Bottom section: user avatar (`auth.profileImageBytes`) + fullName + userId → taps to `ProfilePage`; wrapped in `GestureDetector`

#### `lib/presentation/admin/activity_log/activityLogPage.dart` — `ActivityLogPage`
- `initState` → `addPostFrameCallback` → `LogProvider.fetchActivityLog()`
- Filter state: `selectedType` (from list `['All','Status','Productions','Scraps','Scans']`), `searchController`
- Pagination: `_pageSize=15`, `_currentPage`
- Filter logic: `typeMatch = selectedType=='All' || log.type == log.mapType(selectedType)`; `searchMatch` checks operatorName, machineNo, action, timestamp
- Table columns (widths via `Expanded`): icon(32px) | operator(2) | declaredBy(2) | machine(2) | order(2) | operationNo(2) | action(3) | time(2)
- Error/empty state: cloud_off icon + `'FailedToFetchData'`
- Hour range dropdown in AppBar → `provider.setHours()` + `fetchActivityLog()` + resets `_currentPage`

#### `lib/presentation/machine/machineDashBoard/machineDashboardPage.dart` — `MachineDashboardPage`
- `initState` → reads `workCenters` from `SessionStorage` directly, calls `LogProvider.fetchMachineDashboard(workCenters)`
- Filter: search on `machineName`, `workCenterNo`
- Grid layout via `_GridBreakpoint` list:

| maxWidth | crossCount | aspectRatio | isSmallPhone |
|---|---|---|---|
| 450 | 1 | 1.4 | true |
| 700 | 1 | 2.0 | false |
| 1000 | 2 | 1.6 | false |
| 1300 | 2 | 2.0 | false |
| ∞ | 3 | 1.8 | false |

- Hour range dropdown same as activity log

#### `lib/presentation/admin/settings/settingsPage.dart` — `MesSettingsPage`
- `initState` → fetches settings, populates `_periodController.text`, `_twoFAEnabled`, `_savedPeriod`, `_savedTwoFA`, resets `_isDirty`
- Local state: `_periodController (TextEditingController)`, `_twoFAEnabled (bool)`, `_isDirty (ValueNotifier<bool>)`
- `_checkDirty()`: `_isDirty.value = (controller.text.trim() != _savedPeriod.trim() || _twoFAEnabled != _savedTwoFA)`
- Bottom action bar: `AnimatedSize`-wrapped, appears when `isDirty=true`; shows Discard (`OutlinedButton`) + Save (`FilledButton`) 
- `_save()`: calls `provider.updateSettings(period, newTwoFAEnabled: _twoFAEnabled)`, shows green or red SnackBar
- `_discard()`: resets controller text to `_savedPeriod` and `_twoFAEnabled` to `_savedTwoFA`, sets `_isDirty=false`
- Validator: period must be non-empty digits, 0–3650

---

### Add User Page & Widgets

#### `lib/presentation/admin/AddUser/AddUserPage.dart` — `AddUserPage`
- Receives 4 `GlobalKey`s: `sidebarKey`, `addUserKey`, `tableKey`, `actionMenuKey`
- Streams users via `MesUserProvider.fetchMesUsers()` stored in `_usersStream` in `initState`
- Search with 200ms debounce (`Timer`), stored in `_searchQuery`
- Filter logic (`_filter`): role match (Pending maps to `isPendingSetup==true`), search on fullName + email
- `_openAddUserDialog()`: fetches employees + workcenters first, then shows `AddUserDialog`
- `_exportUsers(users)`: calls `ExportUserService.exportUsersToExcel(users)`, shows SnackBar; uses `_isExporting` flag
- Tutorial: `AdminDashboardTutorial.show` called once on first non-empty user list
- Pagination: `_pageSize=10`, `_currentPage`

#### `lib/presentation/admin/AddUser/widgets/add_user_dialog.dart` — `AddUserDialog`
- State: `selectedEmployeeIndex`, `selectedRoleIndex`, `selectedWorkCenterIndexes (List<int>)`, `selectedWorkCenterIds (List<String>)`, `selectedEmployeeId`, `selectedRole`, `errorMessage`
- Role index 0=Operator, 1=Supervisor, 2=Admin
- `isMultiSelect` = `selectedRoleIndex == 1`; `_showWorkCenters` = `selectedRoleIndex != 2`
- `workCenterSelection(index, id)`: toggles; if not multiSelect and already has one, clears before adding
- Submit validation: must select employee, role, and (if not Admin) at least one WC
- Calls `MesUserProvider.addUser(employeeId: selectedEmployeeId!, roleInt: selectedRoleIndex!, workCenterList: selectedWorkCenterIds)`

#### `lib/presentation/admin/AddUser/widgets/change_role_dialog.dart` — `ChangeRoleDialog`
- Pre-selects current user role via `_capitalize(widget.user.role).clamp(0,2)` index lookup in `_roles` list
- `_roles`: const list of `_RoleMeta` — Operator(0, blue), Supervisor(1, green), Admin(2, purple)
- `isMultiSelect` = `_selectedRole == 'Supervisor'`; `_showWorkCenters` = `_selectedRole != 'Admin'`
- `_toggleWorkCenter`: same logic as `AddUserDialog.workCenterSelection`
- Submit calls `MesUserProvider.changeUserRole(targetUserId, newRoleInt: _selectedRoleIndex, workCenterList: _showWorkCenters ? _selectedWcIds : [])`
- Pops with `true` on success

#### `lib/presentation/admin/AddUser/widgets/generate_password_dialog.dart` — `GeneratePasswordDialog`
- `static generatePassword()`: generates 10-char password; character sets: upperChars (no M,P,W,L), lowerChars (no m,p,w,l), digits, special `!@#$%`; guarantees one of each type, fills to 10 with allChars, shuffles with `Random.secure()`
- `_confirmPassword()`: calls `AuthProvider.adminSetPassword(userId, password)`; on success shows result dialog with copyable `'Auth ID: ...\nPassword: ...'` string via `SelectableText` + `IconButton` copy; on fail shows error dialog

#### `lib/presentation/admin/AddUser/widgets/user_badge_dialog.dart` — `UserBadgeDialog`
- `initState` → `_fetchSecret()` → `AuthProvider.getBadgeSecret(widget.user.userId)`
- QR rendered via `BarcodeWidget(barcode: Barcode.qrCode(errorCorrectLevel: medium), data: _badgeSecret!, 200×200)`
- `_exportPdf()`: renders QR to `Uint8List` via `ui.PictureRecorder` + canvas (draws `BarcodeBar` elements), generates A4 PDF, opens print dialog via `Printing.layoutPdf`
- `_regenerate()`: shows confirm dialog first; calls `AuthProvider.regenerateBadge(userId)`, updates `_badgeSecret` on success

#### `lib/presentation/admin/AddUser/widgets/user_action_menu.dart` — `UserActionMenu`
- `isCurrentUser` flag: when true, menu shows only `viewBadge`; otherwise shows full menu
- Full menu items: editRoleDepartement, generatePassword (only if `user.isActive`), viewBadge (only if `user.isActive`), deactivate (if active) or activate (if inactive)
- `activate`/`deactivate`: calls `AuthProvider.toggleUserActiveStatus` then `.then(() => MesUserProvider.triggerRefresh())`
- `_openChangeRoleDialog`: awaits `ErpWorkcenterProvider.fetchWorkCenters()` first
- `_openUserBadgeDialog`: also awaits `ErpWorkcenterProvider.fetchWorkCenters()` first (provider already fetched — no-op if cached)

#### `lib/presentation/admin/AddUser/widgets/user_list_row.dart` — `UserListRow`
- Columns: avatar+name+email(flex3) | role badge(flex2) | WC text(flex2) | online badge(flex2) | lastSeen(flex2) | actions(60px)
- Inactive rows: `Opacity(0.5)` wraps all content; role/badge colors use muted grey
- Pending rows: amber left-border (3px `0xFFD39D2B`), `_PendingBadge` inline after name; left padding is `13` (vs 16 normal) to compensate for border width
- `_PendingBadge`: amber-colored, lock_clock icon + `'Pending Setup'` text
- Role colors: Admin→`0xFF7C3AED`, Supervisor→`0xFF2563EB`, Operator→`0xFF16A34A`; inactive→grey `0xFF64748B`

#### `lib/presentation/admin/AddUser/widgets/user_list_table.dart` — `UserListTable`
- Renders `TableHeader` + `ListView.separated` of `UserListRow` keyed by `ValueKey(user.userId)`
- Pagination at bottom when `totalPages > 1`
- `RepaintBoundary` on the `ListView`

#### `lib/presentation/admin/AddUser/widgets/table_header.dart` — `TableHeader`
- Fixed header: User(flex3) | Role(flex2) | Department(flex2) | Status(flex2) | LastActive(flex2) | Actions(60px)
- Uses `'tableHeader*'.tr()` keys; `0xFFF8FAFC` bg, bottom border `Colors.grey.shade200`

#### `lib/presentation/admin/AddUser/widgets/stat_card.dart` — `Stats`
- Row of 4 `_StatCard` widgets: totalUsers, active count (`isActive==true`), pending count (`isPendingSetup==true`), `roles.length - 2`

#### `lib/presentation/admin/AddUser/widgets/button.dart` — `Buttons`
- `MouseRegion` + `AnimatedContainer` (120ms) hover button
- primary=blue (`0xFF2563EB`) fill/white text; secondary=white fill/dark text with grey border
- `isLoading` shows 12×12 spinner; `onTap` is null when loading; width fixed at 170

---

### Machine Pages

#### `lib/presentation/machine/machineList/machineListPage.dart` — `Machinelistpage`

**State:**
- `searchQuery`, `statusFilter`, `dataNotifier`, `loadingNotifier`, `chatOpen` — all `ValueNotifier`
- `_subscription (StreamSubscription?)` — active machine list stream subscription
- Implements `RouteAware`

**Stream lifecycle:**
- `initState` → `_startStream()` if `_workCenterIds` non-empty
- `_startStream()`: guard `if (_subscription != null) return`; subscribes to `MesMachinesProvider.streamOrderedMachinePerDepartments`, populates `dataNotifier`, sets `loadingNotifier=false`
- `_stopStream()`: cancels and nulls `_subscription`
- `didChangeDependencies()`: subscribes/re-subscribes `routeObserver`
- `didPushNext()` → `_stopStream()`
- `didPopNext()` → `_startStream()` if `_workCenterIds` non-empty
- `dispose()` → unsubscribes routeObserver, `_stopStream()`, disposes all notifiers and controller

**Filter logic (`_applyFilters`):** per entry: filters by query (machineName, workCenterName case-insensitive) and status (`machine.status.toLowerCase() == status.toLowerCase()`); removes groups that become empty

**Chat behavior:**
- Width ≥ 600: sets `chatOpen.value=true` → renders `AiChatPage(isDialog:false)` as `Positioned` overlay (right=0, width=400); on tablet (820 ≤ width ≤ 1032): bottom=0, height=80% screen; else: full height (top=0 to bottom=0)
- Width < 600: `showDialog` with `AiChatPage(isDialog:true)`
- FAB hidden when `isChatOpen && isWide`

**Grid layout:** `mainAxisExtent=170` for all screen sizes; crossAxisCount: 1 (<700), 2 (<1300), 4 (≥1300)

**Status legend badges** in AppBar area: working (green `0x28C55C`) and idle (grey)

**Tutorial:** `MachineListTutorial.show` called once on first non-empty data

#### `lib/presentation/machine/machineList/widgets/machine_card.dart` — `MachineCard`
- `LayoutBuilder`-responsive: isLarge = maxWidth > 600
- Hover state: `MouseRegion` + `AnimatedContainer` (180ms) — shadow intensifies, slight border appears
- Left border 5px colored by status; `ClipRRect` on inner content
- Status: `status.toLowerCase() != 'working'` → idle
- Shows: machineName, status badge (100–120px wide), currentOrder, operationNo, itemNo, itemDescription (all `'-'` when idle)
- Tap → `Navigator.push` to `MachineMainPage(machineNo, machineName)`

#### `lib/presentation/machine/machine_details/tabsMain.dart` — `MachineMainPage`
- `initialTabIndex` clamped to [0,2]
- Tab 0: `Machineorderpage`; Tab 1: `OrdersProgressionPage`; Tab 2: `MachineHistoryPage`
- `_handleStartOrderSuccess()`: sets `selectedIndex=1`, calls `getMachineOrders` in next frame
- Tutorial: `MachineDetailTabsTutorial.show` called once via `addPostFrameCallback`

#### `lib/presentation/machine/machine_details/machines_orders/machineOrderPage.dart` — `Machineorderpage`
- `initState` → `MachineordersProvider.getMachineOrders(machineNo)` in `addPostFrameCallback`
- Filter: `selectedStatus` dropdown (all/Planned/Firm Planned/Released); search uses `Utils.formatSearchableDate` for date fields
- Sort: Released(0) > Firm Planned(1) > Planned(2) > other(3); tie-break by `plannedStart` date-only (strips time) ascending/descending
- Opacity 0.75 for non-Released orders

#### `lib/presentation/machine/machine_details/machines_orders/widgets/action_buttons.dart` — `ActionButtons`
- `_canStart`: `order.status == 'Released'`
- `_isSupervisor`: `SessionStorage().getRole().toLowerCase() == 'supervisor'`
- `_canClose`: `order.status == 'Released' && _isSupervisor`
- `_handleStart()`: calls `MachineordersProvider.startOrder` → on success calls `onSwitchToProgress?.()`; shows error dialog on exception
- `_handleClose()`: shows confirm dialog (red "Yes Cancel Order" button), calls `cancelOperation`, reloads orders; shows SnackBar on success
- Close button disabled (opacity/IgnorePointer) in wide layout when not applicable; has `Tooltip` with `'onlySupervisorsCanCloseOrders'` when not supervisor

#### `lib/presentation/machine/machine_details/machine_production/ordersProgressionPage.dart` — `OrdersProgressionPage`
- Tab optimization: checks `ModalRoute.of(context)?.isCurrent` — renders `SizedBox()` if not current tab
- Stream: `MachineordersProvider.getMachineOngoingOperationsStateStream`
- Sort: Running(0) first, then by `declaredAt` descending
- `_handleToggle`: calls pause or resume based on `operationStatus.trim().toLowerCase() == 'running'`

#### `lib/presentation/machine/machine_details/machine_history/machineHistoryPage.dart` — `MachineHistoryPage`
- `initState` → stores future `_historyFuture = MachineordersProvider.fetchMachineHistory(machineNo)` — one-time fetch
- Search across `prodOrderNo`, `itemDescription`, `startDateTime`
- Sort by `startDateTime` string comparison ascending/descending
- Tap on `HistoryCard` → navigates to `OperationDetailPage`

#### `lib/presentation/machine/machine_details/operation_detail/operationDetailPage.dart` — `OperationDetailPage`
- **Outer** `StreamBuilder`: `fetchOperationLiveDataStream` → `liveData`
- **Merged** object: static fields from `operationData` (prodOrderNo, machineNo, operationNo, itemNo, itemDescription, operationDescription, orderQuantity, startDateTime); live fields (endDateTime, declaredAt, operationStatus, totalProducedQuantity, scrapQuantity, progressPercent); `executionId` = `liveData?.executionId ?? ""`
- **Middle** `StreamBuilder`: `fetchProductionCyclesStream` → `cycles`
- **Inner** `StreamBuilder`: `componentProvider.getBomStream` → `components`
- `LayoutBuilder`: width < 1210 → `MobileTabletLayout`, else → `PcLayout`

#### `lib/presentation/machine/machine_details/operation_detail/widgets/action_Buttons_Container.dart` — `ActionButtonsContainer`
- `_operationStatus`: `operationData.operationStatus.trim().toLowerCase()`
- `_isClosed`: in `['finished', 'cancelled', 'interrupted']`
- `_canDeclareProduction`: not in `['finished','cancelled','paused','interrupted']`
- `_canReportReject`: not in `['finished','cancelled','paused','interrupted']`
- `_canCloseOrder`: `!_isClosed && _isSupervisor`
- `_canPrintLabel`: `operationStatus == 'finished' || progressPercent >= 100`
- `_isComplete`: `progressPercent >= 100`
- "Declare Production": opens `DeclareProductionDialog`; on non-null positive `declaredQty` return → navigates to `DeclarationLabelPage(operationData, quantity: declaredQty.toInt())`
- "Report Reject": opens `DeclareScrapDialog`
- "Finish/Cancel Order": confirm dialog (finish if complete, cancel/interrupt otherwise), calls `finishOperation` or `cancelOperation`, pops on success
- "Print Label": navigates to `PrintLabelPage`
- Disabled tooltip: `'onlySupervisorsCanFinishOrders'` (when complete) or `'onlySupervisorsCanInterruptOrders'` (when not complete)

#### `lib/presentation/machine/machine_details/operation_detail/widgets/declaire_production_dialog.dart` — `DeclareProductionDialog`
- `_remaining = operationData.orderQuantity - operationData.totalProducedQuantity`
- Component availability check per component: `consumed = totalProduced * quantityPerUnit`, `scrap = component.scrapQuantity + component.quantityPerUnit * operationData.scrapQuantity`, `remaining = component.totalQuantityScanned - consumed - scrap`; if `remaining < declaredQty * component.quantityPerUnit` → error `'insufficientComponentQuantity'`; check runs before API call
- Supervisor: renders `OperatorSelector` (keyed by `workCenterIds.join(',')`) for `_onBehalfOfUserId`
- Submit: calls `MachineordersProvider.declareProduction`, pops with `declaredQty` on success

#### `lib/presentation/machine/machine_details/operation_detail/widgets/declare_scrap_dialog.dart` — `DeclareScrapDialog`
- Types list: `['Material', 'FinishedProduct']`
- `initState` → `MesScrapProvider.fetchScrapCodes()` in `addPostFrameCallback`
- For Material type: shows component `DropdownMenu` (`enableFilter: true`, menuHeight 180); requires `selectedComponent != null`
- Material availability check: `consumed = totalProduced * quantityPerUnit`, `remaining = scanned - consumed - scrapQuantity`; error if `remaining < declaredQty`
- Finished product check: same per-component loop as `DeclareProductionDialog` (includes `outputScrapQuantity` in scrap)
- Submit: calls `MesScrapProvider.declareScrap(..., materialId: currentOption==scrapTypes[0] ? component.itemNo : '')`, on success triggers both `MesComponentconsumptionProvider.triggerRefresh()` and `MachineordersProvider.triggerRefresh()`
- Supervisor: renders `OperatorSelector`

#### `lib/presentation/machine/machine_details/operation_detail/widgets/operator_selector.dart` — `OperatorSelector`
- `initState` → `_loadOperators()`: iterates `workCenterIds`, calls `MesUserProvider.fetchUsersByWc(wcId: wcId)` for each, collects `role == 'Operator'` users into `Map<String,MesUser>` (deduplication by userId)
- Renders `DropdownMenu<MesUser?>` with first entry `null` = `'selfDeclaration'`; other entries have `EmployeeAvatar` as `leadingIcon`
- Calls `onOperatorSelected(user?.userId)` on selection

#### `lib/presentation/machine/machine_details/operation_detail/widgets/scanner_dialog.dart` — `ScannerWidget`
- State: `List<ItemBarcodeModel> items`, `isScanning (starts true)`, `isSubmitting`, `errorMessage`
- `isItemInComponents(itemNo)`: `widget.components.any(c => c.itemNo == itemNo)`
- `canAddMoreItem(item)`:
  1. Item must be in components
  2. `item.quantityPerUnit >= component.baseUOMQuantityPerUnit` (blocks smaller UOM barcodes)
  3. `totalIfAdded <= component.inventory`
- `addItem(item)`: validates (component membership → UOM → inventory); on success: increments if `itemNo+unitOfMeasure` match found, else appends; clears `errorMessage` on success
- On barcode detection: `isScanning=false` immediately; calls `MesBarcodeProvider.resolveBarcode(value)`; builds `ItemBarcodeModel` from response; camera stays stopped until "Scan Again"
- Display: shows `quantity unitOfMeasure = totalScanned pcs out of outOf` per item
- `outOf` map pre-computed in `RequiredComponent._openScanner`: `(orderRemainingQte * quantityPerUnit - remaining).clamp(0, ∞)`
- Submit: calls `MesBarcodeProvider.insertScans(executionId, items.map(toJson).toList())`; on success triggers `MesComponentconsumptionProvider.triggerRefresh()`, pops

#### `lib/presentation/machine/machine_details/operation_detail/widgets/required_componment.dart` — `RequiredComponent`
- `canScan = operationStatus == "Running"` (exact string match)
- Filter by search (itemDescription) and dropdown (all/missing/low)
- `ComponentListView` status logic:
  - `consumed = totalProduced * quantityPerUnit`
  - `scrap = component.scrapQuantity + component.quantityPerUnit * outputScrapQuantity`
  - `remaining = totalQuantityScanned - consumed - scrap`
  - `requiredForOrder = (orderQuantity - totalProduced) * quantityPerUnit`
  - `'missing'`: `scanned == 0 || remaining < quantityPerUnit`
  - `'lowStock'`: `remaining < requiredForOrder`
  - `'available'`: otherwise
- Expand button (wide ≥1210 screens only): opens 900×650 Dialog with full `ComponentListView`
- "Scan Item" button disabled if `!canScan || !hasComponents`

#### `lib/presentation/machine/machine_details/operation_detail/widgets/production_chart.dart` — `ProductionChart`
- Filters `cycleQuantity > 0`, reverses (oldest first for x-axis)
- `fl_chart` `LineChart`; `interval = max(1, floor(highestValue/10))`; `maxY = ceil(highestValue*1.2/interval)*interval`; `minY = floor(lowestValue*0.8/interval)*interval`
- Tooltip shows: fullName, declared qty, totalProduced, fullLabel
- `horizontalScrollable`: chart width = `max(maxWidth, cycles.length/perScreenDataPoints * maxWidth)`; auto-scrolls to end on init and on widget updates via `addPostFrameCallback`

#### `lib/presentation/machine/machine_details/operation_detail/widgets/production_cycle.dart` — `ProductionCycle`
- Filters `totalProducedQuantity > 0`; paginated by `perPage`
- `safeCurrentPage = currentPage >= totalPages ? totalPages-1 : currentPage` (clamp on render)
- `horizontalScrollable=true`: fixed-width `TableCellWidget` columns (operator=180, others=100px); `SingleChildScrollView(Axis.horizontal)`
- `horizontalScrollable=false`: `Expanded` flex columns (operator flex2, others flex1); columns: operator, cycleQty, produced, time (scrap column removed from normal view)

#### `lib/presentation/machine/machine_details/machine_production/models/status_style.dart` — `OperationStatusStyle`
- Fields: `badgeBg`, `badgeBorder`, `badgeText`, `progressColor`, `leftRail`, `label (localized)`
- `operationStatusStyleFromStatus(status)` mapping:

| Status | Badge bg | Badge text | Progress/rail |
|---|---|---|---|
| Running | `0xFFECFDF5` | `0xFF065F46` | `0xFF22C55E` |
| Cancelled | `0xFFFDECEC` | `0xFF5F0606` | `0xFFC52222` |
| Paused | `0xFFFFFBEB` | `0xFF92400E` | `0xFFF59E0B` |
| Interrupted | `0xFFFFFBEB` | `0xFF92400E` | `0xFFF59E0B` |
| Finished | `0xFFEFF6FF` | `0xFF1E40AF` | `0xFF3B82F6` |
| Idle/default | `0xFFF3F4F6` | `0xFF6B7280` | `0xFF9CA3AF` |

#### `lib/presentation/machine/machine_details/machines_orders/models/badge_style.dart` — `BadgeStyle`
- Fields: `bg`, `border`, `text`, `label (localized)`
- `badgeStyleFromStatus(status)` mapping:

| Status | bg | text |
|---|---|---|
| Firm Planned | `0xFFF3F0FF` | `0xFF5B21B6` |
| Planned | `0xFFF3F4F6` | `0xFF6B7280` |
| Finished | `0xFFEFF6FF` | `0xFF1D4ED8` |
| Cancelled | `0xFFFFD1D1` | `0xFFFF0000` |
| Interrupted | `0xFFFFFBEB` | `0xFF92400E` |
| Released/default | `0xFFECFDF5` | `0xFF065F46` |

#### `lib/presentation/machine/machine_details/shared/utils.dart` — `Utils`
- `formatTimestamp(String? raw)`: parses ISO datetime, formats as `'DD Mon YYYY HH:mm'` (e.g. `'01 Jan 2025 09:30'`); returns `'–'` on null/empty/parse error
- `formatSearchableDate(dynamic dt)`: parses datetime, returns space-joined string of `'DD Mon YYYY'`, `'DD/MM/YYYY'`, `'DD-MM-YYYY'` for broad search matching

---

### Barcode Pages

#### `lib/presentation/admin/barCode/barCodeListPage.dart` — `BarcodeListPage`
- `initState` → `addPostFrameCallback` → `MesBarcodeProvider.fetchAllBarcodes()`
- `GridView`: crossAxisCount 2, `childAspectRatio: 1.9`, padding 8
- Pagination: `_pageSize=10`, `_currentPage`; resets to 0 on search change
- `_printSingleBarcode`: renders DataMatrix to PNG via `ui.PictureRecorder` + canvas + `BarcodeBar` drawing, A4 PDF with centered 300×300 image, `Printing.layoutPdf`
- Refresh `IconButton` in AppBar
- Shows `Consumer<MesBarcodeProvider>` for state checks (loading, empty, error)

#### `lib/presentation/admin/barCode/widgets/dataMatrix_card.dart` — `DataMatrixCard`
- `MouseRegion` + `GestureDetector` for hover (`_isHovered`) and press (`_isPressed`) states
- `AnimatedContainer` (200ms): translates Y by -4 on hover
- `Card` elevation: 8 on hover, 2 normal; bg: grey.shade300 pressed, grey.shade100 hovered, white normal
- `BarcodeWidget(Barcode.dataMatrix(), 120×120)` + itemNo (bold) + description (`ExpandableText`) + `'clickToPrint'` hint

---

### Print Pages

#### `lib/presentation/machine/print_lables/printLabelPage.dart` — `PrintLabelPage`
- Barcode data: `'productOrder:X|machineNumber:X|itemNo:X|itemDescription:X|orderQuantity:X'`
- Landscape toggle (`Switch` in AppBar)
- `_print()`: `Barcode.dataMatrix().toSvg(_barcodeData, 120×120)`, A4 PDF via `pdf` package with `pw.SvgImage`, `Printing.layoutPdf`
- Preview (`_preview()`): portrait → stacked (title, barcode 120×120, info rows); landscape → side-by-side row (barcode 100×100, info column)
- `KeyedSubtree(key: ValueKey(_isLandscape))` forces preview rebuild on orientation change

#### `lib/presentation/machine/print_lables/printDeclarationLabelPage.dart` — `DeclarationLabelPage`
- Receives `quantity (int)` — number of label copies
- Barcode data: excludes `orderQuantity` field (vs `PrintLabelPage`)
- PDF: generates `quantity` pages, each labelled `'${i+1} / ${quantity}'` in a `'Label'` row
- Info banner: blue box showing `'${quantity} copies will be created'`
- Layout: phone → `SingleChildScrollView` column; desktop → `Row` with `VerticalDivider`

---

### AI Chat Page

#### `lib/presentation/ai/ai_chat_page.dart` — `AiChatPage`
- Props: `onClose (VoidCallback?)`, `isDialog (bool, default true)`
- `isDialog=true` → `Dialog` (maxWidth 800, maxHeight 800, radius 12); `isDialog=false` → `Container` with top-left and bottom-left rounded corners and shadow
- Debug panel enabled when `AppConstants.aiDebug == true`; toggle via bug_report icon; loads machines from `MesMachinesProvider`

**Role filtering:**
- `_currentRole = SessionStorage().getRole().trim().toLowerCase()`
- `_isSupervisor = _currentRole == 'supervisor'`
- `_filterActions(actions)`: removes `'redirect_machine_dashboard'` for non-supervisors

**`_handleAction(actionType)`:**
- `redirect_machine_list`: dismisses chat, `Navigator.popUntil(isFirst)`
- `redirect_machine_waiting_operations`: dismisses, pushes `MachineMainPage(initialTabIndex: 0)`
- `redirect_machine_ongoing_operations`: dismisses, pushes `MachineMainPage(initialTabIndex: 1)`
- `redirect_history`: dismisses, pushes `MachineMainPage(initialTabIndex: 2)`
- `redirect_machine_dashboard`: supervisor only; dismisses, pushes `MachineDashboardPage`; shows `'actionNotAllowed'` SnackBar for non-supervisors
- default: shows `'unknownAction'` SnackBar

**Navigation helpers:**
- `_navigateTo(page)`: if dialog pops it, else calls `onClose?.()`; then pushes page
- Missing machineNo → shows `'missingMachineNo'` SnackBar early return

**Message rendering:**
- User bubbles: black bg (`0xFF0F172A`), white text
- Assistant bubbles: `0xFFF1F5F9` bg, `MarkdownBody` with custom `MarkdownStyleSheet`; links opened via `url_launcher`
- Action buttons rendered only for the last assistant message (index == history.length-1), role-filtered

**Input bar:** `TextField` submits on Enter; `IconButton.filled` with `0xFF0F172A` bg

**`_handleClose()`:** pops if dialog; calls `onClose?.()` if panel

---

### Profile Page

#### `lib/presentation/profilePage.dart` — `ProfilePage`
- Shows avatar (`auth.profileImageBytes` or fallback `'https://picsum.photos/200/200'`), fullName, email from `SessionStorage`
- Language menu via `showMenu` at tap position (PopupMenuItems en/fr/ar → `context.setLocale`)
- `ProfileTile` widgets: changeLanguage (tap triggers menu), changePassword, logout
- Logout: sets `isLoggingOut=true` → `auth.logout()` → `Navigator.pushAndRemoveUntil` to `LoginPage`
- Responsive: `isPhone = size.width < 600` — symmetric padding 16 vs 70

---

### Widgets

#### `lib/presentation/widgets/searchBar.dart` — `GlobalSearchBar`
- Responsive: `isMobile = maxWidth < 600`
- Mobile: dropdown as `PopupMenuButton` with `Icons.tune` icon
- Desktop: dropdown as `DropdownButton` in bordered container (height 47)
- `onTapOutside` and `onSubmitted` call `FocusManager.instance.primaryFocus?.unfocus()`
- Optional sort button: shown when `sortAscending != null`

#### `lib/presentation/widgets/navBar.dart` — `TopNavigationBar`
- 3 `NavButton` items in `Row`: orders(0), progress(1), history(2) (all localized)
- Selected: bottom `BorderSide(black, width:2)`; unselected: no border
- Each `NavButton` is `Expanded`

#### `lib/presentation/widgets/employee_avatar.dart` — `EmployeeAvatar`
- `static Map<String,Uint8List> _cache` — module-level base64 decode cache, keyed by raw base64 string
- `_getImage()`: checks cache, decodes base64, stores in cache; returns null on null/empty/decode error
- Falls back to `Icons.person` icon (`radius` size, grey.shade400 color)
- `RepaintBoundary` wrapping

#### `lib/presentation/widgets/expandableText.dart` — `ExpandableText`
- `maxLines (default 1)`, tap toggles between truncated and full text
- `overflow: TextOverflow.visible` when expanded

#### `lib/presentation/widgets/language_selector.dart` — `LanguageSelector`
- Languages: `{'en':'English','fr':'Français','ar':'العربية'}`
- `isCompact=true`: `PopupMenuButton` showing `languageCode.toUpperCase()` + language icon; selected item shows `Icons.check` prefix
- `isCompact=false`: `DropdownButton` in bordered container
- `didChangeDependencies` syncs `_selectedLanguage` from `context.locale.languageCode`

---

### Tutorial System

All tutorials use `tutorial_coach_mark` package. Each checks `SharedPreferences` before showing; sets key `true` on finish or skip.

| Class | PrefsKey | Targets |
|---|---|---|
| `MachineListTutorial` | `tutorial_shown_user` | keys[0]=profile, keys[1]=search, keys[4]=machineCard (keys[2],[3] unused GlobalKeys) |
| `MachineDetailTabsTutorial` | `tutorial_shown_machine_detail_tabs` | navBarKey (ContentAlign.bottom) |
| `OperationDetailTutorial` | `tutorial_shown_operation` | keys[0]=currentOrderInfo (bottom), keys[1]=actionButtons (top) |
| `AdminDashboardTutorial` | `tutorial_shown_admin` | keys[0]=addUserButton (bottom), keys[1]=userTable (top), keys[2]=actionMenu (left) |

All tutorials: `paddingFocus: 6-8`, `opacityShadow: 0.9-0.95`, `textSkip: 'skip'.tr()`; `enableOverlayTab: true`, `enableTargetTab: true` (AdminDashboard only)

---

## Layout Architecture

Each auth page (`Login`, `ChangePassword`, `Paring`) dispatches to three layout widgets:
- < 600: Mobile layout
- < 1024: Tablet layout
- ≥ 1024: Web layout

Each renders the same shared form widget with different container sizes/decoration.

Machine card/operation/order views dispatch internally via `LayoutBuilder`:
- `OperationCard`, `OrderCard`, `HistoryCard`: narrow (< 600) or wide (≥ 600) layout sub-widgets
- `OperationDetailPage`: `MobileTabletLayout` (< 1210) or `PcLayout` (≥ 1210)

---

## Data Flow Summary

```
SessionStorage (SharedPreferences)
    ↕
AppConstants (host URL, devToken, aiDebug)
    ↕
HttpClient.post → HttpResponseParser
    ↕
Service classes (lib/data/*/services)
    ↕
Provider classes (lib/domain/*/providers) ← ChangeNotifier / StreamController
    ↕
Presentation widgets (context.read / context.watch / Consumer / StreamBuilder / ValueListenableBuilder)
```

**Refresh pattern:** Write operations call `triggerRefresh()` → adds event to broadcast `StreamController<void>` → event passed as `trigger` to service-level `async*` generators which re-fetch and yield new data.

**Stream pause pattern:** `MachinelistPage` uses `RouteAware` to cancel the machine stream on `didPushNext` and resume on `didPopNext`.

**2FA flow:** `login()` on `twoFAEnabled` holds token+userData in memory (`_pendingToken`, `_pendingUserData`); `BadgeScanDialog` calls `verifyBadge()`; only on success does `AuthProvider` persist to `SessionStorage` and set `_isAuthenticated=true`.

**Component scan submit shape** (`ItemBarcodeModel.toJson`): `{itemNo, barcode, quantityScanned, unitOfMeasure, quantityPerUnitOfMeasure}` — sent as array inside `scansJson: jsonEncode(scans)`.