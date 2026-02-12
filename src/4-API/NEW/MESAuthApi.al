codeunit 50120 "MES Auth API"
{

    var
        Auth: Codeunit "MES Auth Mgt";

    procedure Login(userId: Text; password: Text; deviceId: Text): Text
    var
        TokenRec: Record "MES Auth Token";
        U: Record "MES User";
        OutJ: JsonObject;
    begin
        TokenRec := Auth.Login(userId, password, deviceId);

        U.Get(TokenRec."User Id");

        OutJ.Add('token', Format(TokenRec."Token"));
        OutJ.Add('expiresAt', Format(TokenRec."Expires At"));
        OutJ.Add('userId', U."User Id");
        OutJ.Add('name', U.Name);
        OutJ.Add('role', Format(U.Role));
        OutJ.Add('departmentCode', U."Department Code");
        OutJ.Add('workCenterNo', U."Work Center No.");
        OutJ.Add('needToChangePw', U."Need To Change Pw");

        exit(JsonToText(OutJ));
    end;

    procedure Me(token: Text): Text
    var
        U: Record "MES User";
        T: Record "MES Auth Token";
        OutJ: JsonObject;
    begin
        if not Auth.ValidateToken(token, U, T) then
            Error('Unauthorized.');

        OutJ.Add('userId', U."User Id");
        OutJ.Add('name', U.Name);
        OutJ.Add('role', Format(U.Role));
        OutJ.Add('departmentCode', U."Department Code");
        OutJ.Add('workCenterNo', U."Work Center No.");
        OutJ.Add('needToChangePw', U."Need To Change Pw");

        exit(JsonToText(OutJ));
    end;

    procedure Logout(token: Text): Boolean
    begin
        exit(Auth.Logout(token));
    end;

    procedure ChangePassword(token: Text; oldPassword: Text; newPassword: Text): Boolean
    begin
        exit(Auth.ChangePassword(token, oldPassword, newPassword));
    end;

    // ---------- Admin endpoints (optional but usually needed) ----------

    procedure AdminCreateUser(token: Text; userId: Text; fullName: Text; roleInt: Integer; departmentCode: Text; workCenterNo: Text): Boolean
    var
        AdminUser: Record "MES User";
        Role: Enum "MES User Role";
    begin
        Auth.RequireAdmin(token, AdminUser);

        case roleInt of
            0:
                Role := Role::Operator;
            1:
                Role := Role::Supervisor;
            2:
                Role := Role::Admin;
            else
                Error('Invalid role.');
        end;

        Auth.CreateUser(userId, fullName, Role, departmentCode, workCenterNo);
        exit(true);
    end;

    procedure AdminSetPassword(token: Text; userId: Text; newPassword: Text; forceChangeOnNextLogin: Boolean): Boolean
    var
        AdminUser: Record "MES User";
    begin
        Auth.RequireAdmin(token, AdminUser);
        Auth.SetPassword(userId, newPassword, forceChangeOnNextLogin);
        exit(true);
    end;

    procedure AdminSetActive(token: Text; userId: Text; isActive: Boolean): Boolean
    begin
        exit(Auth.SetActive(token, userId, isActive));
    end;

    local procedure JsonToText(J: JsonObject): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        ResultText: Text;
    begin
        TempBlob.CreateOutStream(OutStr);
        J.WriteTo(OutStr);
        TempBlob.CreateInStream(InStr);
        InStr.ReadText(ResultText);
        exit(ResultText);
    end;
}
