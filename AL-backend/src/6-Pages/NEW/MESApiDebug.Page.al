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
                    Caption = 'MES Auth Actions (v1.0)';
                    MultiLine = true;
                    Editable = false;
                }
            }

            group(Request)
            {
                Caption = 'Request Inputs';

                field(UserId; UserId)
                {
                    ApplicationArea = All;
                    Caption = 'User Id';
                }
                field(Password; Password)
                {
                    ApplicationArea = All;
                    Caption = 'Password';
                    ExtendedDatatype = Masked;
                }
                field(DeviceId; DeviceId)
                {
                    ApplicationArea = All;
                    Caption = 'Device Id';
                }
                field(Token; Token)
                {
                    ApplicationArea = All;
                    Caption = 'Token';
                }
                field(OldPassword; OldPassword)
                {
                    ApplicationArea = All;
                    Caption = 'Old Password';
                    ExtendedDatatype = Masked;
                }
                field(NewPassword; NewPassword)
                {
                    ApplicationArea = All;
                    Caption = 'New Password';
                    ExtendedDatatype = Masked;
                }
                field(EmployeeId; EmployeeId)
                {
                    ApplicationArea = All;
                    Caption = 'Employee Id';
                }
                field(AuthId; AuthId)
                {
                    ApplicationArea = All;
                    Caption = 'Auth Id';
                }
                field(RoleInt; RoleInt)
                {
                    ApplicationArea = All;
                    Caption = 'Role (0=Operator,1=Supervisor,2=Admin)';
                }
                field(WorkCenterNo; WorkCenterNo)
                {
                    ApplicationArea = All;
                    Caption = 'Work Center No.';
                }
                field(ForceChange; ForceChange)
                {
                    ApplicationArea = All;
                    Caption = 'Force Change On Next Login';
                }
                field(IsActive; IsActive)
                {
                    ApplicationArea = All;
                    Caption = 'Is Active';
                }
            }

            group(Response)
            {
                Caption = 'Last Response';

                field(LastResponse; LastResponse)
                {
                    ApplicationArea = All;
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
                action(Login)
                {
                    ApplicationArea = All;
                    Caption = 'Login';
                    Image = LogIn;
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
                    Image = LogOut;
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
                    Image = Information;
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
                    Image = ChangePassword;
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
                action(AdminCreateUser)
                {
                    ApplicationArea = All;
                    Caption = 'Admin Create User';
                    Image = NewUser;
                    Promoted = true;
                    PromotedCategory = Process;

                    trigger OnAction()
                    begin
                        LastResponse := AuthAPI.AdminCreateUser(Token, UserId, EmployeeId, AuthId, RoleInt, WorkCenterNo);
                    end;
                }
                action(AdminSetPassword)
                {
                    ApplicationArea = All;
                    Caption = 'Admin Set Password';
                    Image = ChangePassword;
                    Promoted = true;
                    PromotedCategory = Process;

                    trigger OnAction()
                    begin
                        LastResponse := AuthAPI.AdminSetPassword(Token, UserId, NewPassword, ForceChange);
                    end;
                }
                action(AdminSetActive)
                {
                    ApplicationArea = All;
                    Caption = 'Admin Set Active';
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

            group(Users)
            {
                action(OpenUserList)
                {
                    ApplicationArea = All;
                    Caption = 'Open MES Users';
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
    begin
        ApiList := 'Auth endpoints: Login, Logout, Me, ChangePassword. Admin endpoints: AdminCreateUser, AdminSetPassword, AdminSetActive.';
    end;

    var
        AuthAPI: Codeunit "MES Auth API";
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
        ForceChange: Boolean;
        IsActive: Boolean;
}
