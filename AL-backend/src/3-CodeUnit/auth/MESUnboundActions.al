// =============================================================================
// Codeunit: MES Unbound Actions
// Object ID: 50125
// Purpose : Exposes all MES auth + admin operations as ODataV4 **unbound
//           actions** via a published Codeunit web service.
//
// ENDPOINTS  (after publishing as web service "MESUnboundActions")
//   POST  .../ODataV4/MESUnboundActions_Login
//   POST  .../ODataV4/MESUnboundActions_Logout
//   POST  .../ODataV4/MESUnboundActions_Me
//   POST  .../ODataV4/MESUnboundActions_ChangePassword
//   POST  .../ODataV4/MESUnboundActions_AdminCreateUser
//   POST  .../ODataV4/MESUnboundActions_AdminSetPassword
//   POST  .../ODataV4/MESUnboundActions_AdminSetActive
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
//   Every public procedure wraps its read/validation call in a [TryFunction].
//   All database writes (Insert/Modify/Delete) happen OUTSIDE TryFunctions.
//   HTTP response is always 200 OK with a JSON body — inspect "success" field.
//
// SECTIONS
//   1 — Auth Endpoints (user-facing)
//   2 — Admin Endpoints (Admin role required)
//   3 — [TryFunction] wrappers (strictly read-only)
//   4 — JSON utilities (private)
// =============================================================================
codeunit 50125 "MES Unbound Actions"
{
    Access = Internal;

    // -------------------------------------------------------------------------
    // Dependencies
    // -------------------------------------------------------------------------
    var
        AuthMgt: Codeunit "MES Auth Mgt";  // business logic layer
        JsonHelper: Codeunit "MES Json Helper";

    // =========================================================================
    // SECTION 1 — AUTH ENDPOINTS
    // =========================================================================

    /// <summary>
    /// Authenticates a user and returns a session token.
    /// Body  : { "userId":"...", "password":"...", "deviceId":"..." }
    /// Return: { "success":true, "token":"...", "expiresAt":"...",
    ///           "userId":"...", "name":"...", "role":"...",
    ///           "workCenterNo":"...", "needToChangePw":... }
    /// </summary>
    [NonDebuggable]
    procedure Login(userId: Text; password: Text; deviceId: Text): Text
    var
        TokenRec: Record "MES Auth Token";
        U: Record "MES User";
        WCRec: Record "MES User Work Center";
        UserIdCode: Code[50];
        OutJ: JsonObject;
        WCArr: JsonArray;
        EmployeeRec: Record Employee;
        MediaInStream: InStream;
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        if (userId = '') or (password = '') then
            exit(JsonHelper.BuildError('Invalid request', 'Username and password are required'));

        // Resolve Auth ID → internal User Id
        U.SetRange("Auth ID", userId);
        if not U.FindFirst() then
            exit(JsonHelper.BuildError('Authentication failed', 'Invalid credentials'));

        UserIdCode := U."User Id";

        if not TryValidateCredentials(UserIdCode, password) then
            exit(JsonHelper.BuildErrorFromLastError('Authentication failed'));

        // INSERT happens OUTSIDE the TryFunction.
        TokenRec := AuthMgt.IssueNewToken(UserIdCode, deviceId);

        if not U.Get(TokenRec."User Id") then
            exit(JsonHelper.BuildError('Internal error', 'User data not found after login'));

        WCRec.SetRange("User Id", U."User Id");
        // get all work centers of this user and put them into a json list
        if WCRec.FindSet() then
            repeat
                WCArr.Add(WCRec."Work Center No.");
            //WCArr = ["WC01", "WC02"]
            until WCRec.Next() = 0;

        OutJ.Add('success', true);
        OutJ.Add('workCenters', WCArr);
        OutJ.Add('needToChangePw', U."Need To Change Pw");
        OutJ.Add('userId', U."User Id");
        OutJ.Add('authId', U."Auth ID");
        OutJ.Add('employeeId', U."Employee ID");
        OutJ.Add('role', Format(U.Role));
        OutJ.add('isActive', U."Is Active");
        OutJ.Add('token', Format(TokenRec."Token"));
        OutJ.Add('expiresAt', Format(TokenRec."Expires At", 0, 9));

        if EmployeeRec.Get(U."Employee ID") then begin
            OutJ.Add('fullName', EmployeeRec.FullName());
            OutJ.Add('email', EmployeeRec."E-Mail");

            if EmployeeRec.Image.HasValue then begin
                TempBlob.CreateOutStream(OutStream);
                EmployeeRec.Image.ExportStream(OutStream);
                TempBlob.CreateInStream(MediaInStream);
                OutJ.Add('imageBase64', Base64Convert.ToBase64(MediaInStream));
            end else
                OutJ.Add('imageBase64', '');
        end else begin
            OutJ.Add('fullName', '');
            OutJ.Add('email', '');
            OutJ.Add('imageBase64', '');
        end;

        exit(JsonHelper.JsonToText(OutJ));
    end;

    /// <summary>
    /// Revokes the supplied session token.
    /// Body  : { "token":"..." }
    /// Return: { "success":true, "message":"Logged out successfully" }
    /// </summary>
    procedure Logout(token: Text): Text
    var
        OutJ: JsonObject;
    begin
        if not AuthMgt.Logout(token) then
            exit(JsonHelper.BuildError('Logout failed', 'Invalid or already-expired token'));

        OutJ.Add('success', true);
        OutJ.Add('message', 'Logged out successfully');
        exit(JsonHelper.JsonToText(OutJ));
    end;

    /// <summary>
    /// Returns information about the currently authenticated user.
    /// Body  : { "token":"..." }
    /// Return: { "success":true, "userId":"...", "name":"...", "role":"...",
    ///           "workCenterNo":"...", "needToChangePw":false, "isActive":true }
    /// </summary>
    procedure Me(token: Text): Text
    var
        U: Record "MES User";
        T: Record "MES Auth Token";
        WCRec: Record "MES User Work Center";
        WCArr: JsonArray;
        OutJ: JsonObject;
        EmployeeRec: Record Employee;
        errorMessage: Text;
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        MediaInStream: InStream;
        OutStream: OutStream;
    begin
        // ValidateToken is now read-only — safe to call directly (not in a TryFunction).
        if not AuthMgt.ValidateToken(token, U, T, errorMessage) then
            exit(JsonHelper.BuildError('Unauthorized', errorMessage));

        // Write Last Seen At OUTSIDE the validation path.
        AuthMgt.TouchToken(T);
        WCRec.SetRange("User Id", U."User Id");
        // get all work centers of this user and put them into a json list
        if WCRec.FindSet() then
            repeat
                WCArr.Add(WCRec."Work Center No.");
            //WCArr = ["WC01", "WC02"]
            until WCRec.Next() = 0;

        OutJ.Add('success', true);
        OutJ.Add('workCenters', WCArr);
        OutJ.Add('needToChangePw', U."Need To Change Pw");
        OutJ.Add('userId', U."User Id");
        OutJ.Add('authId', U."Auth ID");
        OutJ.Add('employeeId', U."Employee ID");
        OutJ.Add('role', Format(U.Role));
        OutJ.add('isActive', U."Is Active");

        if EmployeeRec.Get(U."Employee ID") then begin
            OutJ.Add('fullName', EmployeeRec.FullName());
            OutJ.Add('email', EmployeeRec."E-Mail");

            if EmployeeRec.Image.HasValue then begin
                TempBlob.CreateOutStream(OutStream);
                EmployeeRec.Image.ExportStream(OutStream);
                TempBlob.CreateInStream(MediaInStream);
                OutJ.Add('imageBase64', Base64Convert.ToBase64(MediaInStream));
            end else
                OutJ.Add('imageBase64', '');
        end else begin
            OutJ.Add('fullName', '');
            OutJ.Add('email', '');
            OutJ.Add('imageBase64', '');
        end;


        exit(JsonHelper.JsonToText(OutJ));
    end;

    /// <summary>
    /// Allows an authenticated user to change their own password.
    /// Body  : { "token":"...", "oldPassword":"...", "newPassword":"..." }
    /// Return: { "success":true, "message":"Password changed successfully" }
    /// Flow  : TryValidateChangePassword (read-only) → SetPassword (write, outside TryFunction).
    /// After a successful change, ALL tokens for the user are revoked server-side.
    /// </summary>
    [NonDebuggable]
    procedure ChangePassword(token: Text; oldPassword: Text; newPassword: Text): Text
    var
        OutJ: JsonObject;
        TargetUserId: Code[50];
    begin
        if (oldPassword = '') or (newPassword = '') then
            exit(JsonHelper.BuildError('Invalid request', 'Both old and new passwords are required'));

        if not TryValidateChangePassword(token, oldPassword, newPassword, TargetUserId) then
            exit(JsonHelper.BuildErrorFromLastError('Password change failed'));

        // forceChangeOnNextLogin = false: user is actively choosing their own new password.
        AuthMgt.SetPassword(TargetUserId, newPassword, false);

        OutJ.Add('success', true);
        OutJ.Add('message', 'Password changed successfully');
        exit(JsonHelper.JsonToText(OutJ));
    end;

    // =========================================================================
    // SECTION 2 — ADMIN ENDPOINTS
    // =========================================================================

    /// <summary>
    /// Creates a new MES user.  Requires valid Admin token.
    /// Body  : { "token":"...", "userId":"...", "employeeId":"...",
    ///           "authId":"...", "roleInt":0|1|2, "workCenterNo":"..." }
    /// Return: { "success":true, "message":"...", "userId":"..." }
    /// NOTE  : Kept for tooling compatibility. For new integrations, prefer
    ///         the POST API page (MES User Create API, page 50103).
    /// </summary>
    procedure AdminCreateUser(
        token: Text;
        userId: Text;
        employeeId: Text;
        roleInt: Integer;
        workCenterListJson: Text): Text
    var
        Role: Enum "MES User Role";
        MESUserWC: Record "MES User Work Center";
        MESUser: Record "MES User";
        OutJ: JsonObject;
        UserIdCode: Code[50];
        AuthIdCode: Code[50];
        EmployeeIdCode: Code[50];
        WCCode: Code[20];
        AdminUserId: Code[50];
        WCArr: JsonArray;
        WCToken: JsonToken;
    begin
        // ── Validate required fields ──────────────────────────────────────────
        if userId = '' then
            exit(JsonHelper.BuildError('Invalid request', 'User ID is required'));

        // ── Map integer → enum ────────────────────────────────────────────────
        case roleInt of
            0:
                Role := Role::Operator;
            1:
                Role := Role::Supervisor;
            2:
                Role := Role::Admin;
            else
                exit(JsonHelper.BuildError('Invalid request', 'Invalid role value. Use 0 (Operator), 1 (Supervisor), or 2 (Admin)'));
        end;

        // ── Type conversions ──────────────────────────────────────────────────
        UserIdCode := CopyStr(userId, 1, 50);
        EmployeeIdCode := CopyStr(employeeId, 1, 50);


        // Step 1 — read-only admin token validation inside a TryFunction.
        if not TryValidateAdminToken(token, AdminUserId) then
            exit(JsonHelper.BuildErrorFromLastError('User creation failed'));

        // Step 2 — Insert happens OUTSIDE the TryFunction.
        AuthMgt.CreateUser(UserIdCode, EmployeeIdCode, AuthIdCode, Role);
        WCArr.ReadFrom(workCenterListJson);
        foreach WCToken in WCArr do begin
            WCCode := CopyStr(WCToken.AsValue().AsText(), 1, 20);
            MESUserWC.Init();
            MESUserWC."User Id" := UserIdCode;
            MESUserWC."Work Center No." := WCCode;
            MESUserWC.Insert(true);
        end;

        OutJ.Add('success', true);
        OutJ.Add('message', 'User created successfully');
        OutJ.Add('userId', UserIdCode);
        exit(JsonHelper.JsonToText(OutJ));
    end;

    /// <summary>
    /// Admin resets a user's password.  Forces change on next login.
    /// Body  : { "token":"...", "userId":"...", "newPassword":"..." }
    /// Return: { "success":true, "message":"..." }
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
            exit(JsonHelper.BuildError('Invalid request', 'User ID and new password are required'));

        UserIdCode := CopyStr(userId, 1, 50);

        //Step 1 — read-only admin token validation inside a TryFunction.
        if not TryValidateAdminToken(token, AdminUserId) then
            exit(JsonHelper.BuildErrorFromLastError('Password update failed'));

        // Step 2 — writes (Modify + RevokeAll) happen outside the TryFunction.
        AuthMgt.SetPassword(UserIdCode, newPassword, true);
        OutJ.Add('success', true);
        OutJ.Add('message', 'Password updated successfully');
        exit(JsonHelper.JsonToText(OutJ));
    end;

    /// <summary>
    /// Activates or deactivates a user account.  Requires Admin token.
    /// Admin cannot deactivate their own account.
    /// Body  : { "token":"...", "userId":"...", "isActive":true|false }
    /// Return: { "success":true, "message":"..." }
    /// </summary>
    procedure AdminSetActive(token: Text; userId: Text; isActive: Boolean): Text
    var
        OutJ: JsonObject;
        UserIdCode: Code[50];
        AdminUserId: Code[50];
    begin
        if userId = '' then
            exit(JsonHelper.BuildError('Invalid request', 'User ID is required'));

        UserIdCode := CopyStr(userId, 1, 50);

        // Step 1 — read-only admin token validation inside a TryFunction.
        if not TryValidateAdminToken(token, AdminUserId) then
            exit(JsonHelper.BuildErrorFromLastError('Status update failed'));

        // Step 2 — SetActive performs writes (Modify + RevokeAll)
        AuthMgt.SetActive(UserIdCode, isActive);

        OutJ.Add('success', true);
        OutJ.Add('message', 'User status updated successfully');
        exit(JsonHelper.JsonToText(OutJ));
    end;

    // =========================================================================
    // SECTION 3 — [TryFunction] WRAPPERS  (read-only — no writes inside)
    //
    // AL rule: Insert/Modify/Delete are forbidden inside a [TryFunction].
    // Every wrapper here is strictly read-only.
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
        AuthMgt.ValidateChangePassword(token, oldPassword, newPassword, OutUserId);
    end;

    /// <summary>
    /// Read-only admin token check.  Validates the token and asserts Admin role.
    /// Sets OutAdminUserId so the caller can use it for self-action guards.
    /// </summary>
    [TryFunction]
    local procedure TryValidateAdminToken(token: Text; var OutAdminUserId: Code[50])
    begin
        AuthMgt.ValidateAdminToken(token, OutAdminUserId);
    end;

    procedure fetchAllMESUsers(): Text
    var
        EmployeeRec: Record Employee;
        UserRec: Record "MES User";
        UserWorkCenter: Record "MES User Work Center";
        WorkCenter: Record "Work Center";
        AuthToken: Record "MES Auth Token";
        JsonHelper: Codeunit "MES Json Helper";
        UsersArray: JsonArray;
        UserJson: JsonObject;
        WorkCentersArray: JsonArray;
        IsOnline: Boolean;
        LastSeenAt: DateTime;
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        MediaInStream: InStream;
        OutStream: OutStream;
    begin
        if UserRec.FindSet() then
            repeat
                Clear(UserJson);
                Clear(WorkCentersArray);

                UserJson.Add('userId', UserRec."User Id");
                UserJson.Add('authId', UserRec."Auth ID");
                UserJson.Add('employeeId', UserRec."Employee ID");
                UserJson.Add('role', Format(UserRec.Role));
                UserJson.add('isActive', UserRec."Is Active");


                if EmployeeRec.Get(UserRec."Employee ID") then begin
                    UserJson.Add('fullName', EmployeeRec.FullName());
                    UserJson.Add('email', EmployeeRec."E-Mail");


                    if EmployeeRec.Image.HasValue then begin
                        TempBlob.CreateOutStream(OutStream);
                        EmployeeRec.Image.ExportStream(OutStream);
                        TempBlob.CreateInStream(MediaInStream);
                        UserJson.Add('imageBase64', Base64Convert.ToBase64(MediaInStream));
                    end else
                        UserJson.Add('imageBase64', '');
                end else begin
                    UserJson.Add('fullName', '');
                    UserJson.Add('email', '');
                    UserJson.Add('imageBase64', '');
                end;

                // check is online last activity in mes user list 
                IsOnline := false;
                LastSeenAt := 0DT;//0dt means null/zero datetime

                AuthToken.Reset();
                AuthToken.SetRange("User Id", UserRec."User Id");
                if AuthToken.FindSet() then
                    repeat
                        // comparing all tocken to find the most recent activity , at the end the lastseenat will hold the lastest 
                        //9am>0 ---10am>9am....
                        if AuthToken."Last Seen At" > LastSeenAt then
                            LastSeenAt := AuthToken."Last Seen At";

                        // online = at least one token is valid right now
                        if (not AuthToken.Revoked) and (AuthToken."Expires At" > CurrentDateTime()) then
                            IsOnline := true;
                    until AuthToken.Next() = 0;

                UserJson.Add('isOnline', IsOnline);
                UserJson.Add('lastSeenAt', Format(LastSeenAt));

                UserWorkCenter.Reset();
                UserWorkCenter.SetRange("User Id", UserRec."User Id");
                if UserWorkCenter.FindSet() then
                    repeat
                        if WorkCenter.Get(UserWorkCenter."Work Center No.") then
                            WorkCentersArray.Add(WorkCenter.Name);
                    until UserWorkCenter.Next() = 0;

                UserJson.Add('workCenters', WorkCentersArray);
                UsersArray.Add(UserJson);

            until UserRec.Next() = 0;

        exit(JsonHelper.JsonToTextArr(UsersArray));
    end;

    // for the declaired by 
    procedure fetchMESUsersByWC(wcID: Code[20]): Text
    var
        EmployeeRec: Record Employee;
        UserRec: Record "MES User";
        UserWorkCenter: Record "MES User Work Center";
        WorkCenter: Record "Work Center";
        JsonHelper: Codeunit "MES Json Helper";
        UsersArray: JsonArray;
        UserJson: JsonObject;
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        MediaInStream: InStream;
        OutStream: OutStream;
    begin
        UserWorkCenter.Reset();
        UserWorkCenter.SetRange("Work Center No.", wcID);

        if UserWorkCenter.FindSet() then
            repeat
                // Load the user for the current UserId/WorkCenter pair
                if UserRec.Get(UserWorkCenter."User Id") then begin
                    Clear(UserJson);

                    UserJson.Add('userId', UserRec."User Id");
                    UserJson.Add('authId', UserRec."Auth ID");
                    UserJson.Add('employeeId', UserRec."Employee ID");
                    UserJson.Add('role', Format(UserRec.Role));

                    if EmployeeRec.Get(UserRec."Employee ID") then begin

                        UserJson.Add('fullName', EmployeeRec.FullName());
                        // if there is an image and there is a record in employee table then convert the image to base64 and add to json
                        if EmployeeRec.Image.HasValue then begin
                            TempBlob.CreateOutStream(OutStream);
                            EmployeeRec.Image.ExportStream(OutStream);
                            TempBlob.CreateInStream(MediaInStream);
                            UserJson.Add('imageBase64', Base64Convert.ToBase64(MediaInStream));
                        end else
                            UserJson.Add('imageBase64', '');
                    end else begin
                        UserJson.Add('fullName', '');
                        UserJson.Add('imageBase64', '');
                    end;

                    UsersArray.Add(UserJson);
                end;
            until UserWorkCenter.Next() = 0;

        exit(JsonHelper.JsonToTextArr(UsersArray));
    end;

    // =============================================================================
    // PURPOSE
    //   Allows an Admin to change the workcenter of an existing MES User and or the 
    //   role.
    //   A role change also resets the user's work-center assignments, because
    //   the valid cardinality differs per role:
    //     Operator   → exactly 1 work center
    //     Supervisor → 1 or more work centers
    //     Admin      → work-center list is ignored (pass '[]' or '')
    //
    // PARAMETERS
    //   token             — valid Admin session token
    //   targetUserId      — User Id of the MES User whose role will change
    //   newRoleInt        — 0 = Operator, 1 = Supervisor, 2 = Admin
    //   workCenterListJson— JSON array of work-center strings, e.g. '["100","200"]'
    //
    // RETURNS
    //   JSON string: { "success": true } on success
    //                { "error": "...", "message": "..." } on failure
    // =============================================================================
    procedure AdminChangeUserRole(
        token: Text;
        targetUserId: Text;
        newRoleInt: Integer;
        workCenterListJson: Text
    ): Text
    var
        CallerUser: Record "MES User";
        TargetUser: Record "MES User";
        AuthToken: Record "MES Auth Token";
        UserWorkCenter: Record "MES User Work Center";
        NewRole: Enum "MES User Role";
        JsonHelper: Codeunit "MES Json Helper";
        WorkCenterArray: JsonArray;
        WorkCenterToken: JsonToken;
        WorkCenterValue: Text;
        NewUserWorkCenter: Record "MES User Work Center";
        errorMessage: Text;
    begin
        // ── 1. Authenticate & authorise ────────────────────────────────────
        if not AuthMgt.ValidateToken(token, CallerUser, AuthToken, errorMessage) then
            exit(JsonHelper.BuildError('Unauthorized', errorMessage));

        AuthMgt.TouchToken(AuthToken);

        if CallerUser.Role <> CallerUser.Role::Admin then
            exit(JsonHelper.BuildError('Forbidden', 'Only Admins can change user roles.'));

        // ── 2. Load target user ────────────────────────────────────────────
        if not TargetUser.Get(CopyStr(targetUserId, 1, 50)) then
            exit(JsonHelper.BuildError('NotFound', StrSubstNo('User %1 not found.', targetUserId)));

        // ── 3. Map integer to enum ─────────────────────────────────────────
        case newRoleInt of
            0:
                NewRole := NewRole::Operator;
            1:
                NewRole := NewRole::Supervisor;
            2:
                NewRole := NewRole::Admin;
            else
                exit(JsonHelper.BuildError('BadRequest',
                    StrSubstNo('Invalid roleInt %1. Accepted values: 0 (Operator), 1 (Supervisor), 2 (Admin).', newRoleInt)));
        end;

        // ── 4. Validate work-center cardinality ────────────────────────────
        // Admin role: work-center list is irrelevant — skip validation.
        if NewRole <> NewRole::Admin then begin
            if not WorkCenterArray.ReadFrom(workCenterListJson) then
                exit(JsonHelper.BuildError('BadRequest', 'workCenterListJson is not valid JSON.'));

            if WorkCenterArray.Count() = 0 then
                exit(JsonHelper.BuildError('BadRequest',
                    'At least one work center is required for Operator and Supervisor roles.'));

            if (NewRole = NewRole::Operator) and (WorkCenterArray.Count() > 1) then
                exit(JsonHelper.BuildError('BadRequest',
                    'An Operator can only be assigned to exactly one work center.'));
        end;

        // ── 5. Apply role change ───────────────────────────────────────────
        TargetUser.Role := NewRole;
        TargetUser.Modify(true);

        // ── 6. Reset work-center assignments ──────────────────────────────
        UserWorkCenter.SetRange("User Id", TargetUser."User Id");
        UserWorkCenter.DeleteAll();

        if NewRole <> NewRole::Admin then begin
            WorkCenterArray.ReadFrom(workCenterListJson);
            foreach WorkCenterToken in WorkCenterArray do begin
                WorkCenterToken.WriteTo(WorkCenterValue);
                // Strip surrounding quotes that WriteTo adds for string tokens.
                WorkCenterValue := WorkCenterValue.TrimStart('"').TrimEnd('"');

                Clear(NewUserWorkCenter);
                NewUserWorkCenter."User Id" := TargetUser."User Id";
                NewUserWorkCenter."Work Center No." := CopyStr(WorkCenterValue, 1, 20);
                NewUserWorkCenter.Insert(true);
            end;
        end;

        exit('{"success":true,"message":"User role updated successfully."}');
    end;

   
    procedure fetchAllEmployees(): Text
    var
        EmployeeRec: Record Employee;
        MESUser: Record "MES User";
        EmployeesArr: JsonArray;
        EmployeesObj: JsonObject;

        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        MediaInStream: InStream;
        OutStream: OutStream;
    begin
        if EmployeeRec.FindSet() then
            repeat
                MESUser.Reset();
                MESUser.SetRange("Employee ID", EmployeeRec."No.");

                if MESUser.IsEmpty() then begin
                    Clear(EmployeesObj);

                    EmployeesObj.Add('id', EmployeeRec."No.");
                    EmployeesObj.Add('firstName', EmployeeRec."First Name");
                    EmployeesObj.Add('middleName', EmployeeRec."Middle Name");
                    EmployeesObj.Add('lastName', EmployeeRec."Last Name");
                    EmployeesObj.Add('email', EmployeeRec."E-Mail");
                    if EmployeeRec.Image.HasValue then begin
                        TempBlob.CreateOutStream(OutStream);
                        EmployeeRec.Image.ExportStream(OutStream);

                        TempBlob.CreateInStream(MediaInStream);
                        EmployeesObj.Add('imageBase64', Base64Convert.ToBase64(MediaInStream));
                    end else
                        EmployeesObj.Add('imageBase64', '');

                    EmployeesArr.Add(EmployeesObj);
                end;

            until EmployeeRec.Next() = 0;

        exit(JsonHelper.JsonToTextArr(EmployeesArr));
    end;
}

    
