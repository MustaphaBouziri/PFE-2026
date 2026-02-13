codeunit 50111 "MES Auth Mgt"
{
    // IMPROVED VERSION with security enhancements

    var
        PwMgt: Codeunit "MES Password Mgt";
        MaxFailedAttempts: Integer;
        LockoutMinutes: Integer;
        TokenTTLHours: Integer;

    // ---------- INITIALIZATION ----------

    procedure Initialize()
    begin
        MaxFailedAttempts := 5;
        LockoutMinutes := 15;
        TokenTTLHours := 12;
    end;

    // ---------- USER CRUD (internal/admin use) ----------

    procedure CreateUser(UserId: Code[50]; FullName: Text[100]; Role: Enum "MES User Role"; DepartmentCode: Code[20]; WorkCenterNo: Code[20])
    var
        U: Record "MES User";
    begin
        if UserId = '' then
            Error('User ID cannot be empty.');

        if U.Get(UserId) then
            Error('User %1 already exists.', UserId);

        U.Init();
        U."User Id" := UserId;
        U.Name := FullName;
        U.Role := Role;
        U."Department Code" := DepartmentCode;
        U."Work Center No." := WorkCenterNo;
        U."Is Active" := true;
        U."Need To Change Pw" := true;
        U."Password Iterations" := DefaultPasswordIterations();
        U."Created At" := CurrentDateTime();
        U.Insert(true);
    end;

    [NonDebuggable]
    procedure SetPassword(UserId: Code[50]; NewPassword: Text; ForceChangeOnNextLogin: Boolean)
    var
        U: Record "MES User";
        Salt: Text;
        Hash: Text;
    begin
        if not U.Get(UserId) then
            Error('User %1 not found.', UserId);

        if not IsPasswordStrong(NewPassword) then
            Error('Password must be at least 8 characters long and contain uppercase, lowercase, number, and special character.');

        if U."Password Iterations" = 0 then
            U."Password Iterations" := DefaultPasswordIterations();

        Salt := PwMgt.MakeSalt();
        Hash := PwMgt.HashPassword(NewPassword, Salt, U."Password Iterations");

        U."Password Salt" := CopyStr(Salt, 1, 50);
        U."Password Hash" := CopyStr(Hash, 1, 128);
        U."Need To Change Pw" := ForceChangeOnNextLogin;
        U.Modify(true);

        // Revoke all existing tokens when password changes
        RevokeAllTokensForUser(UserId);
    end;

    // ---------- LOGIN / TOKENS ----------

    [NonDebuggable]
    procedure Login(UserId: Code[50]; Password: Text; DeviceId: Text): Record "MES Auth Token"
    var
        U: Record "MES User";
        T: Record "MES Auth Token";
        NullToken: Record "MES Auth Token";
    begin
        Initialize();

        // Generic error message to prevent user enumeration
        if not U.Get(UserId) then
            Error('Invalid credentials.');

        if not U."Is Active" then
            Error('Account is disabled. Please contact administrator.');

        
        // Check if password is set
        if (U."Password Hash" = '') or (U."Password Salt" = '') then
            Error('Account setup incomplete. Please contact administrator.');

        // Verify password
        if not PwMgt.VerifyPassword(Password, U."Password Hash", U."Password Salt", U."Password Iterations") then begin
            Error('Invalid credentials.');
        end;

        

        // Issue new token
        T := IssueToken(UserId, DeviceId);
        exit(T);
    end;

    procedure ValidateToken(TokenText: Text; var U: Record "MES User"; var T: Record "MES Auth Token"): Boolean
    var
        TokenGuid: Guid;
    begin
        Clear(U);
        Clear(T);

        if TokenText = '' then
            exit(false);

        if not Evaluate(TokenGuid, TokenText) then
            exit(false);

        if not T.Get(TokenGuid) then
            exit(false);

        if T.Revoked then
            exit(false);

        if T."Expires At" <= CurrentDateTime() then
            exit(false);

        if not U.Get(T."User Id") then
            exit(false);

        if not U."Is Active" then
            exit(false);

        // Update last seen timestamp
        T."Last Seen At" := CurrentDateTime();
        T.Modify(true);

        exit(true);
    end;

    procedure Logout(TokenText: Text): Boolean
    var
        T: Record "MES Auth Token";
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

    [NonDebuggable]
    procedure ChangePassword(TokenText: Text; OldPassword: Text; NewPassword: Text): Boolean
    var
        U: Record "MES User";
        T: Record "MES Auth Token";
    begin
        if not ValidateToken(TokenText, U, T) then
            Error('Unauthorized. Please login again.');

        if not PwMgt.VerifyPassword(OldPassword, U."Password Hash", U."Password Salt", U."Password Iterations") then
            Error('Current password is incorrect.');

        SetPassword(U."User Id", NewPassword, false);
        exit(true);
    end;

    // ---------- ADMIN GUARDS + ADMIN ENDPOINT HELPERS ----------

    procedure RequireAdmin(TokenText: Text; var AdminUser: Record "MES User")
    var
        T: Record "MES Auth Token";
    begin
        if not ValidateToken(TokenText, AdminUser, T) then
            Error('Unauthorized. Please login again.');

        if AdminUser.Role <> AdminUser.Role::Admin then
            Error('Forbidden. Admin access required.');
    end;

    procedure SetActive(TokenText: Text; TargetUserId: Code[50]; Active: Boolean): Boolean
    var
        AdminUser: Record "MES User";
        U: Record "MES User";
    begin
        RequireAdmin(TokenText, AdminUser);

        if not U.Get(TargetUserId) then
            Error('User %1 not found.', TargetUserId);

        // Prevent admin from disabling themselves
        if AdminUser."User Id" = TargetUserId then
            Error('Cannot modify your own account status.');

        U."Is Active" := Active;
        U.Modify(true);

        if not Active then
            RevokeAllTokensForUser(TargetUserId);

        exit(true);
    end;

    // ---------- CLEANUP OPERATIONS ----------

    procedure CleanupExpiredTokens()
    var
        T: Record "MES Auth Token";
    begin
        T.SetFilter("Expires At", '<%1', CurrentDateTime());
        if not T.IsEmpty() then
            T.DeleteAll(true);
    end;

    // ---------- INTERNALS ----------

    local procedure IssueToken(UserId: Code[50]; DeviceId: Text): Record "MES Auth Token"
    var
        T: Record "MES Auth Token";
        TTL: Duration;
    begin
        Initialize();
        TTL := TokenTTLHours * 60 * 60 * 1000; // Convert hours to milliseconds

        T.Init();
        T."Token" := CreateGuid();
        T."User Id" := UserId;
        T."Device Id" := CopyStr(DeviceId, 1, 100);
        T."Issued At" := CurrentDateTime();
        T."Expires At" := CurrentDateTime() + TTL;
        T.Revoked := false;
        T."Last Seen At" := CurrentDateTime();
        T.Insert(true);

        exit(T);
    end;

    

   

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

    local procedure DefaultPasswordIterations(): Integer
    begin
        exit(10000); // Increased from 1000 for better security
    end;

    local procedure IsPasswordStrong(Password: Text): Boolean
    var
        HasUpper: Boolean;
        HasLower: Boolean;
        HasDigit: Boolean;
        HasSpecial: Boolean;
        i: Integer;
        Char: Char;
    begin
        // Minimum length check
        if StrLen(Password) < 8 then
            exit(false);

        // Check for character variety
        for i := 1 to StrLen(Password) do begin
            Char := Password[i];
            case true of
                (Char in ['A' .. 'Z']):
                    HasUpper := true;
                (Char in ['a' .. 'z']):
                    HasLower := true;
                (Char in ['0' .. '9']):
                    HasDigit := true;
                else
                    HasSpecial := true;
            end;
        end;

        exit(HasUpper and HasLower and HasDigit and HasSpecial);
    end;
}
