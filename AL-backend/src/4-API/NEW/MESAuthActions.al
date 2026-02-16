page 50121 "MES Auth Actions"
{
    PageType = API;
    APIPublisher = 'yourcompany';
    APIGroup = 'mes';
    APIVersion = 'v1.0';
    EntityName = 'authAction';
    EntitySetName = 'authActions';
    SourceTable = "MES User";
    DelayedInsert = true;
    Extensible = false;

    layout
    {
        area(Content)
        {
            // Minimal layout - this is an action-only page
            field(userId; Rec."User Id")
            {
                Caption = 'User Id';
            }
        }
    }

    var
        AuthAPI: Codeunit "MES Auth API";

    // ==================== USER ENDPOINTS ====================

    /// <summary>
    /// Login endpoint - Authenticates user and returns token
    /// </summary>
    [ServiceEnabled]
    procedure Login(userId: Text; password: Text; deviceId: Text): Text
    begin
        exit(AuthAPI.Login(userId, password, deviceId));
    end;

    /// <summary>
    /// Logout endpoint - Revokes the provided token
    /// </summary>
    [ServiceEnabled]
    procedure Logout(token: Text): Text
    begin
        exit(AuthAPI.Logout(token));
    end;

    /// <summary>
    /// Me endpoint - Gets current user information
    /// </summary>
    [ServiceEnabled]
    procedure Me(token: Text): Text
    begin
        exit(AuthAPI.Me(token));
    end;

    /// <summary>
    /// Change Password endpoint - Changes user's password
    /// </summary>
    [ServiceEnabled]
    procedure ChangePassword(token: Text; oldPassword: Text; newPassword: Text): Text
    begin
        exit(AuthAPI.ChangePassword(token, oldPassword, newPassword));
    end;

    // ==================== ADMIN ENDPOINTS ====================

    /// <summary>
    /// Admin endpoint - Creates a new user
    /// </summary>
    [ServiceEnabled]
    procedure AdminCreateUser(token: Text; userId: Text; employeeId: text; authId: text; roleInt: Integer; workCenterNo: Text): Text
    begin
        exit(AuthAPI.AdminCreateUser(token, userId, employeeId, authId, roleInt, workCenterNo));
    end;

    /// <summary>
    /// Admin endpoint - Sets user password
    /// </summary>
    [ServiceEnabled]
    procedure AdminSetPassword(token: Text; userId: Text; newPassword: Text; forceChange: Boolean): Text
    begin
        exit(AuthAPI.AdminSetPassword(token, userId, newPassword, forceChange));
    end;

    /// <summary>
    /// Admin endpoint - Activates or deactivates a user
    /// </summary>
    [ServiceEnabled]
    procedure AdminSetActive(token: Text; userId: Text; isActive: Boolean): Text
    begin
        exit(AuthAPI.AdminSetActive(token, userId, isActive));
    end;

    /// <summary>
    /// Admin endpoint - Gets list of users
    /// </summary>
    [ServiceEnabled]
    procedure GetUsers(token: Text): Text
    begin
        exit(AuthAPI.GetUsers(token));
    end;
}
