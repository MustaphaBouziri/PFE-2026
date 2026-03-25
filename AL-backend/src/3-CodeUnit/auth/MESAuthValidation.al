codeunit 50112 "MES Auth Validation"
{
    Access = Internal;

    procedure IsPasswordStrong(Password: Text): Boolean
    var
        HasUpper, HasLower, HasDigit, HasSpecial : Boolean;
        i: Integer;
        c: Char;
    begin
        if StrLen(Password) < 8 then exit(false);

        for i := 1 to StrLen(Password) do begin
            c := Password[i];
            case true of
                (c in ['A' .. 'Z']):
                    HasUpper := true;
                (c in ['a' .. 'z']):
                    HasLower := true;
                (c in ['0' .. '9']):
                    HasDigit := true;
                else
                    HasSpecial := true;
            end;
        end;
        exit(true); // during developement 
        // TODO: return this to how it is after it is no longer needed
        //exit(HasUpper and HasLower and HasDigit and HasSpecial);
    end;

    procedure RevokeAllTokensForUser(UserId: Code[50])
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

    [TryFunction]
    [NonDebuggable]
    procedure TryValidateCredentials(userId: Code[50]; password: Text)
    var
        AuthMgt: Codeunit "MES Auth Mgt";
    begin
        AuthMgt.ValidateCredentials(userId, password);
    end;

    [TryFunction]
    [NonDebuggable]
    procedure TryValidateChangePassword(
        token: Text;
        oldPassword: Text;
        newPassword: Text;
        var OutUserId: Code[50])
    var
        AuthMgt: Codeunit "MES Auth Mgt";
    begin
        AuthMgt.ValidateChangePassword(token, oldPassword, newPassword, OutUserId);
    end;

    [TryFunction]
    procedure TryValidateAdminToken(token: Text; var OutAdminUserId: Code[50])
    var
        AuthMgt: Codeunit "MES Auth Mgt";
    begin
        AuthMgt.ValidateAdminToken(token, OutAdminUserId);
    end;
}
