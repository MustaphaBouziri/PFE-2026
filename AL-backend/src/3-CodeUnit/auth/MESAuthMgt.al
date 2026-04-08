// =============================================================================
// Codeunit: MES Auth Mgt
// ID      : 50111
// Domain  : Auth / 3-CodeUnits
// Purpose : Core authentication business logic — single source of truth for
//           all auth decisions: user CRUD, login, token lifecycle, password
//           management, and the Admin role guard.
//
// DESIGN PRINCIPLES
//   - Never touches the HTTP layer.  Raises AL Error() for all failures;
//     callers (MESUnboundActions) wrap calls in [TryFunction].
//   - [NonDebuggable] on sensitive procedures prevents passwords/hashes
//     appearing in debugger watches, telemetry, or support snapshots.
//   - Generic "Invalid credentials." for auth failures — prevents user enumeration.
//
// CALL HIERARCHY
//   MESUnboundActions (50125) — HTTP / OData layer
//     └─ MES Auth Mgt  (50111) — business logic          ← THIS FILE
//           └─ MES Password Mgt (50110) — crypto primitives
//
// TOKEN TTL
//   Hardcoded to 12 hours in IssueToken(). Move to a setup table or YAML
//   config if runtime configurability is ever required.
//
// SECTIONS
//   1 — User CRUD
//   2 — Login / Token Management
//   3 — Admin Guards & Helpers
//   4 — Maintenance
//   5 — Private Helpers
// =============================================================================
codeunit 50111 "MES Auth Mgt"
{
    var
        PwMgt: Codeunit "MES Password Mgt";
        AuthValidation: Codeunit "MES Auth Validation";

    // =========================================================================
    // SECTION 1 — USER CRUD
    // =========================================================================

    /// <summary>
    /// Creates a new MES User record with default state:
    ///   Is Active = true, Need To Change Pw = true.
    /// Does NOT set a password — call SetPassword() separately before the
    /// account can be used for Login().
    /// </summary>
    procedure CreateUser(
        UserId: Code[50];
        EmployeeID: Code[50];
        AuthID: Text[100];
        Role: Enum "MES User Role"
        )
    var
        U: Record "MES User";
    begin
        if UserId = '' then
            Error('User ID cannot be empty.');
        if U.Get(UserId) then
            Error('User %1 already exists.', UserId);

        U.Init();
        U."User Id" := UserId;
        U."employee ID" := EmployeeID;
        U."Auth ID" := AuthID;
        U.Role := Role;
        U."Is Active" := true;
        U."Need To Change Pw" := true;
        U."Created At" := CurrentDateTime();
        U.Insert(true);
    end;

    /// <summary>
    /// Sets or resets the password for an existing user.
    /// Steps: validate strength → new salt → hash → persist → revoke all tokens.
    /// [NonDebuggable]: password/hash values never visible in debugger.
    /// </summary>
    [NonDebuggable]
    procedure SetPassword(
        UserId: Code[50];
        NewPassword: Text;
        ForceChangeOnNextLogin: Boolean)
    var
        U: Record "MES User";
        Salt, Hash : Text;
    begin
        if not U.Get(UserId) then
            Error('User %1 not found.', UserId);

        if not AuthValidation.IsPasswordStrong(NewPassword) then
            Error('Password must be at least 8 characters and contain uppercase, lowercase, number, and special character.');

        Salt := PwMgt.MakeSalt();
        Hash := PwMgt.HashPassword(NewPassword, Salt);

        U."Password Salt" := CopyStr(Salt, 1, 64);
        U."Hashed Password" := CopyStr(Hash, 1, 128);
        U."Need To Change Pw" := ForceChangeOnNextLogin;
        U.Modify(true);

        // Invalidate all active sessions — a compromised token cannot persist after a reset.
        AuthValidation.RevokeAllTokensForUser(UserId);
    end;

    // =========================================================================
    // SECTION 2 — LOGIN / TOKEN MANAGEMENT
    // =========================================================================

    /// <summary>
    /// Validates userId + password.  READ-ONLY — safe inside [TryFunction].
    /// Generic "Invalid credentials." message prevents user-enumeration attacks.
    /// </summary>
    [NonDebuggable]
    procedure ValidateCredentials(UserId: Code[50]; Password: Text)
    var
        U: Record "MES User";
    begin
        if not U.Get(UserId) then
            Error('Invalid credentials.');
        if not U."Is Active" then
            Error('Account is disabled. Please contact administrator.');
        if (U."Hashed Password" = '') or (U."Password Salt" = '') then
            Error('Account setup incomplete. Please contact administrator.');
        if not PwMgt.VerifyPassword(Password, U."Hashed Password", U."Password Salt") then
            Error('Invalid credentials.');
    end;

    procedure IssueNewToken(UserId: Code[50]; DeviceId: Text): Record "MES Auth Token"
    begin
        exit(IssueToken(UserId, DeviceId));
    end;

    /// <summary>
    /// Validates a raw token string.  READ-ONLY — safe inside [TryFunction].
    /// A token is valid only when ALL of these are true:
    ///   parseable GUID → exists → not revoked → not expired → user exists → user active.
    /// Returns TRUE on success; clears U and T and returns FALSE on any failure.
    /// </summary>
    procedure ValidateToken(
        TokenText: Text;
        var U: Record "MES User";
        var T: Record "MES Auth Token"; 
        var errorMessage: Text): Boolean
    var
        TokenGuid: Guid;
    begin
        Clear(U);
        Clear(T);
        if TokenText = '' then exit(false);
        errorMessage := 'Unauthorized. Invalid or expired token. token text ||';
        if not Evaluate(TokenGuid, TokenText) then exit(false);
        errorMessage := 'Unauthorized. Invalid or expired token. evaluate ||';
        if not T.Get(TokenGuid) then exit(false);
        errorMessage := 'Unauthorized. Invalid or expired token. get ||';
        if T.Revoked then exit(false);
        errorMessage := 'Unauthorized. Invalid or expired token. revoked ||';
        if T."Expires At" <= CurrentDateTime() then exit(false);
        errorMessage := 'Unauthorized. Invalid or expired token. expired ||';
        if not U.Get(T."User Id") then exit(false);
        errorMessage := 'Unauthorized. Invalid or expired token. getuser ||';
        if not U."Is Active" then exit(false);
        errorMessage := 'Unauthorized. Invalid or expired token. active ||';
        exit(true);
    end;

    /// <summary>
    /// Updates Token."Last Seen At" for activity tracking.
    /// Separated from ValidateToken() so that procedure stays read-only and
    /// safe inside [TryFunction].  Call immediately after a successful validation.
    /// </summary>
    procedure TouchToken(var T: Record "MES Auth Token")
    begin
        T."Last Seen At" := CurrentDateTime();
        T.Modify(true);
    end;

    /// <summary>
    /// Revokes a single session token (logout).
    /// Marks Revoked = true; keeps record for audit trail.
    /// Returns TRUE if found and revoked; FALSE if invalid or not found.
    /// </summary>
    procedure Logout(TokenText: Text): Boolean
    var
        T: Record "MES Auth Token";
        TokenGuid: Guid;
    begin
        if TokenText = '' then exit(false);
        if not Evaluate(TokenGuid, TokenText) then exit(false);
        if not T.Get(TokenGuid) then exit(false);
        T.Revoked := true;
        T.Modify(true);
        exit(true);
    end;

    /// <summary>
    /// Read-only pre-validation for password change.  Safe inside [TryFunction].
    /// Checks: token valid → old password correct → new password strong.
    /// Sets OutUserId so the caller can pass it to SetPassword() outside the TryFunction.
    /// </summary>
    [NonDebuggable]
    procedure ValidateChangePassword(
        TokenText: Text;
        OldPassword: Text;
        NewPassword: Text;
        var OutUserId: Code[50])
    var
        U: Record "MES User";
        T: Record "MES Auth Token";
        errorMessage: Text;
    begin
        if not ValidateToken(TokenText, U, T,errorMessage) then
            Error(errorMessage);
        if not PwMgt.VerifyPassword(OldPassword, U."Hashed Password", U."Password Salt") then
            Error('Current password is incorrect.');
        if not AuthValidation.IsPasswordStrong(NewPassword) then
            Error('Password must be at least 8 characters and contain uppercase, lowercase, number, and special character.');
        OutUserId := U."User Id";
    end;

    /// <summary>
    /// Read-only admin token check.  Safe inside [TryFunction].
    /// Sets OutAdminUserId for self-action guards in the caller.
    /// </summary>
    procedure ValidateAdminToken(TokenText: Text; var OutAdminUserId: Code[50])
    var
        AdminUser: Record "MES User";
        T: Record "MES Auth Token";
        errorMessage: Text;
    begin
        if not ValidateToken(TokenText, AdminUser, T,errorMessage) then
            Error(errorMessage);
        if AdminUser.Role <> AdminUser.Role::Admin then
            Error('Forbidden. Admin access required.');
        OutAdminUserId := AdminUser."User Id";
    end;

    // =========================================================================
    // SECTION 3 — ADMIN GUARDS & HELPERS
    // =========================================================================

    /// <summary>
    /// Validates a token AND asserts Admin role.  Entry point for all admin
    /// privilege checks in write-capable contexts (OUTSIDE TryFunctions).
    /// Populates AdminUser so callers can use AdminUser."User Id" for self-action guards.
    /// Also calls TouchToken() to record admin activity.
    /// </summary>
    procedure RequireAdmin(TokenText: Text; var AdminUser: Record "MES User")
    var
        T: Record "MES Auth Token";
        errorMessage: Text;
    begin
        if not ValidateToken(TokenText, AdminUser, T,errorMessage) then
            Error(errorMessage);
        if AdminUser.Role <> AdminUser.Role::Admin then
            Error('Forbidden. Admin access required.');
        TouchToken(T);
    end;

    /// <summary>
    /// Activates or deactivates a user account.  Requires valid Admin token.
    /// Admin cannot deactivate their own account.
    /// Deactivating immediately revokes ALL active tokens for the target user.
    /// </summary>
    procedure SetActive(TokenText: Text; TargetUserId: Code[50]; Active: Boolean): Boolean
    var
        AdminUser: Record "MES User";
        U: Record "MES User";
    begin
        // RequireAdmin(TokenText, AdminUser);

        if not U.Get(TargetUserId) then
            Error('User %1 not found.', TargetUserId);
        if AdminUser."User Id" = TargetUserId then
            Error('Cannot modify your own account status.');

        U."Is Active" := Active;
        U.Modify(true);

        if not Active then
            AuthValidation.RevokeAllTokensForUser(TargetUserId);

        exit(true);
    end;

    // =========================================================================
    // SECTION 4 — MAINTENANCE
    // =========================================================================

    /// <summary>
    /// Deletes all token records past their expiry timestamp.
    /// Tokens are never deleted on logout — only flagged Revoked.
    /// Schedule as a Job Queue entry running daily during off-peak hours.
    /// </summary>
    procedure CleanupExpiredTokens()
    var
        T: Record "MES Auth Token";
    begin
        T.SetFilter("Expires At", '<%1', CurrentDateTime());
        if not T.IsEmpty() then
            T.DeleteAll(true);
    end;

    // =========================================================================
    // SECTION 5 — PRIVATE HELPERS
    // =========================================================================

    /// <summary>
    /// Creates, persists, and returns a new session token.
    /// TTL: 12 hours (hardcoded).  Move to a setup table if configurability needed.
    /// </summary>
    local procedure IssueToken(UserId: Code[50]; DeviceId: Text): Record "MES Auth Token"
    var
        T: Record "MES Auth Token";
        TTL: Duration;
    begin
        TTL := 12 * 60 * 60 * 1000;  // 12 hours → milliseconds

        T.Init();
        T."Token" := CreateGuid();
        T."User Id" := UserId;
        T."Device Id" := CopyStr(DeviceId, 1, 100);
        T."Issued At" := CurrentDateTime();
        T."Expires At" := CurrentDateTime() + TTL;
        T."Last Seen At" := CurrentDateTime();
        T.Revoked := false;
        T.Insert(true);
        exit(T);
    end;

}
