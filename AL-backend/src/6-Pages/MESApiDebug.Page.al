/// Debug page extended to include a Dev Setup action group.
/// The new action runs MESDevSetup and prints the three permanent
/// token GUIDs into LastResponse so the developer can copy them.
///
/// NOTE: Only the additions/changes relative to the original page are
/// shown below.  In practice this file replaces MESApiDebug.Page.al.
page 50140 "MES API Debug"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'MES API Debug';
    SourceTable = Integer;
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            group(Overview)
            {
                Caption = 'Available APIs';
                field(ApiList; ApiList)
                {
                    ApplicationArea = All;
                    Caption = 'Endpoints';
                    MultiLine = true;
                    Editable = false;
                }
            }

            group(Request)
            {
                Caption = 'Request Inputs';
                field(UserId; UserId) { ApplicationArea = All; Caption = 'User Id'; }
                field(Password; Password) { ApplicationArea = All; Caption = 'Password'; ExtendedDatatype = Masked; }
                field(DeviceId; DeviceId) { ApplicationArea = All; Caption = 'Device Id'; }
                field(Token; Token) { ApplicationArea = All; Caption = 'Token'; }
                field(OldPassword; OldPassword) { ApplicationArea = All; Caption = 'Old Password'; ExtendedDatatype = Masked; }
                field(NewPassword; NewPassword) { ApplicationArea = All; Caption = 'New Password'; ExtendedDatatype = Masked; }
                field(EmployeeId; EmployeeId) { ApplicationArea = All; Caption = 'Employee Id'; }
                field(AuthId; AuthId) { ApplicationArea = All; Caption = 'Auth Id'; }
                field(RoleInt; RoleInt) { ApplicationArea = All; Caption = 'Role (0=Operator, 1=Supervisor, 2=Admin)'; }
                field(WorkCenterNo; WorkCenterNo) { ApplicationArea = All; Caption = 'Work Center No.'; }
                field(IsActive; IsActive) { ApplicationArea = All; Caption = 'Is Active'; }
            }

            group(Response)
            {
                Caption = 'Last Response';
                field(LastResponse; LastResponse)
                {
                    ApplicationArea = All;
                    Caption = 'Response';
                    MultiLine = true;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group("Auth API")
            {
                Caption = 'Auth API';
                action(Login)
                {
                    ApplicationArea = All;
                    Caption = 'Login';
                    Image = Start;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    trigger OnAction()
                    begin
                        LastResponse := AuthAPI.Login(UserId, Password, DeviceId);
                    end;
                }
                action(Logout)
                {
                    ApplicationArea = All;
                    Caption = 'Logout';
                    Image = Stop;
                    Promoted = true;
                    PromotedCategory = Process;
                    trigger OnAction()
                    begin
                        LastResponse := AuthAPI.Logout(Token);
                    end;
                }
                action(Me)
                {
                    ApplicationArea = All;
                    Caption = 'Me';
                    Image = Info;
                    Promoted = true;
                    PromotedCategory = Process;
                    trigger OnAction()
                    begin
                        LastResponse := AuthAPI.Me(Token);
                    end;
                }
                action(ChangePassword)
                {
                    ApplicationArea = All;
                    Caption = 'Change Password';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Process;
                    trigger OnAction()
                    begin
                        LastResponse := AuthAPI.ChangePassword(Token, OldPassword, NewPassword);
                    end;
                }
            }

            group("Admin API")
            {
                Caption = 'Admin API';
                action(AdminSetPassword)
                {
                    ApplicationArea = All;
                    Caption = 'Admin: Set Password';
                    Image = Edit;
                    Promoted = true;
                    PromotedCategory = Process;
                    trigger OnAction()
                    begin
                        LastResponse := AuthAPI.AdminSetPassword(Token, UserId, NewPassword);
                    end;
                }
                action(AdminSetActive)
                {
                    ApplicationArea = All;
                    Caption = 'Admin: Set Active';
                    Image = Status;
                    Promoted = true;
                    PromotedCategory = Process;
                    trigger OnAction()
                    begin
                        LastResponse := AuthAPI.AdminSetActive(Token, UserId, IsActive);
                    end;
                }
            }

            group(Setup)
            {
                Caption = 'Setup';
                action(RunSetup)
                {
                    ApplicationArea = All;
                    Caption = 'Run MES Setup';
                    Image = Setup;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    trigger OnAction()
                    begin
                        Codeunit.Run(Codeunit::"MES Setup");
                    end;
                }
            }

            // ── Dev Setup group ───────────────────────────────────────────
            // Provisions three permanent dev users/tokens and prints the
            // token GUIDs into LastResponse so they can be pasted into
            // AppConstants.devToken in Flutter.
            group("Dev Setup")
            {
                Caption = 'Dev Setup (sandbox only)';
                action(RunDevSetup)
                {
                    ApplicationArea = All;
                    Caption = 'Provision Dev Users & Tokens';
                    Image = TestDatabase;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Creates DEV-OPERATOR, DEV-SUPERVISOR, DEV-ADMIN with permanent tokens. NEVER run in production.';

                    trigger OnAction()
                    var
                        DevSetup: Codeunit "MES Dev Setup";
                    begin
                        DevSetup.Run();
                        LastResponse := DevSetup.GetTokenSummary();
                    end;
                }
            }

            group(Navigate)
            {
                Caption = 'Navigate';
                action(OpenUserList)
                {
                    ApplicationArea = All;
                    Caption = 'Open MES User List';
                    Image = Users;
                    Promoted = true;
                    PromotedCategory = Process;
                    trigger OnAction()
                    begin
                        Page.Run(Page::"MES User List");
                    end;
                }
            }

            action(ClearResponse)
            {
                ApplicationArea = All;
                Caption = 'Clear Response';
                Image = Delete;
                trigger OnAction()
                begin
                    LastResponse := '';
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        B: TextBuilder;
    begin
        B.AppendLine('Auth  : Login · Logout · Me · ChangePassword');
        B.AppendLine('Admin : AdminCreateUser · AdminSetPassword · AdminSetActive');
        B.AppendLine('Dev   : RunDevSetup  (prints 3 token GUIDs to Response)');
        B.Append('All   : POST /ODataV4/MESWebService_<ProcedureName>');
        ApiList := B.ToText();
    end;

    var
        AuthAPI: Codeunit "MES Web Service";
        ApiList: Text;
        LastResponse: Text;
        UserId: Text;
        Password: Text;
        DeviceId: Text;
        Token: Text;
        OldPassword: Text;
        NewPassword: Text;
        EmployeeId: Text;
        AuthId: Text;
        RoleInt: Integer;
        WorkCenterNo: Text;
        IsActive: Boolean;
}
