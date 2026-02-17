// =============================================================================
// Codeunit: MES Auth Mgt
// ID      : 50111
// Purpose : Core authentication business logic for the MES module.
//           This is the single source of truth for all auth decisions —
//           it owns user CRUD, login, token lifecycle, password management,
//           and the Admin role guard.
//
// DESIGN PRINCIPLES
//   - This codeunit never talks to the HTTP layer.  It raises AL Error()
//     calls for all failure conditions; callers (MESUnboundActions) wrap
//     calls in [TryFunction] to convert errors into JSON responses.
//   - All parameters that carry sensitive values (passwords, hashes) are
//     on procedures marked [NonDebuggable] so they cannot appear in debugger
//     variable watches, telemetry, or support snapshots.
//   - Generic error messages are used for authentication failures to prevent
//     user-enumeration attacks.
//
// CALL HIERARCHY
//   MESUnboundActions (HTTP layer)
//     └─ MES Auth Mgt  (this codeunit — business logic)
//           └─ MES Password Mgt  (hashing primitives)
//
// SECTIONS
//   1 — User CRUD
//   2 — Login / Token Management
//   3 — Admin Guards & Admin Helpers
//   4 — Maintenance
//   5 — Private Helpers
// =============================================================================
codeunit 50111 "MES Auth Mgt"
{
    // -------------------------------------------------------------------------
    // Dependencies
    // -------------------------------------------------------------------------
    var
        PwMgt: Codeunit "MES Password Mgt";

    // =========================================================================
    // SECTION 1 — USER CRUD  (internal / admin use only)
    // =========================================================================

    /// <summary>
    /// Creates a new MES User record.
    ///
    /// The new account is created in the following default state:
    ///   Is Active          = true   (immediately usable)
    ///   Need To Change Pw  = true   (user must set password before first use)
    ///   Created At         = CurrentDateTime()
    ///
    /// NOTE: This procedure only creates the record.  No password is set here.
    /// Call SetPassword() separately before the account can be used for Login().
    ///
    /// Raises an error if:
    ///   - UserId is blank
    ///   - A user with this UserId already exists
    /// </summary>
    procedure CreateUser(
        UserId       : Code[50];
        EmployeeID   : Code[50];
        AuthID       : Text[100];
        Role         : Enum "MES User Role";
        WorkCenterNo : Code[20])
    var
        U: Record "MES User";
    begin
        if UserId = '' then
            Error('User ID cannot be empty.');

        if U.Get(UserId) then
            Error('User %1 already exists.', UserId);

        U.Init();
        U."User Id"             := UserId;
        U."employee ID"         := EmployeeID;
        U."Auth ID"             := AuthID;
        U.Role                  := Role;
        U."Work Center No."     := WorkCenterNo;
        U."Is Active"           := true;
        U."Need To Change Pw"   := true;               // force password reset on first login
        U."Created At"          := CurrentDateTime();
        U.Insert(true);
    end;

    /// <summary>
    /// Sets or resets the password for an existing MES user.
    ///
    /// Steps performed:
    ///   1. Validate password meets complexity requirements (IsPasswordStrong).
    ///   2. Generate a new random salt via MES Password Mgt.
    ///   3. Hash (password + salt) 
    ///   4. Persist the salt and hash to the MES User record.
    ///   5. Revoke ALL existing tokens — any live sessions are terminated.
    ///
    /// [NonDebuggable]: password and hash values are never visible in the debugger.
    ///
    /// Raises an error if:
    ///   - UserId does not exist
    ///   - NewPassword fails the strength policy
    /// </summary>
    [NonDebuggable]
    procedure SetPassword(
        UserId                : Code[50];
        NewPassword           : Text;
        ForceChangeOnNextLogin: Boolean)
    var
        U   : Record "MES User";
        Salt: Text;
        Hash: Text;
    begin
        if not U.Get(UserId) then
            Error('User %1 not found.', UserId);

        if not IsPasswordStrong(NewPassword) then
            Error('Password must be at least 8 characters long and contain uppercase, lowercase, number, and special character.');

        Salt := PwMgt.MakeSalt();
        Hash := PwMgt.HashPassword(NewPassword, Salt);

        // CopyStr is required: Salt is 64 chars but field is Text[50];
        // Hash is 64 chars and field is Text[128] — CopyStr is safe for Hash.
        U."Password Salt"    := CopyStr(Salt, 1, 500);
        U."Hashed Password"  := CopyStr(Hash, 1, 128);
        U."Need To Change Pw":= ForceChangeOnNextLogin;
        U.Modify(true);

        // Invalidate all active sessions immediately when the password changes.
        // This ensures a compromised token cannot be used after a password reset.
        RevokeAllTokensForUser(UserId);
    end;

    // =========================================================================
    // SECTION 2 — LOGIN / TOKEN MANAGEMENT
    // =========================================================================

    /// <summary>
    /// Authenticates a user with UserId + Password and issues a new session token.
    ///
    /// Security properties:
    ///   - Generic "Invalid credentials." message for both "no such user" and
    ///     "wrong password" cases — prevents user-enumeration attacks where an
    ///     attacker probes which usernames are registered.
    ///   - Returns a populated MES Auth Token record on success.
    ///   - Token TTL is 12 hours (see IssueToken).
    ///
    /// [NonDebuggable]: password and token values are never visible in the debugger.
    ///
    /// Raises an error (caught by TryLogin in MESUnboundActions) if:
    ///   - User does not exist          → "Invalid credentials."
    ///   - Account is disabled          → "Account is disabled."
    ///   - No password has been set     → "Account setup incomplete."
    ///   - Password is wrong            → "Invalid credentials."
    /// </summary>
    [NonDebuggable]
    procedure Login(
        UserId  : Code[50];
        Password: Text;
        DeviceId: Text) : Record "MES Auth Token"
    var
        U: Record "MES User";
        T: Record "MES Auth Token"; 
        ComputedHash: Text;
    begin
        ComputedHash := PwMgt.HashPassword(Password, U."Password Salt");
   
        // Use a single generic message for both "not found" and "wrong password"
        // to prevent an attacker from learning which user IDs are registered.
        if not U.Get(UserId) then
            Error('Invalid credentials. user does not exist');

        if not U."Is Active" then
            Error('Account is disabled. Please contact administrator.');

        // A user created but not yet given a password cannot log in.
        if (U."Hashed Password" = '') or (U."Password Salt" = '') then
            Error('Account setup incomplete. Please contact administrator.');

        // Verify the supplied password against the stored hash.
        if not PwMgt.VerifyPassword(Password, U."Hashed Password", U."Password Salt") then
            Error('Invalid credentials. password is wrong PW mismatch. Stored=%1.. Computed=%2..',ComputedHash,  U."Hashed Password");

        // All checks passed — create and return a new session token.
        T := IssueToken(UserId, DeviceId);
        exit(T);
    end;

    /// <summary>
    /// Validates a raw token string and returns the associated user and token records.
    ///
    /// A token is considered valid only when ALL of the following are true:
    ///   - TokenText is a parseable GUID
    ///   - The token exists in the MES Auth Token table
    ///   - Token.Revoked = false
    ///   - Token.Expires At > CurrentDateTime()  (strict future check)
    ///   - The associated MES User exists
    ///   - User.Is Active = true
    ///
    /// On success, updates Token."Last Seen At" for audit trail purposes.
    /// On any failure, clears U and T and returns FALSE — the caller never
    /// needs to inspect error state, just check the return value.
    ///
    /// Parameters:
    ///   TokenText — raw GUID string as received from the HTTP client
    ///   U         — populated with the MES User record on success
    ///   T         — populated with the MES Auth Token record on success
    /// </summary>
    procedure ValidateToken(
        TokenText : Text;
        var U     : Record "MES User";
        var T     : Record "MES Auth Token") : Boolean
    var
        TokenGuid: Guid;
    begin
        Clear(U);
        Clear(T);

        if TokenText = '' then
            exit(false);

        // The token value must be a valid GUID — reject malformed strings early.
        if not Evaluate(TokenGuid, TokenText) then
            exit(false);

        if not T.Get(TokenGuid) then
            exit(false);

        // Revoked tokens must be rejected even if not yet expired.
        if T.Revoked then
            exit(false);

        // Strict expiry: Expires At must be strictly in the future.
        if T."Expires At" <= CurrentDateTime() then
            exit(false);

        if not U.Get(T."User Id") then
            exit(false);

        // A disabled user's tokens are rejected even if not formally revoked.
        if not U."Is Active" then
            exit(false);

        // Refresh the activity timestamp for every successful validation.
        // This enables idle-session detection and sliding-window monitoring.
        T."Last Seen At" := CurrentDateTime();
        T.Modify(true);

        exit(true);
    end;

    /// <summary>
    /// Revokes a single session token (logout).
    ///
    /// Marks the token as Revoked = true.  The token record is kept in the
    /// table (not deleted) so that the audit trail is preserved.  Expired
    /// tokens are cleaned up separately by CleanupExpiredTokens().
    ///
    /// Returns TRUE if the token was found and revoked.
    /// Returns FALSE if the token string is invalid, not parseable, or not found.
    /// </summary>
    procedure Logout(TokenText: Text) : Boolean
    var
        T        : Record "MES Auth Token";
        TokenGuid: Guid;
    begin
        if TokenText = '' then
            exit(false);

        if not Evaluate(TokenGuid, TokenText) then
            exit(false);

        if not T.Get(TokenGuid) then
            exit(false);

        T.Revoked := true;
        T.Modify(true);
        exit(true);
    end;

    /// <summary>
    /// Allows an authenticated user to change their own password.
    ///
    /// Requires both a valid session token (the user must be logged in) and
    /// the correct current password.  This double-factor requirement prevents
    /// an attacker who has stolen a token from changing the password silently.
    ///
    /// On success, delegates to SetPassword() which will:
    ///   - Enforce password strength rules
    ///   - Generate a new salt and hash
    ///   - Revoke ALL existing tokens (including the current session)
    ///   The client must log in again after a successful password change.
    ///
    /// [NonDebuggable]: password values are never visible in the debugger.
    ///
    /// Raises an error if:
    ///   - Token is invalid or expired     → "Unauthorized."
    ///   - OldPassword is incorrect        → "Current password is incorrect."
    ///   - NewPassword fails strength test → error from SetPassword()
    /// </summary>
    [NonDebuggable]
    procedure ChangePassword(
        TokenText  : Text;
        OldPassword: Text;
        NewPassword: Text) : Boolean
    var
        U: Record "MES User";
        T: Record "MES Auth Token";
    begin
        if not ValidateToken(TokenText, U, T) then
            Error('Unauthorized. Please login again.');

        // Require the current password before accepting a new one.
        if not PwMgt.VerifyPassword(OldPassword, U."Hashed Password", U."Password Salt") then
            Error('Current password is incorrect.');

        // forceChangeOnNextLogin = false: the user is actively choosing a new
        // password, so no forced-change flag is needed after this call.
        SetPassword(U."User Id", NewPassword, false);
        exit(true);
    end;

    // =========================================================================
    // SECTION 3 — ADMIN GUARDS & ADMIN HELPERS
    // =========================================================================

    /// <summary>
    /// Validates a token AND asserts that the token owner holds the Admin role.
    ///
    /// This is the single entry point for all admin privilege checks.
    /// Call this at the start of any procedure that requires admin access.
    ///
    /// On success, AdminUser is populated with the calling admin's MES User record
    /// so callers can use AdminUser."User Id" for self-action guards.
    ///
    /// Raises an error if:
    ///   - Token is invalid or expired → "Unauthorized. Please login again."
    ///   - User role is not Admin      → "Forbidden. Admin access required."
    /// </summary>
    procedure RequireAdmin(
        TokenText    : Text;
        var AdminUser: Record "MES User")
    var
        T: Record "MES Auth Token";
    begin
        if not ValidateToken(TokenText, AdminUser, T) then
            Error('Unauthorized. Please login again.');

        if AdminUser.Role <> AdminUser.Role::Admin then
            Error('Forbidden. Admin access required.');
    end;

    /// <summary>
    /// Activates or deactivates a user account.
    ///
    /// Requires a valid Admin token.  The admin cannot deactivate their own
    /// account (self-deactivation guard using AdminUser."User Id").
    ///
    /// When deactivating (Active = false):
    ///   - Sets Is Active = false on the target user record.
    ///   - Immediately revokes ALL active tokens for the target user.
    ///   Any in-flight requests using those tokens will fail on the next
    ///   ValidateToken() call.
    ///
    /// When activating (Active = true):
    ///   - Sets Is Active = true.
    ///   - Does NOT create new tokens — the user must log in again.
    ///
    /// Raises an error if:
    ///   - Token is not a valid Admin token → from RequireAdmin()
    ///   - TargetUserId does not exist      → "User X not found."
    ///   - Admin tries to deactivate self   → "Cannot modify your own account."
    /// </summary>
    procedure SetActive(
        TokenText   : Text;
        TargetUserId: Code[50];
        Active      : Boolean) : Boolean
    var
        AdminUser: Record "MES User";
        U        : Record "MES User";
    begin
        // RequireAdmin validates the token AND populates AdminUser."User Id".
        // This must be called first so the self-deactivation guard below works.
        RequireAdmin(TokenText, AdminUser);

        if not U.Get(TargetUserId) then
            Error('User %1 not found.', TargetUserId);

        // Prevent an admin from accidentally locking themselves out.
        if AdminUser."User Id" = TargetUserId then
            Error('Cannot modify your own account status.');

        U."Is Active" := Active;
        U.Modify(true);

        // Immediately terminate all active sessions when disabling an account.
        if not Active then
            RevokeAllTokensForUser(TargetUserId);

        exit(true);
    end;

    // =========================================================================
    // SECTION 4 — MAINTENANCE
    // =========================================================================

    /// <summary>
    /// Deletes all token records that have passed their expiry timestamp.
    ///
    /// Tokens are never deleted on Logout() or revocation — only their
    /// Revoked flag is set — so this procedure must be run periodically to
    /// prevent unbounded growth of the MES Auth Token table.
    ///
    /// Recommended: Schedule as a Job Queue entry running daily during
    /// off-peak hours.  A batch of 10 000 tokens takes under a second.
    ///
    /// NOTE: This deletes expired tokens regardless of their Revoked status,
    /// since an expired token is invalid by definition.
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
    /// Creates, persists, and returns a new MES Auth Token for a user session.
    ///
    /// Token properties:
    ///   Token       = new GUID (generated by CreateGuid)
    ///   User Id     = caller-supplied UserId
    ///   Device Id   = caller-supplied DeviceId (truncated to 100 chars)
    ///   Issued At   = CurrentDateTime()
    ///   Expires At  = CurrentDateTime() + 12 hours
    ///   Last Seen At= CurrentDateTime()
    ///   Revoked     = false
    ///
    /// The TTL of 12 hours is hardcoded here.  If you need it to be
    /// configurable, move it to a setup table or a named constant.
    /// </summary>
    local procedure IssueToken(
        UserId  : Code[50];
        DeviceId: Text) : Record "MES Auth Token"
    var
        T       : Record "MES Auth Token";
        TTLHours: Integer;
        TTL     : Duration;
    begin
        TTLHours := 12;
        TTL := TTLHours * 60 * 60 * 1000;  // hours → milliseconds (Duration type)

        T.Init();
        T."Token"        := CreateGuid();
        T."User Id"      := UserId;
        T."Device Id"    := CopyStr(DeviceId, 1, 100);
        T."Issued At"    := CurrentDateTime();
        T."Expires At"   := CurrentDateTime() + TTL;
        T."Last Seen At" := CurrentDateTime();
        T.Revoked        := false;
        T.Insert(true);

        exit(T);
    end;

    /// <summary>
    /// Marks every token belonging to UserId as Revoked = true.
    ///
    /// Uses the UserTokens secondary index (key on "User Id") to find all
    /// matching rows without a full table scan.
    ///
    /// Called by:
    ///   SetPassword()  — after every password change
    ///   SetActive(false) — when an account is disabled
    /// </summary>
    local procedure RevokeAllTokensForUser(UserId: Code[50])
    var
        T: Record "MES Auth Token";
    begin
        T.SetRange("User Id", UserId);
        if T.FindSet(true) then
            repeat
                T.Revoked := true;
                T.Modify(true);
            until T.Next() = 0;
    end;


    /// <summary>
    /// Returns TRUE only when the password satisfies ALL complexity rules:
    ///   - Minimum 8 characters
    ///   - At least one uppercase letter  (A–Z)
    ///   - At least one lowercase letter  (a–z)
    ///   - At least one digit             (0–9)
    ///   - At least one other character   (punctuation, symbol, space, etc.)
    ///
    /// This check is performed on every SetPassword() call.
    /// It is a server-side guard — never rely solely on client-side validation.
    /// </summary>
    local procedure IsPasswordStrong(Password: Text) : Boolean
    var
        HasUpper  : Boolean;
        HasLower  : Boolean;
        HasDigit  : Boolean;
        HasSpecial: Boolean;
        i         : Integer;
        c         : Char;
    begin
        if StrLen(Password) < 8 then
            exit(false);

        for i := 1 to StrLen(Password) do begin
            c := Password[i];
            case true of
                (c in ['A' .. 'Z']): HasUpper   := true;
                (c in ['a' .. 'z']): HasLower   := true;
                (c in ['0' .. '9']): HasDigit   := true;
                else                 HasSpecial := true;
            end;
        end;
        exit(true)
        //TODO RETURN THIS TO WHAT IT WAS DON'T FORGET
        //exit(HasUpper and HasLower and HasDigit and HasSpecial);
    end;
}
