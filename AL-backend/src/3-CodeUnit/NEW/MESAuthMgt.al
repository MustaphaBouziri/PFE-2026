codeunit 50111 "MES Auth Mgt"
{

    var
        PwMgt: Codeunit "MES Password Mgt";

    // ---------- USER CRUD (internal/admin use) ----------

    procedure CreateUser(UserId: Code[50]; FullName: Text[100]; Role: Enum "MES User Role"; DepartmentCode: Code[20]; WorkCenterNo: Code[20])
    var
        U: Record "MES User";
    begin
        if U.Get(UserId) then
            Error('User already exists.');

        U.Init();
        U."User Id" := UserId;
        U.Name := FullName;
        U.Role := Role;
        U."Department Code" := DepartmentCode;
        U."Work Center No." := WorkCenterNo;
        U."Is Active" := true;
        U."Need To Change Pw" := true;
        U."Password Iterations" := DefaultPasswordIterations();
        U."Failed Login Count" := 0;
        U."Lockout Until" := 0DT;
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
            Error('User not found.');

        if not IsPasswordStrong(NewPassword) then
            Error('Password is not strong enough.');

        if U."Password Iterations" = 0 then
            U."Password Iterations" := DefaultPasswordIterations();

        Salt := PwMgt.MakeSalt();
        Hash := PwMgt.HashPassword(NewPassword, Salt, U."Password Iterations");

        U."Password Salt" := Salt;
        U."Password Hash" := Hash;
        U."Need To Change Pw" := ForceChangeOnNextLogin;
        U.Modify(true);

        RevokeAllTokensForUser(UserId);
    end;

    // ---------- LOGIN / TOKENS ----------

    [NonDebuggable]
    procedure Login(UserId: Code[50]; Password: Text; DeviceId: Text): Record "MES Auth Token"
    var
        U: Record "MES User";
        T: Record "MES Auth Token";
    begin
        if not U.Get(UserId) then
            Error('Invalid credentials.');

        if not U."Is Active" then
            Error('Invalid credentials.');

        if (U."Lockout Until" <> 0DT) and (U."Lockout Until" > CurrentDateTime()) then
            Error('Invalid credentials.');

        if (U."Password Hash" = '') or (U."Password Salt" = '') then
            Error('Password not set.');

        if not PwMgt.VerifyPassword(Password, U."Password Hash", U."Password Salt", U."Password Iterations") then begin
            RegisterFailedLogin(U);
            Error('Invalid credentials.');
        end;

        ResetFailedLogin(U);

        T := IssueToken(UserId, DeviceId);
        exit(T);
    end;

    procedure ValidateToken(TokenText: Text; var U: Record "MES User"; var T: Record "MES Auth Token"): Boolean
    var
        TokenGuid: Guid;
    begin
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

        T."Last Seen At" := CurrentDateTime();
        T.Modify(true);

        exit(true);
    end;

    procedure Logout(TokenText: Text): Boolean
    var
        T: Record "MES Auth Token";
        TokenGuid: Guid;
    begin
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
            Error('Unauthorized.');

        if not PwMgt.VerifyPassword(OldPassword, U."Password Hash", U."Password Salt", U."Password Iterations") then
            Error('Invalid credentials.');

        SetPassword(U."User Id", NewPassword, false);
        exit(true);
    end;

    // ---------- ADMIN GUARDS + ADMIN ENDPOINT HELPERS ----------

    procedure RequireAdmin(TokenText: Text; var AdminUser: Record "MES User")
    var
        T: Record "MES Auth Token";
    begin
        if not ValidateToken(TokenText, AdminUser, T) then
            Error('Unauthorized.');
        if AdminUser.Role <> AdminUser.Role::Admin then
            Error('Forbidden.');
    end;

    procedure SetActive(TokenText: Text; TargetUserId: Code[50]; Active: Boolean): Boolean
    var
        AdminUser: Record "MES User";
        U: Record "MES User";
    begin
        RequireAdmin(TokenText, AdminUser);

        if not U.Get(TargetUserId) then
            Error('User not found.');

        U."Is Active" := Active;
        U.Modify(true);

        if not Active then
            RevokeAllTokensForUser(TargetUserId);

        exit(true);
    end;

    // ---------- INTERNALS ----------

    local procedure IssueToken(UserId: Code[50]; DeviceId: Text): Record "MES Auth Token"
    var
        T: Record "MES Auth Token";
        TTL: Duration;
    begin
        TTL := 12 * 60 * 60 * 1000; // 12 hours

        T.Init();
        T."Token" := CreateGuid();
        T."User Id" := UserId;
        T."Device Id" := DeviceId;
        T."Issued At" := CurrentDateTime();
        T."Expires At" := CurrentDateTime() + TTL;
        T.Revoked := false;
        T."Last Seen At" := CurrentDateTime();
        T.Insert(true);

        exit(T);
    end;

    local procedure RegisterFailedLogin(var U: Record "MES User")
    var
        LockoutDuration: Duration;
    begin
        U."Failed Login Count" += 1;

        if U."Failed Login Count" >= 5 then begin
            LockoutDuration := 15 * 60 * 1000; // 15 minutes
            U."Lockout Until" := CurrentDateTime() + LockoutDuration;
            U."Failed Login Count" := 0;
        end;

        U.Modify(true);
    end;

    local procedure ResetFailedLogin(var U: Record "MES User")
    begin
        U."Failed Login Count" := 0;
        U."Lockout Until" := 0DT;
        U.Modify(true);
    end;

    local procedure RevokeAllTokensForUser(UserId: Code[50])
    var
        T: Record "MES Auth Token";
    begin
        T.SetRange("User Id", UserId);
        if T.FindSet() then
            repeat
                T.Revoked := true;
                T.Modify(true);
            until T.Next() = 0;
    end;

    local procedure DefaultPasswordIterations(): Integer
    begin
        exit(1000);
    end;

    local procedure IsPasswordStrong(Password: Text): Boolean
    var
        PwText: Text;
    begin
        PwText := Password;
        exit(StrLen(PwText) >= 8);
    end;
}
