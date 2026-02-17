// =============================================================================
// Page   : MES API Debug
// ID     : 50140
// Type   : Card
// Purpose: Interactive test harness for all MES API endpoints.
//          Allows developers and administrators to call every MES Auth and
//          Admin endpoint directly from within Business Central — no external
//          REST client or Postman setup required.
//
// HOW TO USE
//   1. Open the page (search "MES API Debug" in BC, or navigate via the
//      MES User List actions).
//   2. Fill in the Request Inputs fields for the operation you want to test.
//   3. Click the corresponding action button (Login, Me, AdminCreateUser, etc.).
//   4. Read the result in the "Last Response" field — it shows the raw JSON
//      returned by the API, including "success", "error", and "message" fields.
//
// TYPICAL TEST FLOW
//   1. Click "Run MES Setup" (first time only) to create the default admin account.
//   2. Fill in UserId = "admin", Password = "Admin@123!", DeviceId = "debug".
//   3. Click "Login" — copy the "token" value from Last Response.
//   4. Paste the token into the Token field.
//   5. Click "Me" to verify the token is valid.
//   6. Use the Admin API buttons to create more users, set passwords, etc.
//
// SOURCE TABLE NOTE
//   SourceTable = Integer with SourceTableTemporary = true is a standard BC
//   pattern for Card pages that do not need to persist their own data.
//   The Integer table always has exactly one row (value = 0) in temporary mode,
//   which keeps the page open without requiring a real table record.
//
// IMPORTANT — PRODUCTION USE
//   This page is intended for development and administration only.
//   The Password fields use ExtendedDatatype = Masked so values are hidden
//   in the UI, but the underlying variables are still plain Text.
//   Do not leave this page accessible to Operator-role users in production.
// =============================================================================
page 50140 "MES API Debug"
{
    PageType           = Card;
    ApplicationArea    = All;
    UsageCategory      = Administration;
    Caption            = 'MES API Debug';
    SourceTable        = Integer;
    SourceTableTemporary = true;  // keeps the page open without a real record

    layout
    {
        area(Content)
        {
            // -----------------------------------------------------------------
            // Group: Available APIs
            // Shows a summary of the available endpoints as a quick reference.
            // Populated in OnOpenPage.
            // -----------------------------------------------------------------
            group(Overview)
            {
                Caption = 'Available APIs';

                field(ApiList; ApiList)
                {
                    ApplicationArea = All;
                    Caption         = 'Endpoints';
                    MultiLine       = true;
                    Editable        = false;
                    ToolTip         = 'Lists all available MES API endpoints for quick reference.';
                }
            }

            // -----------------------------------------------------------------
            // Group: Request Inputs
            // Input fields shared across all API calls.  Fill in the fields
            // relevant to the action you intend to test.
            // -----------------------------------------------------------------
            group(Request)
            {
                Caption = 'Request Inputs';

                // UserId — used by: Login, AdminCreateUser, AdminSetPassword, AdminSetActive
                field(UserId; UserId)
                {
                    ApplicationArea = All;
                    Caption         = 'User Id';
                    ToolTip         = 'The MES User Id.  Used as the login username and as the target for admin actions.';
                }

                // Password — used by: Login
                // ExtendedDatatype = Masked hides the value in the UI.
                field(Password; Password)
                {
                    ApplicationArea  = All;
                    Caption          = 'Password';
                    ExtendedDatatype = Masked;
                    ToolTip          = 'Plaintext password for the Login action.  Masked in UI.';
                }

                // DeviceId — used by: Login
                // Optional identifier for the calling device (for audit purposes).
                field(DeviceId; DeviceId)
                {
                    ApplicationArea = All;
                    Caption         = 'Device Id';
                    ToolTip         = 'Optional device identifier sent with Login (stored in the token for audit trail).';
                }

                // Token — used by: Logout, Me, ChangePassword, all Admin actions
                // Paste the GUID token value returned by Login here.
                field(Token; Token)
                {
                    ApplicationArea = All;
                    Caption         = 'Token';
                    ToolTip         = 'Session token GUID returned by Login.  Required for all authenticated actions.';
                }

                // OldPassword — used by: ChangePassword
                field(OldPassword; OldPassword)
                {
                    ApplicationArea  = All;
                    Caption          = 'Old Password';
                    ExtendedDatatype = Masked;
                    ToolTip          = 'Current password, required to authenticate the ChangePassword request.';
                }

                // NewPassword — used by: ChangePassword, AdminSetPassword
                field(NewPassword; NewPassword)
                {
                    ApplicationArea  = All;
                    Caption          = 'New Password';
                    ExtendedDatatype = Masked;
                    ToolTip          = 'New password to set.  Must meet complexity requirements (8+ chars, upper, lower, digit, special).';
                }

                // EmployeeId — used by: AdminCreateUser
                field(EmployeeId; EmployeeId)
                {
                    ApplicationArea = All;
                    Caption         = 'Employee Id';
                    ToolTip         = 'BC Employee No. to link to the new MES User.  Leave blank if no HR record exists.';
                }

                // AuthId — used by: AdminCreateUser
                field(AuthId; AuthId)
                {
                    ApplicationArea = All;
                    Caption         = 'Auth Id';
                    ToolTip         = 'External identity reference (e.g. Active Directory UPN "AD\\jdoe").  Returned as "name" in API responses.';
                }

                // RoleInt — used by: AdminCreateUser
                // 0 = Operator, 1 = Supervisor, 2 = Admin
                field(RoleInt; RoleInt)
                {
                    ApplicationArea = All;
                    Caption         = 'Role  (0=Operator, 1=Supervisor, 2=Admin)';
                    ToolTip         = 'Integer role code for the new user.  0=Operator, 1=Supervisor, 2=Admin.';
                }

                // WorkCenterNo — used by: AdminCreateUser
                field(WorkCenterNo; WorkCenterNo)
                {
                    ApplicationArea = All;
                    Caption         = 'Work Center No.';
                    ToolTip         = 'The Work Center the new user is assigned to.  Leave blank for Admin accounts.';
                }

                // ForceChange — used by: AdminSetPassword
                field(ForceChange; ForceChange)
                {
                    ApplicationArea = All;
                    Caption         = 'Force Change On Next Login';
                    ToolTip         = 'If true, the target user must change their password on next login.';
                }

                // IsActive — used by: AdminSetActive
                field(IsActive; IsActive)
                {
                    ApplicationArea = All;
                    Caption         = 'Is Active';
                    ToolTip         = 'Target active status for AdminSetActive.  Set to false to disable the account.';
                }
            }

            // -----------------------------------------------------------------
            // Group: Last Response
            // Displays the raw JSON text returned by the last API call.
            // Always shows the full { "success": ..., ... } envelope.
            // -----------------------------------------------------------------
            group(Response)
            {
                Caption = 'Last Response';

                field(LastResponse; LastResponse)
                {
                    ApplicationArea = All;
                    Caption         = 'Response';
                    MultiLine       = true;
                    Editable        = false;
                    ToolTip         = 'Raw JSON response from the last API call.  Check "success" to determine if the call succeeded.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            // -----------------------------------------------------------------
            // Group: Auth API
            // User-facing endpoints — available to all authenticated users.
            // -----------------------------------------------------------------
            group("Auth API")
            {
                Caption = 'Auth API';

                action(Login)
                {
                    ApplicationArea  = All;
                    Caption          = 'Login';
                    Image            = Start;
                    Promoted         = true;
                    PromotedCategory = Process;
                    PromotedIsBig    = true;
                    ToolTip          = 'Authenticate with UserId + Password.  Copies the returned token into the Token field automatically is NOT done here — paste it manually from Last Response.';

                    trigger OnAction()
                    begin
                        LastResponse := AuthAPI.Login(UserId, Password, DeviceId);
                    end;
                }

                action(Logout)
                {
                    ApplicationArea  = All;
                    Caption          = 'Logout';
                    Image            = Stop;
                    Promoted         = true;
                    PromotedCategory = Process;
                    ToolTip          = 'Revoke the token in the Token field.  Use after testing to clean up active sessions.';

                    trigger OnAction()
                    begin
                        LastResponse := AuthAPI.Logout(Token);
                    end;
                }

                action(Me)
                {
                    ApplicationArea  = All;
                    Caption          = 'Me';
                    Image            = Info;
                    Promoted         = true;
                    PromotedCategory = Process;
                    ToolTip          = 'Validate the token and retrieve the current user profile.  Useful to confirm a token is still valid.';

                    trigger OnAction()
                    begin
                        LastResponse := AuthAPI.Me(Token);
                    end;
                }

                action(ChangePassword)
                {
                    ApplicationArea  = All;
                    Caption          = 'Change Password';
                    Image            = Change;
                    Promoted         = true;
                    PromotedCategory = Process;
                    ToolTip          = 'Change the password for the user owning the current token.  Requires Token, Old Password, and New Password.';

                    trigger OnAction()
                    begin
                        LastResponse := AuthAPI.ChangePassword(Token, OldPassword, NewPassword);
                    end;
                }
            }

            // -----------------------------------------------------------------
            // Group: Admin API
            // Administrative endpoints — require a token from an Admin account.
            // -----------------------------------------------------------------
            group("Admin API")
            {
                Caption = 'Admin API';

                action(AdminCreateUser)
                {
                    ApplicationArea  = All;
                    Caption          = 'Admin: Create User';
                    Image            = User;
                    Promoted         = true;
                    PromotedCategory = Process;
                    ToolTip          = 'Create a new MES user.  Requires Admin token, UserId, EmployeeId, AuthId, RoleInt, and WorkCenterNo.';

                    trigger OnAction()
                    begin
                        LastResponse := AuthAPI.AdminCreateUser(
                            Token, UserId, EmployeeId, AuthId, RoleInt, WorkCenterNo);
                    end;
                }

                action(AdminSetPassword)
                {
                    ApplicationArea  = All;
                    Caption          = 'Admin: Set Password';
                    Image            = Edit;
                    Promoted         = true;
                    PromotedCategory = Process;
                    ToolTip          = 'Set or reset the password for any MES user.  Requires Admin token, target UserId, NewPassword, and ForceChange flag.';

                    trigger OnAction()
                    begin
                        LastResponse := AuthAPI.AdminSetPassword(
                            Token, UserId, NewPassword, ForceChange);
                    end;
                }

                action(AdminSetActive)
                {
                    ApplicationArea  = All;
                    Caption          = 'Admin: Set Active';
                    Image            = Status;
                    Promoted         = true;
                    PromotedCategory = Process;
                    ToolTip          = 'Activate or deactivate a user account.  Requires Admin token, target UserId, and IsActive value.';

                    trigger OnAction()
                    begin
                        LastResponse := AuthAPI.AdminSetActive(Token, UserId, IsActive);
                    end;
                }
            }

            // -----------------------------------------------------------------
            // Group: Setup
            // One-time initialisation actions.
            // -----------------------------------------------------------------
            group(Setup)
            {
                Caption = 'Setup';

                action(RunSetup)
                {
                    ApplicationArea  = All;
                    Caption          = 'Run MES Setup';
                    Image            = Setup;
                    Promoted         = true;
                    PromotedCategory = Process;
                    PromotedIsBig    = true;
                    ToolTip          = 'Seeds the default "admin" account.  Run ONCE on a new environment.  Will fail gracefully if the admin account already exists.';

                    trigger OnAction()
                    begin
                        Codeunit.Run(Codeunit::"MES Setup");
                    end;
                }
            }

            // -----------------------------------------------------------------
            // Group: Navigation
            // Quick links to related BC pages.
            // -----------------------------------------------------------------
            group(Navigate)
            {
                Caption = 'Navigate';

                action(OpenUserList)
                {
                    ApplicationArea  = All;
                    Caption          = 'Open MES User List';
                    Image            = Users;
                    Promoted         = true;
                    PromotedCategory = Process;
                    ToolTip          = 'Opens the MES User List page to view all registered MES accounts.';

                    trigger OnAction()
                    begin
                        Page.Run(Page::"MES User List");
                    end;
                }
            }

            // -----------------------------------------------------------------
            // Utility action: clears the Last Response field.
            // -----------------------------------------------------------------
            action(ClearResponse)
            {
                ApplicationArea = All;
                Caption         = 'Clear Response';
                Image           = Delete;
                ToolTip         = 'Clears the Last Response field so the next API call result is easy to read.';

                trigger OnAction()
                begin
                    LastResponse := '';
                end;
            }
        }
    }

    // -------------------------------------------------------------------------
    // Trigger: OnOpenPage
    // Populates the ApiList summary field shown in the Overview group.
    // -------------------------------------------------------------------------
    trigger OnOpenPage()
    var
        ApiListBuilder: TextBuilder;
    begin
        ApiListBuilder.AppendLine('Auth: Login · Logout · Me · ChangePassword');
        ApiListBuilder.AppendLine('Admin: AdminCreateUser · AdminSetPassword · AdminSetActive');
        ApiListBuilder.Append('All endpoints: POST /ODataV4/MESUnboundActions_<ProcedureName>');
        ApiList := ApiListBuilder.ToText();
    end;

    // -------------------------------------------------------------------------
    // Variables
    // -------------------------------------------------------------------------
    var
        // Codeunit reference — points to MES Unbound Actions (50125).
        // All action triggers delegate to this codeunit, which is the same
        // code that the ODataV4 web service calls externally.
        AuthAPI: Codeunit "MES Unbound Actions";

        // Display field for the API endpoint summary shown in Overview.
        ApiList     : Text;

        // Last response from any API call — displayed in the Response group.
        LastResponse: Text;

        // Input fields — shared across multiple API actions.
        UserId      : Text;
        Password    : Text;
        DeviceId    : Text;
        Token       : Text;
        OldPassword : Text;
        NewPassword : Text;
        EmployeeId  : Text;
        AuthId      : Text;
        RoleInt     : Integer;
        WorkCenterNo: Text;
        ForceChange : Boolean;
        IsActive    : Boolean;
}
