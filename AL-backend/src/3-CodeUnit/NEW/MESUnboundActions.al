// =============================================================================
// Codeunit: MES Unbound Actions
// Object ID: 50125
// Purpose : Exposes all MES auth + admin operations as ODataV4 **unbound
//           actions** via a published Codeunit web service.
//
// MIGRATION NOTE
// ──────────────
// This codeunit replaces the former "MES Auth Actions" API page (50121) and
// its backing "MES Auth API" codeunit (50120).  Bound actions on an API page
// are convenient but couple routing to a SourceTable entity.  Unbound actions
// on a published codeunit are completely entity-agnostic, making them ideal
// for an auth service that must be callable without a prior record context.
//
// HOW TO CALL (ODataV4)
// ─────────────────────
//   POST  <baseUrl>/ODataV4/MESAuthEndpoints_Login
//   POST  <baseUrl>/ODataV4/MESAuthEndpoints_Logout
//   POST  <baseUrl>/ODataV4/MESAuthEndpoints_Me
//   POST  <baseUrl>/ODataV4/MESAuthEndpoints_ChangePassword
//   POST  <baseUrl>/ODataV4/MESAuthEndpoints_AdminCreateUser
//   POST  <baseUrl>/ODataV4/MESAuthEndpoints_AdminSetPassword
//   POST  <baseUrl>/ODataV4/MESAuthEndpoints_AdminSetActive
//
//   All endpoints:
//     - Accept JSON body   { "paramName": value, ... }
//     - Return JSON string { "success": true/false, ... }
//     - Use HTTP POST (ODataV4 actions are always POST)
//     - Require a company query param or header if multi-company:
//         ?company=<name>  -or-  Company-Id: <guid>
//
// PUBLISHING AS WEB SERVICE
// ──────────────────────────
//   1. Navigate to Web Services in Business Central.
//   2. New → Object Type = Codeunit, Object ID = 50125,
//      Service Name = MESAuthEndpoints, Published = true.
//   3. The ODataV4 URL column will NOT show a URL (this is expected for
//      codeunits), but the endpoint IS reachable at the path shown above.
//
// ERROR HANDLING PATTERN
// ───────────────────────
//   Every public procedure wraps its read/validation call in a [TryFunction].
//   All database writes (Insert, Modify, Delete) happen OUTSIDE TryFunctions.
//   On validation failure the [TryFunction] returns FALSE; the last error text
//   is captured, cleared, and embedded in a JSON error envelope.  This means
//   the HTTP response is always 200 OK with a JSON body — the caller must
//   inspect the "success" field to distinguish success from failure.
// =============================================================================
codeunit 50125 "MES Unbound Actions"
{
    // -------------------------------------------------------------------------
    // Dependencies
    // -------------------------------------------------------------------------
    var
        AuthMgt: Codeunit "MES Auth Mgt";  // business logic layer

    // =========================================================================
    // SECTION 1 – USER / AUTH ENDPOINTS
    // =========================================================================

    /// <summary>
    /// Authenticates a user and returns a session token.
    ///
    /// HTTP POST  .../ODataV4/MESAuthEndpoints_Login
    /// Body       { "userId": "...", "password": "...", "deviceId": "..." }
    /// Returns    { "success": true,  "token": "...", "expiresAt": "...",
    ///              "userId": "...",  "name": "...",  "role": "...",
    ///              "workCenterNo": "...", "needToChangePw": false }
    ///         or { "success": false, "error": "...", "message": "..." }
    ///
    /// NOTE: password parameter is [NonDebuggable] so it is never logged.
    /// </summary>
    [NonDebuggable]
    procedure Login(userId: Text; password: Text; deviceId: Text): Text
    var
        TokenRec: Record "MES Auth Token";
        U: Record "MES User";
        UserIdCode: Code[50];
        OutJ: JsonObject;
    begin
        if (userId = '') or (password = '') then
            exit(BuildError('Invalid request', 'Username and password are required'));

        UserIdCode := CopyStr(userId, 1, 50);

        // TryValidateCredentials is read-only — no writes inside the TryFunction.
        if not TryValidateCredentials(UserIdCode, password) then
            exit(BuildErrorFromLastError('Authentication failed'));

        // INSERT happens OUTSIDE the TryFunction.
        TokenRec := AuthMgt.IssueNewToken(UserIdCode, deviceId);

        if not U.Get(TokenRec."User Id") then
            exit(BuildError('Internal error', 'User data not found after login'));

        OutJ.Add('success', true);
        OutJ.Add('token', Format(TokenRec."Token"));
        OutJ.Add('expiresAt', Format(TokenRec."Expires At", 0, 9));
        OutJ.Add('userId', U."User Id");
        OutJ.Add('name', U."Auth ID");
        OutJ.Add('role', Format(U.Role));
        OutJ.Add('workCenterNo', U."Work Center No.");
        OutJ.Add('needToChangePw', U."Need To Change Pw");

        exit(JsonToText(OutJ));
    end;

    /// <summary>
    /// Revokes the supplied session token (logout).
    ///
    /// HTTP POST  .../ODataV4/MESAuthEndpoints_Logout
    /// Body       { "token": "..." }
    /// Returns    { "success": true, "message": "Logged out successfully" }
    ///         or { "success": false, "error": "...", "message": "..." }
    /// </summary>
    procedure Logout(token: Text): Text
    var
        OutJ: JsonObject;
    begin
        if not AuthMgt.Logout(token) then
            exit(BuildError('Logout failed', 'Invalid or already-expired token'));

        OutJ.Add('success', true);
        OutJ.Add('message', 'Logged out successfully');
        exit(JsonToText(OutJ));
    end;

    /// <summary>
    /// Returns information about the currently authenticated user.
    ///
    /// HTTP POST  .../ODataV4/MESAuthEndpoints_Me
    /// Body       { "token": "..." }
    /// Returns    { "success": true,  "userId": "...", "name": "...",
    ///              "role": "...", "workCenterNo": "...",
    ///              "needToChangePw": false, "isActive": true }
    ///         or { "success": false, "error": "...", "message": "..." }
    /// </summary>
    procedure Me(token: Text): Text
    var
        U: Record "MES User";
        T: Record "MES Auth Token";
        OutJ: JsonObject;
    begin
        // ValidateToken is now read-only — safe to call directly (not in a TryFunction).
        if not AuthMgt.ValidateToken(token, U, T) then
            exit(BuildError('Unauthorized', 'Invalid or expired token'));

        // Write Last Seen At OUTSIDE the validation path.
        AuthMgt.TouchToken(T);

        OutJ.Add('success', true);
        OutJ.Add('userId', U."User Id");
        OutJ.Add('name', U."Auth ID");
        OutJ.Add('role', Format(U.Role));
        OutJ.Add('workCenterNo', U."Work Center No.");
        OutJ.Add('needToChangePw', U."Need To Change Pw");
        OutJ.Add('isActive', U."Is Active");

        exit(JsonToText(OutJ));
    end;

    /// <summary>
    /// Allows an authenticated user to change their own password.
    ///
    /// HTTP POST  .../ODataV4/MESAuthEndpoints_ChangePassword
    /// Body       { "token": "...", "oldPassword": "...", "newPassword": "..." }
    /// Returns    { "success": true, "message": "Password changed successfully" }
    ///         or { "success": false, "error": "...", "message": "..." }
    ///
    /// Flow:
    ///   1. TryValidateChangePassword — read-only: checks token, old password
    ///      correctness, and new password strength.  Safe inside TryFunction.
    ///   2. SetPassword — writes new salt/hash and revokes all tokens.
    ///      Runs OUTSIDE the TryFunction.
    ///
    /// NOTE: password parameters are [NonDebuggable].
    /// </summary>
    [NonDebuggable]
    procedure ChangePassword(token: Text; oldPassword: Text; newPassword: Text): Text
    var
        OutJ: JsonObject;
        TargetUserId: Code[50];
    begin
        if (oldPassword = '') or (newPassword = '') then
            exit(BuildError('Invalid request', 'Both old and new passwords are required'));

        // Step 1 — read-only validation inside a TryFunction.
        if not TryValidateChangePassword(token, oldPassword, newPassword, TargetUserId) then
            exit(BuildErrorFromLastError('Password change failed'));

        // Step 2 — writes (Modify + RevokeAll) happen outside the TryFunction.
        // forceChangeOnNextLogin = false: the user is actively choosing a new
        // password, so no forced-change flag is needed after this call.
        AuthMgt.SetPassword(TargetUserId, newPassword, false);

        OutJ.Add('success', true);
        OutJ.Add('message', 'Password changed successfully');
        exit(JsonToText(OutJ));
    end;

    // =========================================================================
    // SECTION 2 – ADMIN ENDPOINTS  (require Admin role token)
    // =========================================================================

    /// <summary>
    /// Creates a new MES user.  Caller must supply a valid Admin token.
    ///
    /// HTTP POST  .../ODataV4/MESAuthEndpoints_AdminCreateUser
    /// Body       { "token": "...", "userId": "...", "employeeId": "...",
    ///              "authId": "...", "roleInt": 0|1|2, "workCenterNo": "..." }
    ///   roleInt: 0 = Operator, 1 = Supervisor, 2 = Admin
    /// Returns    { "success": true, "message": "...", "userId": "..." }
    ///         or { "success": false, "error": "...", "message": "..." }
    ///
    /// Flow:
    ///   1. TryValidateAdminToken — read-only admin check.  Safe in TryFunction.
    ///   2. CreateUser            — Insert happens OUTSIDE the TryFunction.
    /// </summary>

    // DEPRICATED: is not currently in use do not delete
    procedure AdminCreateUser(
        token: Text;
        userId: Text;
        employeeId: Text;
        authId: Text;
        roleInt: Integer;
        workCenterNo: Text): Text
    var
        Role: Enum "MES User Role";
        OutJ: JsonObject;
        UserIdCode: Code[50];
        AuthIdCode: Code[50];
        EmployeeIdCode: Code[50];
        WCCode: Code[20];
        AdminUserId: Code[50];
    begin
        // ── Validate required fields ──────────────────────────────────────────
        if userId = '' then
            exit(BuildError('Invalid request', 'User ID is required'));

        // ── Map integer → enum ────────────────────────────────────────────────
        case roleInt of
            0:
                Role := Role::Operator;
            1:
                Role := Role::Supervisor;
            2:
                Role := Role::Admin;
            else
                exit(BuildError('Invalid request', 'Invalid role value. Use 0 (Operator), 1 (Supervisor), or 2 (Admin)'));
        end;

        // ── Type conversions ──────────────────────────────────────────────────
        UserIdCode := CopyStr(userId, 1, 50);
        AuthIdCode := CopyStr(authId, 1, 50);
        EmployeeIdCode := CopyStr(employeeId, 1, 50);
        WCCode := CopyStr(workCenterNo, 1, 20);

        // Step 1 — read-only admin token validation inside a TryFunction.
        if not TryValidateAdminToken(token, AdminUserId) then
            exit(BuildErrorFromLastError('User creation failed'));

        // Step 2 — Insert happens OUTSIDE the TryFunction.
        AuthMgt.CreateUser(UserIdCode, EmployeeIdCode, AuthIdCode, Role, WCCode);

        OutJ.Add('success', true);
        OutJ.Add('message', 'User created successfully');
        OutJ.Add('userId', UserIdCode);
        exit(JsonToText(OutJ));
    end;

    /// <summary>
    /// Admin sets or resets a user's password.  Caller must supply a valid
    /// Admin token.  Forces the target user to change password on their
    /// next login.
    ///
    /// HTTP POST  .../ODataV4/MESAuthEndpoints_AdminSetPassword
    /// Body       { "token": "...", "userId": "...", "newPassword": "...",
    ///              "forceChangeOnNextLogin": true|false }
    /// Returns    { "success": true, "message": "..." }
    ///         or { "success": false, "error": "...", "message": "..." }
    ///
    /// Flow:
    ///   1. TryValidateAdminToken — read-only admin check.  Safe in TryFunction.
    ///   2. SetPassword           — writes OUTSIDE the TryFunction.
    ///
    /// NOTE: newPassword is [NonDebuggable].
    /// </summary>
    [NonDebuggable]
    procedure AdminSetPassword(
        token: Text;
        userId: Text;
        newPassword: Text): Text
    var
        OutJ: JsonObject;
        UserIdCode: Code[50];
        AdminUserId: Code[50];
    begin
        if (userId = '') or (newPassword = '') then
            exit(BuildError('Invalid request', 'User ID and new password are required'));

        UserIdCode := CopyStr(userId, 1, 50);

        // Step 1 — read-only admin token validation inside a TryFunction.
        if not TryValidateAdminToken(token, AdminUserId) then
            exit(BuildErrorFromLastError('Password update failed'));

        // Step 2 — writes (Modify + RevokeAll) happen outside the TryFunction.
        AuthMgt.SetPassword(UserIdCode, newPassword, true);

        OutJ.Add('success', true);
        OutJ.Add('message', 'Password updated successfully');
        exit(JsonToText(OutJ));
    end;

    /// <summary>
    /// Activates or deactivates a user account.  Caller must supply a valid
    /// Admin token.  Admin cannot deactivate their own account.
    /// Deactivating automatically revokes all existing tokens for that user.
    ///
    /// HTTP POST  .../ODataV4/MESAuthEndpoints_AdminSetActive
    /// Body       { "token": "...", "userId": "...", "isActive": true|false }
    /// Returns    { "success": true, "message": "..." }
    ///         or { "success": false, "error": "...", "message": "..." }
    ///
    /// Flow:
    ///   1. TryValidateAdminToken — read-only admin check.  Safe in TryFunction.
    ///   2. SetActive             — writes OUTSIDE the TryFunction.
    ///      SetActive itself calls RequireAdmin which re-validates the token
    ///      (this second validation is pure read; TouchToken is called there).
    /// </summary>
    procedure AdminSetActive(token: Text; userId: Text; isActive: Boolean): Text
    var
        OutJ: JsonObject;
        UserIdCode: Code[50];
        AdminUserId: Code[50];
    begin
        if userId = '' then
            exit(BuildError('Invalid request', 'User ID is required'));

        UserIdCode := CopyStr(userId, 1, 50);

        // Step 1 — read-only admin token validation inside a TryFunction.
        if not TryValidateAdminToken(token, AdminUserId) then
            exit(BuildErrorFromLastError('Status update failed'));

        // Step 2 — SetActive performs writes (Modify + RevokeAll) outside the
        // TryFunction.  It calls RequireAdmin internally which re-validates the
        // token and calls TouchToken; this is acceptable here since we are
        // already outside any TryFunction.
        AuthMgt.SetActive(token, UserIdCode, isActive);

        OutJ.Add('success', true);
        OutJ.Add('message', 'User status updated successfully');
        exit(JsonToText(OutJ));
    end;

    // =========================================================================
    // SECTION 3 – [TryFunction] WRAPPERS  (read-only — no writes allowed)
    //
    // AL rule: Modify / Insert / Delete (directly or transitively) are
    // forbidden inside a [TryFunction].  Every wrapper here is strictly
    // read-only.  All database writes happen in the public procedures above,
    // AFTER the TryFunction has returned TRUE.
    // =========================================================================

    /// <summary>
    /// Read-only credential check.  Raises an error on any failure;
    /// the [TryFunction] converts that to a FALSE return value.
    /// </summary>
    [TryFunction]
    [NonDebuggable]
    local procedure TryValidateCredentials(userId: Code[50]; password: Text)
    begin
        // ValidateCredentials is read-only (no writes).
        AuthMgt.ValidateCredentials(userId, password);
    end;

    /// <summary>
    /// Read-only password-change pre-check.  Validates the token, verifies the
    /// old password, and checks the new password strength — all reads.
    /// Sets OutUserId so the caller can pass it to SetPassword() outside.
    /// </summary>
    [TryFunction]
    [NonDebuggable]
    local procedure TryValidateChangePassword(
        token: Text;
        oldPassword: Text;
        newPassword: Text;
        var OutUserId: Code[50])
    begin
        // ValidateChangePassword is read-only (no writes).
        AuthMgt.ValidateChangePassword(token, oldPassword, newPassword, OutUserId);
    end;

    /// <summary>
    /// Read-only admin token check.  Validates the token and asserts Admin role.
    /// Sets OutAdminUserId so the caller can use it for self-action guards.
    /// </summary>
    [TryFunction]
    local procedure TryValidateAdminToken(token: Text; var OutAdminUserId: Code[50])
    begin
        // ValidateAdminToken is read-only (no writes).
        AuthMgt.ValidateAdminToken(token, OutAdminUserId);
    end;

    // =========================================================================
    // SECTION 4 – JSON UTILITIES  (private)
    // =========================================================================

    /// <summary>
    /// Serialises a JsonObject to its text representation.
    /// </summary>
    local procedure JsonToText(J: JsonObject): Text
    var
        JsonText: Text;
    begin
        J.WriteTo(JsonText);
        exit(JsonText);
    end;

    /// <summary>
    /// Builds a standard error JSON envelope from explicit strings.
    ///   { "success": false, "error": "&lt;errorCode&gt;", "message": "&lt;message&gt;" }
    /// </summary>
    local procedure BuildError(ErrorCode: Text; Message: Text): Text
    var
        ErrJ: JsonObject;
    begin
        ErrJ.Add('success', false);
        ErrJ.Add('error', ErrorCode);
        ErrJ.Add('message', Message);
        exit(JsonToText(ErrJ));
    end;

    /// <summary>
    /// Builds a standard error JSON envelope from GetLastErrorText(), then
    /// clears the last error so it does not pollute subsequent calls.
    /// </summary>
    local procedure BuildErrorFromLastError(ErrorCode: Text): Text
    var
        Msg: Text;
    begin
        Msg := GetLastErrorText();
        ClearLastError();
        exit(BuildError(ErrorCode, Msg));
    end;
}
