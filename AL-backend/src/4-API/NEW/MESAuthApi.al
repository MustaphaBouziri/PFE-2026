codeunit 50120 "MES Auth API"
{
    // IMPROVED VERSION with better error handling and JSON utilities

    var
        Auth: Codeunit "MES Auth Mgt";

    [TryFunction]
    local procedure TryLogin(userId: Code[50]; password: Text; deviceId: Text; var TokenRec: Record "MES Auth Token")
    begin
        TokenRec := Auth.Login(userId, password, deviceId);
    end;

    procedure Login(userId: Text; password: Text; deviceId: Text): Text
    var
        TokenRec: Record "MES Auth Token";
        U: Record "MES User";
        OutJ: JsonObject;
        ErrorJ: JsonObject;
        UserIdCode: Code[50];
    begin
        // Input validation
        if (userId = '') or (password = '') then begin
            ErrorJ.Add('error', 'Invalid request');
            ErrorJ.Add('message', 'Username and password are required');
            exit(JsonToText(ErrorJ));
        end;

        UserIdCode := CopyStr(userId, 1, 50);

        // Try login with error handling
        if not TryLogin(UserIdCode, password, deviceId, TokenRec) then begin
            ErrorJ.Add('error', 'Authentication failed');
            ErrorJ.Add('message', GetLastErrorText());
            ClearLastError();
            exit(JsonToText(ErrorJ));
        end;

        // Get user details
        if not U.Get(TokenRec."User Id") then begin
            ErrorJ.Add('error', 'Internal error');
            ErrorJ.Add('message', 'User data not found');
            exit(JsonToText(ErrorJ));
        end;

        // Build success response
        OutJ.Add('success', true);
        OutJ.Add('token', Format(TokenRec."Token"));
        OutJ.Add('expiresAt', Format(TokenRec."Expires At", 0, 9)); // ISO 8601 format
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
        ErrorJ: JsonObject;
    begin
        if not Auth.ValidateToken(token, U, T) then begin
            ErrorJ.Add('error', 'Unauthorized');
            ErrorJ.Add('message', 'Invalid or expired token');
            exit(JsonToText(ErrorJ));
        end;

        OutJ.Add('success', true);
        OutJ.Add('userId', U."User Id");
        OutJ.Add('name', U.Name);
        OutJ.Add('role', Format(U.Role));
        OutJ.Add('departmentCode', U."Department Code");
        OutJ.Add('workCenterNo', U."Work Center No.");
        OutJ.Add('needToChangePw', U."Need To Change Pw");
        OutJ.Add('isActive', U."Is Active");

        exit(JsonToText(OutJ));
    end;

    procedure Logout(token: Text): Text
    var
        OutJ: JsonObject;
        ErrorJ: JsonObject;
        Success: Boolean;
    begin
        Success := Auth.Logout(token);

        if Success then begin
            OutJ.Add('success', true);
            OutJ.Add('message', 'Logged out successfully');
        end else begin
            ErrorJ.Add('error', 'Logout failed');
            ErrorJ.Add('message', 'Invalid token');
            exit(JsonToText(ErrorJ));
        end;

        exit(JsonToText(OutJ));
    end;

    [TryFunction]
    local procedure TryChangePassword(token: Text; oldPassword: Text; newPassword: Text)
    var
        Success: Boolean;
    begin
        Success := Auth.ChangePassword(token, oldPassword, newPassword);
    end;

    procedure ChangePassword(token: Text; oldPassword: Text; newPassword: Text): Text
    var
        OutJ: JsonObject;
        ErrorJ: JsonObject;
    begin
        if (oldPassword = '') or (newPassword = '') then begin
            ErrorJ.Add('error', 'Invalid request');
            ErrorJ.Add('message', 'Both old and new passwords are required');
            exit(JsonToText(ErrorJ));
        end;

        if not TryChangePassword(token, oldPassword, newPassword) then begin
            ErrorJ.Add('error', 'Password change failed');
            ErrorJ.Add('message', GetLastErrorText());
            ClearLastError();
            exit(JsonToText(ErrorJ));
        end;

        OutJ.Add('success', true);
        OutJ.Add('message', 'Password changed successfully');
        exit(JsonToText(OutJ));
    end;

    // ---------- Admin endpoints ----------

    [TryFunction]
    local procedure TryAdminCreateUser(token: Text; userId: Code[50]; fullName: Text[100]; role: Enum "MES User Role"; departmentCode: Code[20]; workCenterNo: Code[20])
    var
        AdminUser: Record "MES User";
    begin
        Auth.RequireAdmin(token, AdminUser);
        Auth.CreateUser(userId, fullName, role, departmentCode, workCenterNo);
    end;

    procedure AdminCreateUser(token: Text; userId: Text; fullName: Text; roleInt: Integer; departmentCode: Text; workCenterNo: Text): Text
    var
        Role: Enum "MES User Role";
        OutJ: JsonObject;
        ErrorJ: JsonObject;
        UserIdCode: Code[50];
        FullNameText: Text[100];
        DeptCode: Code[20];
        WCCode: Code[20];
    begin
        // Input validation
        if userId = '' then begin
            ErrorJ.Add('error', 'Invalid request');
            ErrorJ.Add('message', 'User ID is required');
            exit(JsonToText(ErrorJ));
        end;

        // Convert role integer to enum
        case roleInt of
            0:
                Role := Role::Operator;
            1:
                Role := Role::Supervisor;
            2:
                Role := Role::Admin;
            else begin
                    ErrorJ.Add('error', 'Invalid request');
                    ErrorJ.Add('message', 'Invalid role value');
                    exit(JsonToText(ErrorJ));
                end;
        end;

        // Convert types
        UserIdCode := CopyStr(userId, 1, 50);
        FullNameText := CopyStr(fullName, 1, 100);
        DeptCode := CopyStr(departmentCode, 1, 20);
        WCCode := CopyStr(workCenterNo, 1, 20);

        // Try to create user
        if not TryAdminCreateUser(token, UserIdCode, FullNameText, Role, DeptCode, WCCode) then begin
            ErrorJ.Add('error', 'User creation failed');
            ErrorJ.Add('message', GetLastErrorText());
            ClearLastError();
            exit(JsonToText(ErrorJ));
        end;

        OutJ.Add('success', true);
        OutJ.Add('message', 'User created successfully');
        OutJ.Add('userId', UserIdCode);
        exit(JsonToText(OutJ));
    end;

    [TryFunction]
    local procedure TryAdminSetPassword(token: Text; userId: Code[50]; newPassword: Text; forceChange: Boolean)
    var
        AdminUser: Record "MES User";
    begin
        Auth.RequireAdmin(token, AdminUser);
        Auth.SetPassword(userId, newPassword, forceChange);
    end;

    procedure AdminSetPassword(token: Text; userId: Text; newPassword: Text; forceChangeOnNextLogin: Boolean): Text
    var
        OutJ: JsonObject;
        ErrorJ: JsonObject;
        UserIdCode: Code[50];
    begin
        if (userId = '') or (newPassword = '') then begin
            ErrorJ.Add('error', 'Invalid request');
            ErrorJ.Add('message', 'User ID and password are required');
            exit(JsonToText(ErrorJ));
        end;

        UserIdCode := CopyStr(userId, 1, 50);

        if not TryAdminSetPassword(token, UserIdCode, newPassword, forceChangeOnNextLogin) then begin
            ErrorJ.Add('error', 'Password update failed');
            ErrorJ.Add('message', GetLastErrorText());
            ClearLastError();
            exit(JsonToText(ErrorJ));
        end;

        OutJ.Add('success', true);
        OutJ.Add('message', 'Password updated successfully');
        exit(JsonToText(OutJ));
    end;

    [TryFunction]
    local procedure TryAdminSetActive(token: Text; userId: Code[50]; isActive: Boolean)
    var
        Success: Boolean;
    begin
        Success := Auth.SetActive(token, userId, isActive);
    end;

    procedure AdminSetActive(token: Text; userId: Text; isActive: Boolean): Text
    var
        OutJ: JsonObject;
        ErrorJ: JsonObject;
        UserIdCode: Code[50];
    begin
        if userId = '' then begin
            ErrorJ.Add('error', 'Invalid request');
            ErrorJ.Add('message', 'User ID is required');
            exit(JsonToText(ErrorJ));
        end;

        UserIdCode := CopyStr(userId, 1, 50);

        if not TryAdminSetActive(token, UserIdCode, isActive) then begin
            ErrorJ.Add('error', 'Status update failed');
            ErrorJ.Add('message', GetLastErrorText());
            ClearLastError();
            exit(JsonToText(ErrorJ));
        end;

        OutJ.Add('success', true);
        OutJ.Add('message', 'User status updated successfully');
        exit(JsonToText(OutJ));
    end;

    // ---------- Utility procedure ----------

    local procedure JsonToText(J: JsonObject): Text
    var
        JsonText: Text;
    begin
        J.WriteTo(JsonText);
        exit(JsonText);
    end;
}
