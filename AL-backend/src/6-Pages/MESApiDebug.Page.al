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

                action(RunPasswordExpiryCheck)
                {
                    ApplicationArea = All;
                    Caption = 'Run Password Expiry Check';
                    Image = Refresh;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Runs the expiry worker and prints a full per-user diagnostic report into Last Response so you can see exactly why each user was or was not flagged.';
                    trigger OnAction()
                    var
                        Worker: Codeunit "MES Password Expiry Worker";
                    begin
                        LastResponse := Worker.CheckAndFlagExpiredPasswordsVerbose();
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
        B.AppendLine('Dev   : RunPasswordExpiryCheck  (runs worker immediately)');
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
