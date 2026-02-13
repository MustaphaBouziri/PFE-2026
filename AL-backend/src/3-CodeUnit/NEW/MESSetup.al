codeunit 50115 "MES Setup"
{
    trigger OnRun()
    var
        AuthMgt: Codeunit "MES Auth Mgt";
    begin
        AuthMgt.CreateUser('admin', 'Administrator', "MES User Role"::Admin, '', '');
        AuthMgt.SetPassword('admin', 'Admin@123!', true);
    end;
}